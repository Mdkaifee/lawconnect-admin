import { Router } from "express";
import bcrypt from "bcryptjs";
import { Category, Note, Bookmark, History, User, Case, Act, Post, LegalUpdate, Report, Comment } from "../models/index.js";
import { auth, requireAdmin, requireUser, asyncHandler } from "../middleware/auth.js";
import mongoose from "mongoose";

/* ---------------- 1. Categories ---------------- */
export const categories = Router();

categories.get(
  "/",
  asyncHandler(async (_req, res) => {
    const items = await Category.find().sort({ order: 1, name: 1 });
    res.json({ items });
  }),
);

categories.post(
  "/",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    res.status(201).json({ item: await Category.create(req.body) });
  }),
);

categories.put(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    res.json({ item: await Category.findByIdAndUpdate(req.params.id, req.body, { new: true }) });
  }),
);

categories.delete(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    await Category.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  }),
);

/* ---------------- 2. Personal Notes (App User Strict Ownership) ---------------- */
export const notes = Router();
notes.use(auth(), requireUser);

notes.get(
  "/",
  asyncHandler(async (req, res) => {
    const filter = { userId: req.auth.id };
    if (req.query.refType) filter.refType = req.query.refType;
    const pageNum = Math.max(1, Number(req.query.page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
    const skip = (pageNum - 1) * limitNum;
    const [items, total] = await Promise.all([
      Note.find(filter).sort({ updatedAt: -1 }).skip(skip).limit(limitNum),
      Note.countDocuments(filter),
    ]);
    res.json({ items, total, page: pageNum, limit: limitNum });
  }),
);

notes.post(
  "/",
  asyncHandler(async (req, res) => {
    const item = await Note.create({
      userId: req.auth.id,
      title: req.body.title || "Untitled Note",
      content: req.body.content || "",
      refType: req.body.refType || "general",
      refId: req.body.refId || "",
      refTitle: req.body.refTitle || "",
    });
    res.status(201).json({ item });
  }),
);

notes.put(
  "/:id",
  asyncHandler(async (req, res) => {
    const item = await Note.findOneAndUpdate(
      { _id: req.params.id, userId: req.auth.id },
      { $set: req.body },
      { new: true },
    );
    if (!item) return res.status(404).json({ error: "Note not found or unauthorized" });
    res.json({ item });
  }),
);

notes.delete(
  "/:id",
  asyncHandler(async (req, res) => {
    const result = await Note.findOneAndDelete({ _id: req.params.id, userId: req.auth.id });
    if (!result) return res.status(404).json({ error: "Note not found or unauthorized" });
    res.json({ ok: true });
  }),
);

/* ---------------- 3. Bookmarks (App User Strict Ownership) ---------------- */
export const bookmarks = Router();
bookmarks.use(auth(), requireUser);

bookmarks.get(
  "/",
  asyncHandler(async (req, res) => {
    const filter = { userId: req.auth.id };
    if (req.query.refType) filter.refType = req.query.refType;
    const pageNum = Math.max(1, Number(req.query.page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
    const skip = (pageNum - 1) * limitNum;
    const [items, total] = await Promise.all([
      Bookmark.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limitNum),
      Bookmark.countDocuments(filter),
    ]);
    res.json({ items, total, page: pageNum, limit: limitNum });
  }),
);

bookmarks.post(
  "/",
  asyncHandler(async (req, res) => {
    const { refType, refId, title, subtitle } = req.body || {};
    if (!refType || !refId || !title) {
      return res.status(400).json({ error: "refType, refId, and title are required" });
    }
    const item = await Bookmark.findOneAndUpdate(
      { userId: req.auth.id, refType, refId },
      { $set: { userId: req.auth.id, refType, refId, title, subtitle } },
      { upsert: true, new: true },
    );
    res.status(201).json({ item });
  }),
);

bookmarks.delete(
  "/:id",
  asyncHandler(async (req, res) => {
    // Allows deleting by either Bookmark _id or by refId
    let result = null;
    if (mongoose.Types.ObjectId.isValid(req.params.id)) {
      result = await Bookmark.findOneAndDelete({ _id: req.params.id, userId: req.auth.id });
    }
    if (!result) {
      result = await Bookmark.findOneAndDelete({ refId: req.params.id, userId: req.auth.id });
    }
    res.json({ ok: true, deleted: Boolean(result) });
  }),
);

/* ---------------- 4. Reading History ---------------- */
export const history = Router();
history.use(auth(), requireUser);

history.get(
  "/",
  asyncHandler(async (req, res) => {
    const filter = { userId: req.auth.id };
    const pageNum = Math.max(1, Number(req.query.page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
    const skip = (pageNum - 1) * limitNum;
    const [items, total] = await Promise.all([
      History.find(filter).sort({ viewedAt: -1 }).skip(skip).limit(limitNum),
      History.countDocuments(filter),
    ]);
    res.json({ items, total, page: pageNum, limit: limitNum });
  }),
);

history.post(
  "/",
  asyncHandler(async (req, res) => {
    const { refType = "case", refId, title } = req.body || {};
    if (!refId || !title) {
      return res.status(400).json({ error: "refId and title are required" });
    }
    // Update or insert viewing record
    const item = await History.findOneAndUpdate(
      { userId: req.auth.id, refType, refId },
      { $set: { title, viewedAt: new Date() } },
      { upsert: true, new: true },
    );
    res.status(201).json({ item });
  }),
);

history.delete(
  "/",
  asyncHandler(async (req, res) => {
    await History.deleteMany({ userId: req.auth.id });
    res.json({ ok: true, message: "History cleared successfully." });
  }),
);

/* ---------------- 5. Users & Follow & Public Profile ---------------- */
export const users = Router();

function getConnectionStatus(currentUser, targetUserId) {
  const target = targetUserId.toString();
  const following = (currentUser.following || []).map((id) => id.toString());
  const incoming = (currentUser.followRequests || []).map((id) => id.toString());
  if (following.includes(target)) return "friend";
  if (incoming.includes(target)) return "incoming";
  return "none";
}

users.get(
  "/app/list",
  auth(),
  requireUser,
  asyncHandler(async (req, res) => {
    const currentUser = await User.findById(req.auth.id).select("following followRequests");
    if (!currentUser) return res.status(404).json({ error: "User not found" });

    const outgoingUsers = await User.find({ followRequests: req.auth.id }).select("_id");
    const outgoingIds = new Set(outgoingUsers.map((u) => u._id.toString()));

    const items = await User.find({ _id: { $ne: req.auth.id }, blocked: { $ne: true } })
      .select("name email photoUrl headline college following followRequests createdAt")
      .sort({ name: 1 })
      .lean();

    res.json({
      items: items.map((u) => ({
        id: u._id.toString(),
        name: u.name,
        email: u.email,
        photoUrl: u.photoUrl,
        headline: u.headline,
        college: u.college,
        followersCount: Array.isArray(u.following) ? u.following.length : 0,
        followingCount: Array.isArray(u.following) ? u.following.length : 0,
        connectionStatus: outgoingIds.has(u._id.toString())
          ? "requested"
          : getConnectionStatus(currentUser, u._id),
      })),
    });
  }),
);

users.post(
  "/:id/connect",
  auth(),
  requireUser,
  asyncHandler(async (req, res) => {
    const currentUserId = req.auth.id;
    const targetUserId = req.params.id;
    if (currentUserId === targetUserId) return res.status(400).json({ error: "Cannot connect with yourself" });

    const [currentUser, targetUser] = await Promise.all([
      User.findById(currentUserId),
      User.findById(targetUserId),
    ]);
    if (!currentUser || !targetUser) return res.status(404).json({ error: "User not found" });

    const currentFollowing = (currentUser.following || []).map((id) => id.toString());
    const incoming = (currentUser.followRequests || []).map((id) => id.toString());
    const targetRequests = (targetUser.followRequests || []).map((id) => id.toString());

    if (currentFollowing.includes(targetUserId)) {
      return res.json({ ok: true, status: "friend", message: "Already connected" });
    }

    if (incoming.includes(targetUserId)) {
      await Promise.all([
        User.findByIdAndUpdate(currentUserId, {
          $pull: { followRequests: targetUserId },
          $addToSet: { following: targetUserId },
        }),
        User.findByIdAndUpdate(targetUserId, { $addToSet: { following: currentUserId } }),
      ]);
      return res.json({ ok: true, status: "friend", message: "Connection request accepted" });
    }

    if (!targetRequests.includes(currentUserId)) {
      await User.findByIdAndUpdate(targetUserId, { $addToSet: { followRequests: currentUserId } });
    }
    res.json({ ok: true, status: "requested", message: "Connection request sent" });
  }),
);

users.post(
  "/:id/accept",
  auth(),
  requireUser,
  asyncHandler(async (req, res) => {
    const currentUserId = req.auth.id;
    const requesterId = req.params.id;
    if (currentUserId === requesterId) return res.status(400).json({ error: "Cannot connect with yourself" });

    const currentUser = await User.findById(currentUserId);
    if (!currentUser) return res.status(404).json({ error: "User not found" });
    const incoming = (currentUser.followRequests || []).map((id) => id.toString());
    if (!incoming.includes(requesterId)) {
      return res.status(400).json({ error: "No pending request from this user" });
    }

    await Promise.all([
      User.findByIdAndUpdate(currentUserId, {
        $pull: { followRequests: requesterId },
        $addToSet: { following: requesterId },
      }),
      User.findByIdAndUpdate(requesterId, { $addToSet: { following: currentUserId } }),
    ]);

    res.json({ ok: true, status: "friend", message: "Connection request accepted" });
  }),
);

// Connection request / accept friend (authenticated app user)
users.post(
  "/:id/follow",
  auth(),
  requireUser,
  asyncHandler(async (req, res) => {
    const targetUserId = req.params.id;
    if (targetUserId === req.auth.id) {
      return res.status(400).json({ error: "Cannot follow yourself" });
    }

    const [currentUser, targetUser] = await Promise.all([
      User.findById(req.auth.id),
      User.findById(targetUserId),
    ]);
    if (!currentUser || !targetUser) return res.status(404).json({ error: "User not found" });

    const following = (currentUser.following || []).map((id) => id.toString());
    const incoming = (currentUser.followRequests || []).map((id) => id.toString());
    const targetRequests = (targetUser.followRequests || []).map((id) => id.toString());

    if (following.includes(targetUserId)) {
      return res.json({ ok: true, status: "friend", isFollowing: true });
    }

    if (incoming.includes(targetUserId)) {
      await Promise.all([
        User.findByIdAndUpdate(req.auth.id, {
          $pull: { followRequests: targetUserId },
          $addToSet: { following: targetUserId },
        }),
        User.findByIdAndUpdate(targetUserId, { $addToSet: { following: req.auth.id } }),
      ]);
      return res.json({ ok: true, status: "friend", isFollowing: true });
    }

    if (!targetRequests.includes(req.auth.id)) {
      await User.findByIdAndUpdate(targetUserId, { $addToSet: { followRequests: req.auth.id } });
    }

    res.json({ ok: true, status: "requested", isFollowing: false });
  }),
);

// Public advocate profile
users.get(
  "/:id/profile",
  asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id).select("-passwordHash").lean();
    if (!user) return res.status(404).json({ error: "User not found" });

    const [postsCount, followersCount] = await Promise.all([
      Post.countDocuments({ authorId: user._id, status: "published" }),
      User.countDocuments({ following: user._id }),
    ]);

    res.json({
      user: {
        ...user,
        postsCount,
        followersCount,
        followingCount: user.following ? user.following.length : 0,
      },
    });
  }),
);

// Admin: User management
users.get(
  "/",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const filter = req.query.q
      ? { $or: [{ name: new RegExp(req.query.q, "i") }, { email: new RegExp(req.query.q, "i") }] }
      : {};
    const pageNum = Math.max(1, Number(req.query.page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
    const skip = (pageNum - 1) * limitNum;
    const [items, total] = await Promise.all([
      User.find(filter).select("-passwordHash").sort({ createdAt: -1 }).skip(skip).limit(limitNum),
      User.countDocuments(filter),
    ]);
    res.json({ items, total, page: pageNum, limit: limitNum });
  }),
);

users.put(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const patch = { ...req.body };
    if (patch.password) {
      patch.passwordHash = await bcrypt.hash(patch.password, 10);
      delete patch.password;
    }
    const item = await User.findByIdAndUpdate(req.params.id, patch, { new: true }).select("-passwordHash");
    if (!item) return res.status(404).json({ error: "User not found" });
    res.json({ item });
  }),
);

