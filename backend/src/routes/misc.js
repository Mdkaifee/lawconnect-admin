import { Router } from "express";
import bcrypt from "bcryptjs";
import { Category, Note, Bookmark, History, User, Case, Act, Post, LegalUpdate } from "../models/index.js";
import { auth, requireAdmin, requireUser, asyncHandler } from "../middleware/auth.js";

export const categories = Router();

categories.get("/", asyncHandler(async (_req, res) => {
  const items = await Category.find().sort({ order: 1, name: 1 });
  res.json({ items });
}));
categories.post("/", auth(), requireAdmin, asyncHandler(async (req, res) => {
  res.status(201).json({ item: await Category.create(req.body) });
}));
categories.put("/:id", auth(), requireAdmin, asyncHandler(async (req, res) => {
  res.json({ item: await Category.findByIdAndUpdate(req.params.id, req.body, { new: true }) });
}));
categories.delete("/:id", auth(), requireAdmin, asyncHandler(async (req, res) => {
  await Category.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
}));

/* ---------------- Notes (app user) ---------------- */
export const notes = Router();
notes.use(auth(), requireUser);
notes.get("/", asyncHandler(async (req, res) => {
  const filter = { userId: req.auth.id };
  if (req.query.refType) filter.refType = req.query.refType;
  res.json({ items: await Note.find(filter).sort({ updatedAt: -1 }) });
}));
notes.post("/", asyncHandler(async (req, res) => {
  res.status(201).json({ item: await Note.create({ ...req.body, userId: req.auth.id }) });
}));
notes.put("/:id", asyncHandler(async (req, res) => {
  res.json({ item: await Note.findOneAndUpdate({ _id: req.params.id, userId: req.auth.id }, req.body, { new: true }) });
}));
notes.delete("/:id", asyncHandler(async (req, res) => {
  await Note.findOneAndDelete({ _id: req.params.id, userId: req.auth.id });
  res.json({ ok: true });
}));

/* ---------------- Bookmarks + reading history ---------------- */
export const bookmarks = Router();
bookmarks.use(auth(), requireUser);
bookmarks.get("/", asyncHandler(async (req, res) => {
  const filter = { userId: req.auth.id };
  if (req.query.refType) filter.refType = req.query.refType;
  res.json({ items: await Bookmark.find(filter).sort({ createdAt: -1 }) });
}));
bookmarks.post("/", asyncHandler(async (req, res) => {
  const item = await Bookmark.findOneAndUpdate(
    { userId: req.auth.id, refType: req.body.refType, refId: req.body.refId },
    { $set: { ...req.body, userId: req.auth.id } },
    { upsert: true, new: true },
  );
  res.status(201).json({ item });
}));
bookmarks.delete("/:id", asyncHandler(async (req, res) => {
  await Bookmark.findOneAndDelete({ _id: req.params.id, userId: req.auth.id });
  res.json({ ok: true });
}));

export const history = Router();
history.use(auth(), requireUser);
history.get("/", asyncHandler(async (req, res) => {
  res.json({ items: await History.find({ userId: req.auth.id }).sort({ viewedAt: -1 }).limit(100) });
}));
history.post("/", asyncHandler(async (req, res) => {
  res.status(201).json({ item: await History.create({ ...req.body, userId: req.auth.id, viewedAt: new Date() }) });
}));

/* ---------------- Admin: users + stats ---------------- */
export const users = Router();
users.use(auth(), requireAdmin);
users.get("/", asyncHandler(async (req, res) => {
  const filter = req.query.q ? { $or: [{ name: new RegExp(req.query.q, "i") }, { email: new RegExp(req.query.q, "i") }] } : {};
  res.json({ items: await User.find(filter).select("-passwordHash").sort({ createdAt: -1 }).limit(200) });
}));
users.put("/:id", asyncHandler(async (req, res) => {
  const patch = { ...req.body };
  if (patch.password) {
    patch.passwordHash = await bcrypt.hash(patch.password, 10);
    delete patch.password;
  }
  res.json({ item: await User.findByIdAndUpdate(req.params.id, patch, { new: true }).select("-passwordHash") });
}));
users.delete("/:id", asyncHandler(async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
}));

export const stats = Router();
stats.get("/", auth(), requireAdmin, asyncHandler(async (_req, res) => {
  const [cases, acts, posts, updates, appUsers, notesCount, bookmarksCount] = await Promise.all([
    Case.countDocuments(), Act.countDocuments(), Post.countDocuments(),
    LegalUpdate.countDocuments(), User.countDocuments(), Note.countDocuments(), Bookmark.countDocuments(),
  ]);
  const recentCases = await Case.find().sort({ createdAt: -1 }).limit(5).select("title citation court createdAt");
  const recentPosts = await Post.find().sort({ createdAt: -1 }).limit(5).select("title authorName createdAt status");
  res.json({ counts: { cases, acts, posts, updates, users: appUsers, notes: notesCount, bookmarks: bookmarksCount }, recentCases, recentPosts });
}));
