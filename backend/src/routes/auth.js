import { Router } from "express";
import bcrypt from "bcryptjs";
import { Admin, AppNotification, User, DeletionRequest, Post, Comment, Note, Bookmark, History, Report, Conversation, Message } from "../models/index.js";
import { signToken, auth, asyncHandler } from "../middleware/auth.js";
import { notifyUsers } from "../services/notifications.js";

const router = Router();

/**
 * Permanently purges all user data from the database.
 * Invoked when the 7-day grace period has expired.
 */
export async function purgeUserData(userId) {
  if (!userId) return;

  const user = await User.findById(userId);
  const userEmail = user?.email;

  // 1. Delete user-authored comments
  await Comment.deleteMany({ authorId: userId });

  // 2. Delete user-authored posts
  await Post.deleteMany({ authorId: userId });

  // 3. Remove user likes from all posts
  await Post.updateMany({ likedBy: userId }, { $pull: { likedBy: userId } });

  // 4. Delete user personal notes
  await Note.deleteMany({ userId });

  // 5. Delete bookmarks
  await Bookmark.deleteMany({ userId });

  // 6. Delete reading history
  await History.deleteMany({ userId });

  // 7. Delete reports filed by user
  await Report.deleteMany({ reporterId: userId });

  // 8. Delete conversations and messages involving user
  const conversations = await Conversation.find({ participants: userId }).select("_id");
  await Message.deleteMany({ $or: [{ senderId: userId }, { receiverId: userId }, { conversationId: { $in: conversations.map((c) => c._id) } }] });
  await Conversation.deleteMany({ participants: userId });

  // 9. Remove userId from other users' following lists
  await User.updateMany({ following: userId }, { $pull: { following: userId } });

  // 10. Mark all pending DeletionRequests as completed
  if (userEmail) {
    await DeletionRequest.updateMany(
      { $or: [{ userId }, { email: userEmail.toLowerCase() }], status: "pending" },
      { status: "completed", completedAt: new Date() }
    );
  } else {
    await DeletionRequest.updateMany(
      { userId, status: "pending" },
      { status: "completed", completedAt: new Date() }
    );
  }

  // 11. Permanently remove the user document
  await User.findByIdAndDelete(userId);
}

/* ---- Admin (owner) login ---- */
router.post(
  "/admin/login",
  asyncHandler(async (req, res) => {
    const { username, password } = req.body || {};
    if (!username || !password) return res.status(400).json({ error: "Username and password required" });

    const admin = await Admin.findOne({ username: new RegExp(`^${username}$`, "i") });
    if (!admin) return res.status(401).json({ error: "Invalid credentials" });

    const ok = await bcrypt.compare(password, admin.passwordHash);
    if (!ok) return res.status(401).json({ error: "Invalid credentials" });

    const token = signToken({ type: "admin", id: admin._id.toString(), username: admin.username });
    res.json({ token, admin: { id: admin._id, username: admin.username, name: admin.name, role: admin.role } });
  }),
);

router.get(
  "/admin/me",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "admin") return res.status(403).json({ error: "Admin only" });
    const admin = await Admin.findById(req.auth.id).select("-passwordHash");
    res.json({ admin });
  }),
);

router.post(
  "/admin/change-password",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "admin") return res.status(403).json({ error: "Admin only" });
    const { currentPassword, newPassword } = req.body || {};
    const admin = await Admin.findById(req.auth.id);
    if (!admin || !(await bcrypt.compare(currentPassword || "", admin.passwordHash))) {
      return res.status(401).json({ error: "Current password is incorrect" });
    }
    if (!newPassword || newPassword.length < 6) return res.status(400).json({ error: "New password too short" });
    admin.passwordHash = await bcrypt.hash(newPassword, 10);
    await admin.save();
    res.json({ ok: true });
  }),
);

/* ---- App user auth (Flutter) ---- */
router.post(
  "/register",
  asyncHandler(async (req, res) => {
    const { name, email, password } = req.body || {};
    if (!name || !email || !password) return res.status(400).json({ error: "name, email, password required" });
    const exists = await User.findOne({ email: email.toLowerCase() });
    if (exists) return res.status(409).json({ error: "Email already registered" });
    const user = await User.create({ name, email, passwordHash: await bcrypt.hash(password, 10) });
    user.lastActiveAt = new Date();
    await user.save();
    const token = signToken({ type: "user", id: user._id.toString() });
    res.status(201).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        photoUrl: user.photoUrl,
        headline: user.headline,
        college: user.college,
      },
    });
  }),
);