users.delete(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    await User.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  }),
);

/* ---------------- 6. Reports Moderation Queue (Admin) ---------------- */
export const reports = Router();

reports.get(
  "/",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const { status = "pending", page = 1, limit = 20 } = req.query;
    const filter = status !== "all" ? { status } : {};
    const pageNum = Math.max(1, Number(page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(limit) || 20));
    const skip = (pageNum - 1) * limitNum;
    const [items, total] = await Promise.all([
      Report.find(filter).populate("reporterId", "name email").sort({ createdAt: -1 }).skip(skip).limit(limitNum),
      Report.countDocuments(filter),
    ]);
    res.json({ items, total, page: pageNum, limit: limitNum });
  }),
);

reports.put(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const { status, action } = req.body || {};
    const report = await Report.findById(req.params.id);
    if (!report) return res.status(404).json({ error: "Report not found" });

    if (action === "hide_target") {
      if (report.targetType === "post") {
        await Post.findByIdAndUpdate(report.targetId, { status: "hidden" });
      } else if (report.targetType === "comment") {
        await Comment.findByIdAndUpdate(report.targetId, { status: "hidden" });
      }
    } else if (action === "delete_target") {
      if (report.targetType === "post") {
        await Post.findByIdAndDelete(report.targetId);
      } else if (report.targetType === "comment") {
        await Comment.findByIdAndDelete(report.targetId);
      }
    }

    report.status = status || "resolved";
    await report.save();

    res.json({ ok: true, item: report });
  }),
);

/* ---------------- 7. Admin Dashboard Stats ---------------- */
export const stats = Router();
stats.get(
  "/",
  auth(),
  requireAdmin,
  asyncHandler(async (_req, res) => {
    const [cases, acts, posts, updates, appUsers, notesCount, bookmarksCount, pendingReports] = await Promise.all([
      Case.countDocuments(),
      Act.countDocuments(),
      Post.countDocuments(),
      LegalUpdate.countDocuments(),
      User.countDocuments(),
      Note.countDocuments(),
      Bookmark.countDocuments(),
      Report.countDocuments({ status: "pending" }),
    ]);

    const recentCases = await Case.find().sort({ createdAt: -1 }).limit(5).select("title citation court createdAt");
    const recentPosts = await Post.find().sort({ createdAt: -1 }).limit(5).select("title authorName createdAt status");

    res.json({
      counts: {
        cases,
        acts,
        posts,
        updates,
        users: appUsers,
        notes: notesCount,
        bookmarks: bookmarksCount,
        pendingReports,
      },
      recentCases,
      recentPosts,
    });
  }),
);
