import { Router } from "express";
import { LegalUpdate } from "../models/index.js";
import { auth, requireAdmin, asyncHandler } from "../middleware/auth.js";

const router = Router();

router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { court, limit = 30, all } = req.query;
    const filter = {};
    if (!all) filter.published = true;
    if (court && court !== "Latest") filter.court = court;
    const items = await LegalUpdate.find(filter).sort({ publishedAt: -1 }).limit(Number(limit));
    res.json({ items, total: items.length });
  }),
);

router.get("/:id", asyncHandler(async (req, res) => {
  const item = await LegalUpdate.findById(req.params.id);
  if (!item) return res.status(404).json({ error: "Update not found" });
  res.json({ item });
}));

router.post("/", auth(), requireAdmin, asyncHandler(async (req, res) => {
  const item = await LegalUpdate.create(req.body);
  res.status(201).json({ item });
}));

router.put("/:id", auth(), requireAdmin, asyncHandler(async (req, res) => {
  const item = await LegalUpdate.findByIdAndUpdate(req.params.id, req.body, { new: true });
  if (!item) return res.status(404).json({ error: "Update not found" });
  res.json({ item });
}));

router.delete("/:id", auth(), requireAdmin, asyncHandler(async (req, res) => {
  await LegalUpdate.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
}));

export default router;
