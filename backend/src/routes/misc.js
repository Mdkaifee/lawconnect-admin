import { Router } from "express";
import bcrypt from "bcryptjs";
import { AppNotification, Category, Note, Bookmark, History, User, Case, Act, Post, LegalUpdate, Report, Comment, AiChatMessage } from "../models/index.js";
import { auth, requireAdmin, requireUser, asyncHandler } from "../middleware/auth.js";
import mongoose from "mongoose";
import { notifyUsers } from "../services/notifications.js";

const paidChatMonths = Math.max(1, Number.parseInt(process.env.PAID_CHAT_MONTHS || process.env.CHAT_PAID_DURATION_MONTHS || "3", 10) || 3);

function addCalendarMonths(date, months) {
  const result = new Date(date);
  const originalDay = result.getUTCDate();
  result.setUTCDate(1);
  result.setUTCMonth(result.getUTCMonth() + months);
  const lastDay = new Date(Date.UTC(result.getUTCFullYear(), result.getUTCMonth() + 1, 0)).getUTCDate();
  result.setUTCDate(Math.min(originalDay, lastDay));
  return result;
}

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
  if (following.includes(target)) return "following";
  if (incoming.includes(target)) return "incoming";
  return "none";
}

function isOnline(lastActiveAt) {
  return lastActiveAt && Date.now() - new Date(lastActiveAt).getTime() <= 5 * 60 * 1000;
}

