import { Router } from "express";
import { LegalUpdate, AppNotification } from "../models/index.js";
import { auth, requireAdmin, asyncHandler } from "../middleware/auth.js";
import { validateSafeUrl } from "../utils/security.js";
import { notifyAllUsers } from "../services/notifications.js";

const router = Router();

router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { court, category, q, page = 1, limit = 20, all } = req.query;
    const filter = {};
    if (!all) filter.published = true;
    if (court && court !== "Latest" && court !== "All") filter.court = court;
    if (category && category !== "All") filter.category = category;
    if (q) {
      const rx = new RegExp(q.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      filter.$or = [{ title: rx }, { summary: rx }, { body: rx }, { source: rx }];
    }
    const pageNum = Math.max(1, Number(page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(limit) || 20));
    const skip = (pageNum - 1) * limitNum;

    const [items, total] = await Promise.all([
      LegalUpdate.find(filter).sort({ publishedAt: -1 }).skip(skip).limit(limitNum),
      LegalUpdate.countDocuments(filter),
    ]);
    res.json({ items, total, page: pageNum, limit: limitNum });
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
    await AppNotification.create({
      userId: null,
      title: "New Legal Update",
      body: item.title,
      type: "update",
      refType: "update",
      refId: item._id.toString(),
    });
    await notifyAllUsers({
      title: "New Legal Update",
      body: item.title,
      data: { type: "update", refType: "update", refId: item._id.toString(), updateId: item._id.toString() },
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
    await notifyAllUsers({
      title: "Legal update changed",
      body: item.title,
      data: { type: "legal_update_changed", updateId: item._id.toString() },
    });
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