router.post(
  "/login",
  asyncHandler(async (req, res) => {
    const { email, password } = req.body || {};
    const user = await User.findOne({ email: (email || "").toLowerCase() });
    if (!user || !(await bcrypt.compare(password || "", user.passwordHash))) {
      return res.status(401).json({ error: "Invalid credentials" });
    }
    if (user.blocked) return res.status(403).json({ error: "Account blocked" });
    if (user.deletionRequested) return res.status(403).json({ error: "This account is inactive because deletion was requested." });

    const token = signToken({ type: "user", id: user._id.toString() });
    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        photoUrl: user.photoUrl,
        headline: user.headline,
        college: user.college,
      },
      restored: false,
    });
  }),
);

router.post(
  "/change-password",
  asyncHandler(async (req, res) => {
    const { email, currentPassword, newPassword, confirmPassword } = req.body || {};
    const normalizedEmail = (email || "").trim().toLowerCase();
    if (!normalizedEmail || !currentPassword || !newPassword || !confirmPassword) {
      return res.status(400).json({ error: "Email, current password, new password, and confirmation are required" });
    }
    if (newPassword.length < 6) return res.status(400).json({ error: "New password must be at least 6 characters" });
    if (newPassword !== confirmPassword) return res.status(400).json({ error: "New passwords do not match" });

    const user = await User.findOne({ email: normalizedEmail });
    if (!user || !(await bcrypt.compare(currentPassword, user.passwordHash))) {
      return res.status(401).json({ error: "Email or current password is incorrect" });
    }
    if (user.blocked || user.deletionRequested) return res.status(403).json({ error: "This account is inactive" });
    if (await bcrypt.compare(newPassword, user.passwordHash)) return res.status(400).json({ error: "New password must be different" });

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    await user.save();
    res.json({ ok: true, message: "Password changed successfully" });
  }),
);

router.get(
  "/me",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const user = await User.findByIdAndUpdate(req.auth.id, { lastActiveAt: new Date() }, { new: true }).select("-passwordHash -chatPaymentOrders -fcmTokens -photoData");
    res.json({ user });
  }),
);

router.put(
  "/me",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const { name, photoUrl, headline, college } = req.body || {};
    const patch = {};
    if (name) patch.name = name;
    if (photoUrl !== undefined) patch.photoUrl = photoUrl;
    if (headline !== undefined) patch.headline = headline;
    if (college !== undefined) patch.college = college;
    const user = await User.findByIdAndUpdate(
      req.auth.id,
      { $set: patch },
      { new: true },
    ).select("-passwordHash");
    res.json({ user });
  }),
);

router.post(
  "/fcm-token",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const { token } = req.body || {};
    if (!token) return res.status(400).json({ error: "token is required" });
    await User.findByIdAndUpdate(req.auth.id, { $addToSet: { fcmTokens: token } });
    res.json({ ok: true });
  }),
);

router.post(
  "/fcm-token/remove",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const { token } = req.body || {};
    if (!token) return res.status(400).json({ error: "token is required" });
    await User.findByIdAndUpdate(req.auth.id, { $pull: { fcmTokens: token } });
    res.json({ ok: true });
  }),
);

router.post(
  "/me/photo",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const { imageBase64, mimeType = "image/jpeg" } = req.body || {};
    if (!imageBase64) return res.status(400).json({ error: "imageBase64 is required" });

    const cleanBase64 = imageBase64.includes(",") ? imageBase64.split(",").pop() : imageBase64;
    const approxBytes = Math.ceil((cleanBase64.length * 3) / 4);
    if (approxBytes > 2 * 1024 * 1024) {
      return res.status(400).json({ error: "Profile image must be under 2MB." });
    }

    const publicBase = process.env.PUBLIC_API_BASE_URL || `${req.protocol}://${req.get("host")}`;
    const photoUrl = `${publicBase.replace(/\/$/, "")}/api/auth/users/${req.auth.id}/photo`;
    const user = await User.findByIdAndUpdate(
      req.auth.id,
      {
        $set: {
          photoData: cleanBase64,
          photoMimeType: mimeType,
          photoUrl,
        },
      },
      { new: true },
    ).select("-passwordHash -photoData");

    res.json({ user, photoUrl });
  }),
);