users.get(
  "/app/list",
  auth(),
  requireUser,
  asyncHandler(async (req, res) => {
    const currentUser = await User.findByIdAndUpdate(req.auth.id, { lastActiveAt: new Date() }, { new: true }).select("following followRequests");
    if (!currentUser) return res.status(404).json({ error: "User not found" });

    const outgoingUsers = await User.find({ followRequests: req.auth.id }).select("_id");
    const outgoingIds = new Set(outgoingUsers.map((u) => u._id.toString()));
    const followerUsers = await User.find({ following: req.auth.id }).select("_id");
    const followerIds = new Set(followerUsers.map((u) => u._id.toString()));
    const currentFollowing = new Set((currentUser.following || []).map((id) => id.toString()));

    const items = await User.find({ _id: { $ne: req.auth.id }, blocked: { $ne: true } })
      .select("name email photoUrl headline college following followRequests createdAt lastActiveAt chatPaidUntil")
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
        isFollowing: currentFollowing.has(u._id.toString()),
        isFollower: followerIds.has(u._id.toString()),
        isFriend: currentFollowing.has(u._id.toString()) && followerIds.has(u._id.toString()),
        connectionStatus: outgoingIds.has(u._id.toString())
          ? "requested"
          : currentFollowing.has(u._id.toString()) && followerIds.has(u._id.toString())
            ? "friend"
            : followerIds.has(u._id.toString())
              ? "follower"
              : getConnectionStatus(currentUser, u._id),
        lastActiveAt: u.lastActiveAt,
        isOnline: isOnline(u.lastActiveAt),
        isChatPaid: Boolean(u.chatPaidUntil && new Date(u.chatPaidUntil).getTime() > Date.now()),
        chatPaidUntil: u.chatPaidUntil || null,
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
    const targetFollowing = (targetUser.following || []).map((id) => id.toString());

    if (currentFollowing.includes(targetUserId)) {
      await User.findByIdAndUpdate(currentUserId, { $pull: { following: targetUserId } });
      await notifyUsers([targetUserId], {
        title: "Unfollowed",
        body: `${currentUser.name} unfollowed you.`,
        data: { type: "unfollowed", userId: currentUserId },
      });
      await AppNotification.create({ userId: targetUserId, title: "Unfollowed", body: `${currentUser.name} unfollowed you.`, type: "community", refType: "user", refId: currentUserId });
      return res.json({ ok: true, status: incoming.includes(targetUserId) ? "follower" : "none", message: "Unfollowed" });
    }

    if (incoming.includes(targetUserId)) {
      await Promise.all([
        User.findByIdAndUpdate(currentUserId, {
          $pull: { followRequests: targetUserId },
          $addToSet: { following: targetUserId },
        }),
        User.findByIdAndUpdate(targetUserId, { $addToSet: { following: currentUserId } }),
      ]);
      await notifyUsers([targetUserId], {
        title: "Connection accepted",
        body: `${currentUser.name} accepted your follow request.`,
        data: { type: "connection_accepted", userId: currentUserId },
      });
      await AppNotification.create({ userId: targetUserId, title: "Connection accepted", body: `${currentUser.name} accepted your follow request.`, type: "community", refType: "user", refId: currentUserId });
      return res.json({ ok: true, status: "friend", message: "Connection request accepted" });
    }

    if (targetFollowing.includes(currentUserId)) {
      await User.findByIdAndUpdate(currentUserId, { $addToSet: { following: targetUserId } });
      await notifyUsers([targetUserId], {
        title: "Followed back",
        body: `${currentUser.name} followed you back.`,
        data: { type: "follow_back", userId: currentUserId },
      });
      await AppNotification.create({ userId: targetUserId, title: "Followed back", body: `${currentUser.name} followed you back.`, type: "community", refType: "user", refId: currentUserId });
      return res.json({ ok: true, status: "friend", message: "Followed back" });
    }

    if (targetRequests.includes(currentUserId)) {
      await User.findByIdAndUpdate(targetUserId, { $pull: { followRequests: currentUserId } });
      await notifyUsers([targetUserId], {
        title: "Request cancelled",
        body: `${currentUser.name} cancelled a follow request.`,
        data: { type: "connection_cancelled", userId: currentUserId },
      });
      await AppNotification.create({ userId: targetUserId, title: "Request cancelled", body: `${currentUser.name} cancelled a follow request.`, type: "community", refType: "user", refId: currentUserId });
      return res.json({ ok: true, status: "none", message: "Connection request cancelled" });
    }

    if (!targetRequests.includes(currentUserId)) {
      await User.findByIdAndUpdate(targetUserId, { $addToSet: { followRequests: currentUserId } });
      await notifyUsers([targetUserId], {
        title: "New follow request",
        body: `${currentUser.name} wants to connect with you.`,
        data: { type: "connection_request", userId: currentUserId },
      });
      await AppNotification.create({ userId: targetUserId, title: "New follow request", body: `${currentUser.name} wants to connect with you.`, type: "community", refType: "user", refId: currentUserId });
    }
    res.json({ ok: true, status: "requested", message: "Connection request sent" });
  }),
);

