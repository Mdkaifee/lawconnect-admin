import { Router } from "express";
import { Act } from "../models/index.js";
import { auth, requireAdmin, asyncHandler } from "../middleware/auth.js";

const router = Router();

/* Public: acts list + section search */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { q, type, all } = req.query;
    const filter = {};
    if (!all) filter.published = true;
    if (type && type !== "All Acts") filter.type = type.replace(" Acts", "");
    if (q) {
      const rx = new RegExp(q.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      filter.$or = [{ name: rx }, { shortName: rx }, { description: rx }, { "sections.number": rx }, { "sections.title": rx }];
    }
    const items = await Act.find(filter).sort({ name: 1 });
    res.json({ items, total: items.length });
  }),
);

router.get(
  "/search/sections",
  asyncHandler(async (req, res) => {
    const q = (req.query.q || "").trim();
    if (!q) return res.json({ items: [] });
    const rx = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
    const acts = await Act.find({ published: true, $or: [{ "sections.number": rx }, { "sections.title": rx }, { "sections.text": rx }] });
    const items = [];
    for (const act of acts) {
      for (const s of act.sections) {
        if (rx.test(s.number || "") || rx.test(s.title || "") || rx.test(s.text || "")) {
          items.push({ actId: act._id, actName: act.name, sectionId: s._id, number: s.number, title: s.title, text: s.text, explanation: s.explanation });
        }
      }
    }
    res.json({ items });
  }),
);

router.get(
  "/:id",
  asyncHandler(async (req, res) => {
    const item = await Act.findById(req.params.id);
    if (!item) return res.status(404).json({ error: "Act not found" });
    res.json({ item });
  }),
);

/* Admin CRUD (sections are edited inline with the act) */
router.post("/", auth(), requireAdmin, asyncHandler(async (req, res) => {
  const item = await Act.create(req.body);
  res.status(201).json({ item });
}));

router.put("/:id", auth(), requireAdmin, asyncHandler(async (req, res) => {
  const item = await Act.findByIdAndUpdate(req.params.id, req.body, { new: true });
  if (!item) return res.status(404).json({ error: "Act not found" });
  res.json({ item });
}));

router.delete("/:id", auth(), requireAdmin, asyncHandler(async (req, res) => {
  await Act.findByIdAndDelete(req.params.id);
  res.json({ ok: true });
}));

router.post("/:id/sections", auth(), requireAdmin, asyncHandler(async (req, res) => {
  const act = await Act.findById(req.params.id);
  if (!act) return res.status(404).json({ error: "Act not found" });
  act.sections.push(req.body);
  await act.save();
  res.status(201).json({ item: act });
}));

router.delete("/:id/sections/:sectionId", auth(), requireAdmin, asyncHandler(async (req, res) => {
  const act = await Act.findById(req.params.id);
  if (!act) return res.status(404).json({ error: "Act not found" });
  act.sections = act.sections.filter((s) => s._id.toString() !== req.params.sectionId);
  await act.save();
  res.json({ item: act });
}));

export default router;