router.get(
  "/users/:id/photo",
  asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id).select("photoData photoMimeType");
    if (!user || !user.photoData) return res.status(404).json({ error: "Photo not found" });
    res.setHeader("Content-Type", user.photoMimeType || "image/jpeg");
    res.setHeader("Cache-Control", "public, max-age=86400");
    res.send(Buffer.from(user.photoData, "base64"));
  }),
);

/* ---- Connection request / accept friend (Prevent Self-Follow) ---- */
router.post(
  "/follow/:authorId",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const { authorId } = req.params;
    const currentUserId = req.auth.id;

    // DO NOT ALLOW TO FOLLOW MYSELF
    if (authorId === currentUserId) {
      return res.status(400).json({ error: "You cannot follow yourself" });
    }

    const [currentUser, targetUser] = await Promise.all([
      User.findById(currentUserId),
      User.findById(authorId),
    ]);
    if (!currentUser || !targetUser) return res.status(404).json({ error: "User not found" });

    const currentFollowing = (currentUser.following || []).map((id) => id.toString());
    const targetRequests = (targetUser.followRequests || []).map((id) => id.toString());
    const currentIncoming = (currentUser.followRequests || []).map((id) => id.toString());
    const targetFollowing = (targetUser.following || []).map((id) => id.toString());

    if (currentFollowing.includes(authorId)) {
      await User.findByIdAndUpdate(currentUserId, { $pull: { following: authorId } });
      await notifyUsers([authorId], {
        title: "Unfollowed",
        body: `${currentUser.name} unfollowed you.`,
        data: { type: "unfollowed", userId: currentUserId },
      });
      await AppNotification.create({
        userId: authorId,
        title: "Unfollowed",
        body: `${currentUser.name} unfollowed you.`,
        type: "community",
        refType: "user",
        refId: currentUserId,
      });
      const fresh = await User.findById(currentUserId);
      return res.json({
        ok: true,
        status: "none",
        message: "Connection removed",
        following: (fresh?.following || []).map((id) => id.toString()),
      });
    }

    if (currentIncoming.includes(authorId)) {
      await Promise.all([
        User.findByIdAndUpdate(currentUserId, {
          $pull: { followRequests: authorId },
          $addToSet: { following: authorId },
        }),
        User.findByIdAndUpdate(authorId, { $addToSet: { following: currentUserId } }),
      ]);
      await notifyUsers([authorId], {
        title: "Connection accepted",
        body: `${currentUser.name} accepted your follow request.`,
        data: { type: "connection_accepted", userId: currentUserId },
      });
      await AppNotification.create({
        userId: authorId,
        title: "Connection accepted",
        body: `${currentUser.name} accepted your follow request.`,
        type: "community",
        refType: "user",
        refId: currentUserId,
      });
      const fresh = await User.findById(currentUserId);
      return res.json({
        ok: true,
        status: "friend",
        isFollowing: true,
        message: "Connection request accepted",
        following: (fresh?.following || []).map((id) => id.toString()),
      });
    }

    if (targetFollowing.includes(currentUserId)) {
      await User.findByIdAndUpdate(currentUserId, { $addToSet: { following: authorId } });
      await notifyUsers([authorId], {
        title: "Followed back",
        body: `${currentUser.name} followed you back.`,
        data: { type: "follow_back", userId: currentUserId },
      });
      await AppNotification.create({
        userId: authorId,
        title: "Followed back",
        body: `${currentUser.name} followed you back.`,
        type: "community",
        refType: "user",
        refId: currentUserId,
      });
      const fresh = await User.findById(currentUserId);
      return res.json({
        ok: true,
        status: "friend",
        isFollowing: true,
        message: "Followed back",
        following: (fresh?.following || []).map((id) => id.toString()),
      });
    }

    if (targetRequests.includes(currentUserId)) {
      await User.findByIdAndUpdate(authorId, { $pull: { followRequests: currentUserId } });
      await notifyUsers([authorId], {
        title: "Request cancelled",
        body: `${currentUser.name} cancelled a follow request.`,
        data: { type: "connection_cancelled", userId: currentUserId },
      });
      await AppNotification.create({
        userId: authorId,
        title: "Request cancelled",
        body: `${currentUser.name} cancelled a follow request.`,
        type: "community",
        refType: "user",
        refId: currentUserId,
      });
      const fresh = await User.findById(currentUserId);
      return res.json({
        ok: true,
        status: "none",
        isFollowing: false,
        message: "Connection request cancelled",
        following: (fresh?.following || []).map((id) => id.toString()),
      });
    }

    if (!targetRequests.includes(currentUserId)) {
      await User.findByIdAndUpdate(authorId, { $addToSet: { followRequests: currentUserId } });
      await notifyUsers([authorId], {
        title: "New follow request",
        body: `${currentUser.name} wants to connect with you.`,
        data: { type: "connection_request", userId: currentUserId },
      });
      await AppNotification.create({
        userId: authorId,
        title: "New follow request",
        body: `${currentUser.name} wants to connect with you.`,
        type: "community",
        refType: "user",
        refId: currentUserId,
      });
    }

    const updatedUser = await User.findById(currentUserId);
    const updatedFollowing = (updatedUser?.following || []).map((id) => id.toString());
    res.json({
      ok: true,
      status: "requested",
      isFollowing: false,
      message: "Connection request sent",
      following: updatedFollowing,
    });
  }),
);

