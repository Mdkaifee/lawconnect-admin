import { Router } from "express";
import { Post, Comment, Report, User } from "../models/index.js";
import { auth, requireAdmin, requireUser, asyncHandler } from "../middleware/auth.js";
import { notifyAllUsers, notifyUsers } from "../services/notifications.js";
import mongoose from "mongoose";

const router = Router();

/* ---------------- 1. List & Search Posts ---------------- */
router.get(
  "/",
  auth(false),
  asyncHandler(async (req, res) => {
    const { scope, authorId, category, tag, q, page = 1, limit = 20, all } = req.query;
    const filter = {};
    if (!all) filter.status = "published";
    if (scope === "mine" && authorId) filter.authorId = authorId;
    if (scope === "following") {
      let followingIds = [];
      if (req.auth && req.auth.id) {
        const currentUser = await User.findById(req.auth.id);
        followingIds = (currentUser?.following || []).map((id) => id.toString());
      } else if (authorId) {
        followingIds = authorId.split(",").map((s) => s.trim()).filter(Boolean);
      }
      filter.authorId = { $in: followingIds };
    }
    if (category && category !== "All" && category !== "Feed") filter.category = category;
    if (tag) filter.tags = tag;
    if (q) {
      const rx = new RegExp(q.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      filter.$or = [{ title: rx }, { content: rx }, { tags: rx }, { authorName: rx }];
    }

    const pageNum = Math.max(1, Number(page) || 1);
    const limitNum = Math.min(50, Math.max(1, Number(limit) || 20));
    const skip = (pageNum - 1) * limitNum;

    const [items, total] = await Promise.all([
      Post.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limitNum).lean(),
      Post.countDocuments(filter),
    ]);

    // Live populate author photos
    const authorIds = items.filter((p) => p.authorId).map((p) => p.authorId);
    let authorPhotoMap = {};
    if (authorIds.length > 0) {
      const users = await User.find({ _id: { $in: authorIds } }).select("_id photoUrl").lean();
      users.forEach((u) => {
        if (u.photoUrl) authorPhotoMap[u._id.toString()] = u.photoUrl;
      });
    }

    res.json({
      items: items.map((p) => {
        const authorIdStr = p.authorId ? p.authorId.toString() : "";
        const dynamicPhoto = authorPhotoMap[authorIdStr] || p.authorPhotoUrl || "";
        return {
          ...p,
          authorPhotoUrl: dynamicPhoto,
          likesCount: p.likedBy ? p.likedBy.length : p.likes || 0,
        };
      }),
      total,
      page: pageNum,
      limit: limitNum,
    });
  }),
);

/* ---------------- 2. Single Post Details ---------------- */
router.get(
  "/:id",
  asyncHandler(async (req, res) => {
    const item = await Post.findById(req.params.id).lean();
    if (!item) return res.status(404).json({ error: "Post not found" });
    if (item.authorId) {
      const u = await User.findById(item.authorId).select("photoUrl").lean();
      if (u && u.photoUrl) item.authorPhotoUrl = u.photoUrl;
    }
    res.json({
      item: {
        ...item,
        likesCount: item.likedBy ? item.likedBy.length : item.likes || 0,
      },
    });
  }),
);

/* ---------------- 3. Create Post (App User) ---------------- */
router.post(
  "/",
  auth(),
  requireUser,
  asyncHandler(async (req, res) => {
    const user = await User.findById(req.auth.id);
    if (!user) return res.status(401).json({ error: "User not found" });

    const item = await Post.create({
      title: req.body.title,
      content: req.body.content,
      category: req.body.category || "General Law",
      tags: Array.isArray(req.body.tags) ? req.body.tags : [],
      authorType: "user",
      authorModel: "User",
      authorId: user._id,
      authorName: user.name,
      authorPhotoUrl: user.photoUrl || "",
      likedBy: [],
      likes: 0,
      commentsCount: 0,
      status: "published",
    });

    await notifyUsers(user.following || [], {
      title: `${user.name} posted`,
      body: item.title,
      data: { type: "friend_post", postId: item._id.toString(), authorId: user._id.toString() },
    });

    res.status(201).json({ item });
  }),
);

/* ---------------- 4. Idempotent Like / Unlike Toggle ---------------- */
router.post(
  "/:id/like",
  auth(),
  requireUser,
  asyncHandler(async (req, res) => {
    const userId = new mongoose.Types.ObjectId(req.auth.id);
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ error: "Post not found" });

    const isAlreadyLiked = (post.likedBy || []).some((id) => id.toString() === req.auth.id);

    let updatedPost;
    if (isAlreadyLiked) {
      updatedPost = await Post.findByIdAndUpdate(
        req.params.id,
        {
          $pull: { likedBy: userId },
          $inc: { likes: post.likes > 0 ? -1 : 0 },
        },
        { new: true },
      );
    } else {
      updatedPost = await Post.findByIdAndUpdate(
        req.params.id,
        {
          $addToSet: { likedBy: userId },
          $inc: { likes: 1 },
        },
        { new: true },
      );
    }

    const likesCount = updatedPost.likedBy ? updatedPost.likedBy.length : updatedPost.likes || 0;
    res.json({
      isLiked: !isAlreadyLiked,
      likesCount,
      item: {
        ...updatedPost.toObject(),
        likesCount,
      },
    });
  }),
);

