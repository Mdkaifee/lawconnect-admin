import { Router } from "express";
import { LegalUpdate } from "../models/index.js";
import { auth, requireAdmin, asyncHandler } from "../middleware/auth.js";
import { validateSafeUrl } from "../utils/security.js";

const router = Router();

router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { court, category, q, limit = 50, all } = req.query;
    const filter = {};
    if (!all) filter.published = true;
    if (court && court !== "Latest" && court !== "All") filter.court = court;
    if (category && category !== "All") filter.category = category;
    if (q) {
      const rx = new RegExp(q.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      filter.$or = [{ title: rx }, { summary: rx }, { body: rx }, { source: rx }];
    }
    const items = await LegalUpdate.find(filter).sort({ publishedAt: -1 }).limit(Number(limit));
    res.json({ items, total: items.length });
  }),
);

router.get(
  "/:id",
  asyncHandler(async (req, res) => {
    const item = await LegalUpdate.findById(req.params.id);
    if (!item) return res.status(404).json({ error: "Update not found" });
    res.json({ item });
  }),
);

router.post(
  "/",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    // Validate sourceUrl if supplied
    if (req.body.sourceUrl) {
      const urlCheck = validateSafeUrl(req.body.sourceUrl);
      if (!urlCheck.safe) {
        return res.status(400).json({ error: `Invalid source URL: ${urlCheck.reason}` });
      }
    }
    const item = await LegalUpdate.create({
      ...req.body,
      verifiedAt: req.body.verificationStatus === "verified" ? new Date() : undefined,
    });
    res.status(201).json({ item });
  }),
);

router.put(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    if (req.body.sourceUrl) {
      const urlCheck = validateSafeUrl(req.body.sourceUrl);
      if (!urlCheck.safe) {
        return res.status(400).json({ error: `Invalid source URL: ${urlCheck.reason}` });
      }
    }
    const patch = { ...req.body };
    if (patch.verificationStatus === "verified" && !patch.verifiedAt) {
      patch.verifiedAt = new Date();
    }
    const item = await LegalUpdate.findByIdAndUpdate(req.params.id, patch, { new: true });
    if (!item) return res.status(404).json({ error: "Update not found" });
    res.json({ item });
  }),
);

router.delete(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    await LegalUpdate.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  }),
);

export default router;
