import { Router } from "express";
import bcrypt from "bcryptjs";
import { Admin, User } from "../models/index.js";
import { signToken, auth, asyncHandler } from "../middleware/auth.js";

const router = Router();

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
    const token = signToken({ type: "user", id: user._id.toString() });
    res.status(201).json({ token, user: { id: user._id, name: user.name, email: user.email } });
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
    const token = signToken({ type: "user", id: user._id.toString() });
    res.json({ token, user: { id: user._id, name: user.name, email: user.email, photoUrl: user.photoUrl } });
  }),
);

router.get(
  "/me",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const user = await User.findById(req.auth.id).select("-passwordHash");
    res.json({ user });
  }),
);

router.put(
  "/me",
  auth(),
  asyncHandler(async (req, res) => {
    if (req.auth.type !== "user") return res.status(403).json({ error: "User only" });
    const { name, photoUrl, headline, college } = req.body || {};
    const user = await User.findByIdAndUpdate(
      req.auth.id,
      { $set: { ...(name && { name }), photoUrl, headline, college } },
      { new: true },
    ).select("-passwordHash");
    res.json({ user });
  }),
);

/* ---- Follow / Unfollow Author (Prevent Self-Follow) ---- */
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

    const currentUser = await User.findById(currentUserId);
    if (!currentUser) return res.status(404).json({ error: "User not found" });

    const followingList = (currentUser.following || []).map((id) => id.toString());
    const isAlreadyFollowing = followingList.includes(authorId);

    let updatedUser;
    if (isAlreadyFollowing) {
      updatedUser = await User.findByIdAndUpdate(
        currentUserId,
        { $pull: { following: authorId } },
        { new: true },
      );
    } else {
      updatedUser = await User.findByIdAndUpdate(
        currentUserId,
        { $addToSet: { following: authorId } },
        { new: true },
      );
    }

    const updatedFollowing = (updatedUser.following || []).map((id) => id.toString());
    res.json({
      ok: true,
      isFollowing: !isAlreadyFollowing,
      message: !isAlreadyFollowing ? "Author followed successfully" : "Author unfollowed successfully",
      following: updatedFollowing,
    });
  }),
);

/* ---- Get current user's followed authors ---- */
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

export default router;