/* ---- Get current user's accepted connections ---- */
router.get(
  "/following",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const user = await User.findById(req.auth.id);
    if (!user) return res.status(404).json({ error: "User not found" });

    const followingIds = (user.following || []).map((id) => id.toString());
    res.json({
      following: followingIds,
    });
  }),
);

/* ---------------- 11. Account Deletion APIs ---------------- */

/**
 * In-app account deletion request (Authenticated).
 * Schedules account deletion in 7 days.
 */
router.post(
  "/delete-account",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const user = await User.findById(req.auth.id);
    if (!user) return res.status(404).json({ error: "User not found" });

    const { reason } = req.body || {};
    const now = new Date();
    const scheduledDueAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000); // 7 days

    user.deletionRequested = true;
    user.deletionRequestedAt = now;
    user.deletionDueAt = scheduledDueAt;
    user.deletionReason = reason || "User requested account deletion via mobile app";
    await user.save();

    await DeletionRequest.create({
      userId: user._id,
      email: user.email,
      reason: reason || "User requested account deletion via mobile app",
      source: "in_app",
      status: "pending",
      requestedAt: now,
      scheduledDeletionAt: scheduledDueAt,
    });

    res.json({
      ok: true,
      message: "Your account is scheduled for deletion. You have 7 days to log back in if you wish to cancel this request and restore your account. After 7 days, all your data will be permanently wiped.",
      scheduledDeletionAt: scheduledDueAt,
      gracePeriodDays: 7,
    });
  }),
);

router.post(
  "/request-web-deletion",
  asyncHandler(async (req, res) => {
    res.status(403).json({
      error: "Account deletion requests are only accepted from inside the signed-in mobile app.",
    });
  }),
);

/**
 * Cancel Account Deletion (Authenticated).
 */
router.post(
  "/cancel-deletion",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const user = await User.findById(req.auth.id);
    if (!user) return res.status(404).json({ error: "User not found" });

    user.deletionRequested = false;
    user.deletionRequestedAt = undefined;
    user.deletionDueAt = undefined;
    user.deletionReason = undefined;
    await user.save();

    await DeletionRequest.updateMany(
      { userId: user._id, status: "pending" },
      { status: "cancelled" }
    );

    res.json({
      ok: true,
      message: "Account deletion request has been cancelled. Your account is active.",
    });
  }),
);

/**
 * Check current user deletion status.
 */
router.get(
  "/deletion-status",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const user = await User.findById(req.auth.id).select("deletionRequested deletionRequestedAt deletionDueAt deletionReason");
    if (!user) return res.status(404).json({ error: "User not found" });

    res.json({
      deletionRequested: user.deletionRequested || false,
      deletionRequestedAt: user.deletionRequestedAt,
      deletionDueAt: user.deletionDueAt,
      deletionReason: user.deletionReason,
    });
  }),
);

export default router;
