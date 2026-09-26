import { Router } from "express";
import { Case } from "../models/index.js";
import { auth, requireAdmin, asyncHandler } from "../middleware/auth.js";

const router = Router();

/* Public: search + list. Supports name / court / year / citation search. */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { q, court, year, category, tag, page = 1, limit = 20, all } = req.query;
    const filter = {};
    if (!all) filter.published = true;
    if (court && court !== "All") filter.courtType = court;
    if (year) filter.year = Number(year);
    if (category) filter.categories = category;
    if (tag) filter.tags = tag;
    if (q) {
      const rx = new RegExp(q.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      filter.$or = [{ title: rx }, { citation: rx }, { summary: rx }, { court: rx }, { tags: rx }];
    }
    const skip = (Number(page) - 1) * Number(limit);
    const [items, total] = await Promise.all([
      Case.find(filter).sort({ dateOfJudgment: -1, createdAt: -1 }).skip(skip).limit(Number(limit)),
      Case.countDocuments(filter),
    ]);
    res.json({ items, total, page: Number(page), limit: Number(limit) });
  }),
);

router.get(
  "/:id",
  asyncHandler(async (req, res) => {
    const item = await Case.findById(req.params.id);
    if (!item) return res.status(404).json({ error: "Case not found" });
    res.json({ item });
  }),
);

/* Admin CRUD */
router.post("/", auth(), requireAdmin, asyncHandler(async (req, res) => {
  const item = await Case.create(req.body);
  res.status(201).json({ item });
}));

router.put("/:id", auth(), requireAdmin, asyncHandler(async (req, res) => {
  const item = await Case.findByIdAndUpdate(req.params.id, req.body, { new: true });
  if (!item) return res.status(404).json({ error: "Case not found" });
  res.json({ item });
}));

router.delete("/:id", auth(), requireAdmin, asyncHandler(async (req, res) => {
  await Case.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
}));

export default router;