/* ---------------- 5. Comments CRUD ---------------- */
router.get(
  "/:id/comments",
  asyncHandler(async (req, res) => {
    const pageNum = Math.max(1, Number(req.query.page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
    const skip = (pageNum - 1) * limitNum;
    const filter = { postId: req.params.id, status: "published" };
    const [comments, total] = await Promise.all([
      Comment.find(filter).sort({ createdAt: 1 }).skip(skip).limit(limitNum).lean(),
      Comment.countDocuments(filter),
    ]);
    const commentAuthorIds = comments.filter((c) => c.authorId).map((c) => c.authorId);
    let commentAuthorPhotoMap = {};
    if (commentAuthorIds.length > 0) {
      const users = await User.find({ _id: { $in: commentAuthorIds } }).select("_id photoUrl").lean();
      users.forEach((u) => {
        if (u.photoUrl) commentAuthorPhotoMap[u._id.toString()] = u.photoUrl;
      });
    }
    res.json({
      items: comments.map((c) => {
        const aIdStr = c.authorId ? c.authorId.toString() : "";
        return {
          ...c,
          authorPhotoUrl: commentAuthorPhotoMap[aIdStr] || c.authorPhotoUrl || "",
        };
      }),
      total,
      page: pageNum,
      limit: limitNum,
    });
  }),
);

router.post(
  "/:id/comments",
  auth(),
  asyncHandler(async (req, res) => {
    const { content } = req.body || {};
    if (!content || !content.trim()) {
      return res.status(400).json({ error: "Comment content is required" });
    }

    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ error: "Post not found" });

    let authorName = "Advocate";
    let authorType = "user";
    let authorModel = "User";
    let authorPhotoUrl = "";

    if (req.auth.type === "admin") {
      authorType = "admin";
      authorModel = "Admin";
      authorName = "Rishikesh Yadav (Admin)";
    } else {
      const user = await User.findById(req.auth.id);
      if (user) {
        authorName = user.name;
        authorPhotoUrl = user.photoUrl || "";
      }
    }

    const comment = await Comment.create({
      postId: post._id,
      authorType,
      authorId: req.auth.id,
      authorModel,
      authorName,
      authorPhotoUrl,
      content: content.trim(),
      status: "published",
    });

    await Post.findByIdAndUpdate(post._id, { $inc: { commentsCount: 1 } });

    res.status(201).json({ item: comment });
  }),
);

router.delete(
  "/:id/comments/:commentId",
  auth(),
  asyncHandler(async (req, res) => {
    const comment = await Comment.findById(req.params.commentId);
    if (!comment) return res.status(404).json({ error: "Comment not found" });

    // Verify ownership: Admin or the author
    if (req.auth.type !== "admin" && comment.authorId.toString() !== req.auth.id) {
      return res.status(403).json({ error: "Forbidden: Not comment author" });
    }

    await Comment.findByIdAndDelete(req.params.commentId);
    await Post.findByIdAndUpdate(req.params.id, { $inc: { commentsCount: -1 } });

    res.json({ ok: true });
  }),
);

/* ---------------- 6. Moderation Reporting ---------------- */
router.post(
  "/:id/report",
  auth(),
  requireUser,
  asyncHandler(async (req, res) => {
    const { reason = "Inappropriate content", targetType = "post" } = req.body || {};
    const report = await Report.create({
      targetType,
      targetId: req.params.id,
      reporterId: req.auth.id,
      reason,
      status: "pending",
    });

    res.status(201).json({ ok: true, message: "Report submitted for moderation.", item: report });
  }),
);

/* ---------------- 7. Admin: Official Posts & Moderation ---------------- */
router.post(
  "/admin",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const item = await Post.create({
      ...req.body,
      authorType: "admin",
      authorModel: "Admin",
      authorId: req.auth.id,
      authorName: req.body.authorName || "Rishikesh Yadav",
      likedBy: [],
      likes: 0,
      commentsCount: 0,
    });
    await notifyAllUsers({
      title: "New post from admin",
      body: item.title,
      data: { type: "admin_post", postId: item._id.toString() },
    });
    res.status(201).json({ item });
  }),
);

router.put(
  "/:id",
  auth(),
  asyncHandler(async (req, res) => {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ error: "Post not found" });

    // Allow author or admin
    if (req.auth.type !== "admin" && post.authorId.toString() !== req.auth.id) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const updated = await Post.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json({ item: updated });
  }),
);

router.delete(
  "/:id",
  auth(),
  asyncHandler(async (req, res) => {
    const post = await Post.findById(req.params.id);
    if (!post) return res.status(404).json({ error: "Post not found" });

    if (req.auth.type !== "admin" && post.authorId.toString() !== req.auth.id) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await Promise.all([Post.findByIdAndDelete(req.params.id), Comment.deleteMany({ postId: req.params.id })]);

    res.json({ ok: true });
  }),
);

export default router;