users.post(
  "/:id/remove-follower",
  auth(),
  requireUser,
  asyncHandler(async (req, res) => {
    const currentUserId = req.auth.id;
    const followerId = req.params.id;
    if (currentUserId === followerId) return res.status(400).json({ error: "Cannot remove yourself" });

    const [currentUser, follower] = await Promise.all([
      User.findById(currentUserId),
      User.findById(followerId),
    ]);
    if (!currentUser || !follower) return res.status(404).json({ error: "User not found" });

    await User.findByIdAndUpdate(followerId, { $pull: { following: currentUserId } });
    await notifyUsers([followerId], {
      title: "Follower removed",
      body: `${currentUser.name} removed you as a follower.`,
      data: { type: "follower_removed", userId: currentUserId },
    });
    await AppNotification.create({ userId: followerId, title: "Follower removed", body: `${currentUser.name} removed you as a follower.`, type: "community", refType: "user", refId: currentUserId });

    const stillFollowing = (currentUser.following || []).map((id) => id.toString()).includes(followerId);
    res.json({ ok: true, status: stillFollowing ? "following" : "none", message: "Follower removed" });
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
    await notifyUsers([requesterId], {
      title: "Connection accepted",
      body: "Your follow request was accepted.",
      data: { type: "connection_accepted", userId: currentUserId },
    });
    await AppNotification.create({ userId: requesterId, title: "Connection accepted", body: "Your follow request was accepted.", type: "community", refType: "user", refId: currentUserId });

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
    const targetFollowing = (targetUser.following || []).map((id) => id.toString());

    if (following.includes(targetUserId)) {
      await User.findByIdAndUpdate(req.auth.id, { $pull: { following: targetUserId } });
      return res.json({ ok: true, status: "none", isFollowing: false });
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

    if (targetFollowing.includes(req.auth.id)) {
      await User.findByIdAndUpdate(req.auth.id, { $addToSet: { following: targetUserId } });
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
  auth(false),
  asyncHandler(async (req, res) => {
    if (req.auth?.type === "user") await User.findByIdAndUpdate(req.auth.id, { lastActiveAt: new Date() });
    const user = await User.findById(req.params.id).select("name email photoUrl headline college chatPaidUntil createdAt lastActiveAt following").lean();
    if (!user) return res.status(404).json({ error: "User not found" });
    const viewer = req.auth?.type === "user" ? await User.findById(req.auth.id).select("following").lean() : null;
    const userFollowing = (user.following || []).map((id) => id.toString());
    const viewerFollowing = (viewer?.following || []).map((id) => id.toString());
    const isFriend = Boolean(
      req.auth?.id &&
        userFollowing.includes(req.auth.id.toString()) &&
        viewerFollowing.includes(user._id.toString()),
    );

    const [postsCount, followersCount] = await Promise.all([
      Post.countDocuments({ authorId: user._id, status: "published" }),
      User.countDocuments({ following: user._id }),
    ]);

    res.json({
      user: {
        id: user._id.toString(),
        name: user.name || "",
        email: user.email || "",
        photoUrl: user.photoUrl || "",
        headline: user.headline || "",
        college: user.college || "",
        chatPaidUntil: user.chatPaidUntil || null,
        isChatPaid: Boolean(user.chatPaidUntil && new Date(user.chatPaidUntil).getTime() > Date.now()),
        postsCount,
        followersCount,
        followingCount: user.following ? user.following.length : 0,
        isFriend,
        lastActiveAt: user.lastActiveAt,
        isOnline: isOnline(user.lastActiveAt),
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
      User.find(filter).select("name email college headline photoUrl blocked createdAt chatPaidUntil").sort({ createdAt: -1 }).skip(skip).limit(limitNum),
      User.countDocuments(filter),
    ]);
    res.json({
      items: items.map((user) => ({
        ...user.toObject(),
        isChatPaid: Boolean(user.chatPaidUntil && user.chatPaidUntil > new Date()),
      })),
      total,
      page: pageNum,
      limit: limitNum,
      chatPlanDurationMonths: paidChatMonths,
    });
  }),
);

users.put(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const patch = {};
    for (const field of ["name", "email", "college", "headline", "blocked"]) {
      if (req.body?.[field] !== undefined) patch[field] = req.body[field];
    }
    if (typeof req.body?.password === "string" && req.body.password) {
      patch.passwordHash = await bcrypt.hash(req.body.password, 10);
    }
    const item = await User.findById(req.params.id);
    if (!item) return res.status(404).json({ error: "User not found" });
    Object.assign(item, patch);
    if (typeof req.body?.chatPlanEnabled === "boolean") {
      if (req.body.chatPlanEnabled) {
        const now = new Date();
        const startAt = item.chatPaidUntil && item.chatPaidUntil > now ? item.chatPaidUntil : now;
        item.chatPaidUntil = addCalendarMonths(startAt, paidChatMonths);
      } else {
        item.chatPaidUntil = null;
      }
    }
    await item.save();
    const safeItem = await User.findById(item._id).select("-passwordHash -chatPaymentOrders -fcmTokens -photoData").lean();
    res.json({ item: safeItem, isChatPaid: Boolean(item.chatPaidUntil && item.chatPaidUntil > new Date()) });
  }),
);

users.delete(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    await AiChatMessage.deleteMany({ userId: req.params.id });
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
