import { Router } from "express";
import { Post } from "../models/index.js";
import { auth, requireAdmin, requireUser, asyncHandler } from "../middleware/auth.js";

const router = Router();

router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { scope, authorId, q, page = 1, limit = 20, all } = req.query;
    const filter = {};
    if (!all) filter.status = "published";
    if (scope === "mine" && authorId) filter.authorId = authorId;
    if (q) filter.$or = [{ title: new RegExp(q, "i") }, { content: new RegExp(q, "i") }, { tags: new RegExp(q, "i") }];
    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      Post.find(filter).sort({ createdAt: -1 }).skip(skip).limit(Number(limit)),
      Post.countDocuments(filter),
    ]);
    res.json({ items, total });
  }),
);

router.get("/:id", asyncHandler(async (req, res) => {
  const item = await Post.findById(req.params.id);
  if (!item) return res.status(404).json({ error: "Post not found" });
  res.json({ item });
}));

/* App users create their own posts */
router.post("/", auth(), requireUser, asyncHandler(async (req, res) => {
  const item = await Post.create({
    ...req.body,
    authorType: "user",
    authorModel: "User",
    authorId: req.auth.id,
  });
  res.status(201).json({ item });
}));

router.post("/:id/like", auth(), requireUser, asyncHandler(async (req, res) => {
  const item = await Post.findByIdAndUpdate(req.params.id, { $inc: { likes: 1 } }, { new: true });
  res.json({ item });
}));

/* Admin: create official posts, moderate everything */
router.post("/admin", auth(), requireAdmin, asyncHandler(async (req, res) => {
  const item = await Post.create({
    ...req.body,
    authorType: "admin",
    authorModel: "Admin",
    authorId: req.auth.id,
    authorName: req.body.authorName || "Rishikesh Yadav",
  });
  res.status(201).json({ item });
}));

router.put("/:id", auth(), requireAdmin, asyncHandler(async (req, res) => {
  const item = await Post.findByIdAndUpdate(req.params.id, req.body, { new: true });
  if (!item) return res.status(404).json({ error: "Post not found" });
  res.json({ item });
}));

router.delete("/:id", auth(), requireAdmin, asyncHandler(async (req, res) => {
  await Post.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
}));

export default router;
