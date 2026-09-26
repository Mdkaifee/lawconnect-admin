import { Router } from "express";
import { Case } from "../models/index.js";
import { IndianKanoonService } from "../services/indianKanoon.js";
import { auth, requireAdmin, asyncHandler } from "../middleware/auth.js";
import { sanitizeLogOutput } from "../utils/security.js";
import mongoose from "mongoose";

const router = Router();

/**
 * Integration & Sync status check for Admin UI
 */
router.get(
  "/integration-status",
  auth(),
  requireAdmin,
  asyncHandler(async (_req, res) => {
    const status = await IndianKanoonService.checkStatus();
    res.json(status);
  }),
);

router.get(
  "/sync-status",
  auth(),
  requireAdmin,
  asyncHandler(async (_req, res) => {
    const total = await Case.countDocuments();
    const status = IndianKanoonService.getSyncStatus(total);
    res.json(status);
  }),
);

/**
 * Trigger manual fetch from Indian Kanoon to save in MongoDB
 */
router.post(
  "/sync-kanoon",
  auth(),
  requireAdmin,
  asyncHandler(async (_req, res) => {
    const result = await IndianKanoonService.syncLandmarkCasesToDb(Case);
    res.json(result);
  }),
);

/**
 * Public: Search cases (Hybrid: Curated Database + Indian Kanoon API)
 * Supports query (name/keywords/citation), court filter, year/date range, pagination.
 */
router.get(
  "/search",
  asyncHandler(async (req, res) => {
    const { q = "", court, year, fromYear, toYear, page = 1, limit = 20, provider = "auto" } = req.query;
    const cleanQuery = (q || "").trim();
    const pageNum = Math.max(1, Number(page) || 1);
    const limitNum = Math.min(50, Math.max(1, Number(limit) || 20));

    // 1. If Indian Kanoon is explicitly requested or query is provided and Kanoon is configured
    if (provider === "indian_kanoon" || (cleanQuery && provider === "auto" && IndianKanoonService.isConfigured())) {
      try {
        const kanoonResults = await IndianKanoonService.search({
          query: cleanQuery,
          page: pageNum,
          court: court && court !== "All" ? court : undefined,
          fromYear: fromYear || year,
          toYear: toYear || year,
        });

        // Also fetch any local curated matches for page 1 to highlight landmark summaries
        let curatedMatches = [];
        if (pageNum === 1 && cleanQuery) {
          const rx = new RegExp(cleanQuery.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
          curatedMatches = await Case.find({
            published: true,
            $or: [{ title: rx }, { citation: rx }, { tags: rx }],
          })
            .limit(3)
            .lean();
        }

        const normalizedCurated = curatedMatches.map((c) => ({
          id: c._id.toString(),
          providerId: c.providerId || c._id.toString(),
          provider: "curated",
          title: c.title,
          court: c.court,
          courtType: c.courtType,
          dateOfJudgment: c.dateOfJudgment ? c.dateOfJudgment.toISOString() : (c.year ? String(c.year) : ""),
          citation: c.citation || "",
          snippet: c.summary || c.simpleExplanation || "",
          summary: c.summary || "",
          isCurated: true,
          isFeatured: c.isFeatured,
          sourceUrl: c.judgmentPdfUrl || "",
        }));

        // Combine curated matches at the top (avoiding duplicate titles)
        const combinedItems = [
          ...normalizedCurated,
          ...kanoonResults.items.filter(
            (k) => !normalizedCurated.some((c) => c.title.toLowerCase() === k.title.toLowerCase()),
          ),
        ];

        return res.json({
          items: combinedItems,
          total: kanoonResults.total + normalizedCurated.length,
          page: pageNum,
          limit: limitNum,
          provider: "hybrid",
        });
      } catch (err) {
        // Fallback gracefully to local database if Kanoon fails or rate-limited
        console.error("Indian Kanoon search error, falling back to local DB:", sanitizeLogOutput(err.message));
      }
    }

    // 2. Database search fallback / default
    const filter = { published: true };
    if (court && court !== "All") filter.courtType = court;
    if (year) filter.year = Number(year);
    if (cleanQuery) {
      const rx = new RegExp(cleanQuery.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      filter.$or = [{ title: rx }, { citation: rx }, { summary: rx }, { court: rx }, { tags: rx }];
    }

    const skip = (pageNum - 1) * limitNum;
    const [items, total] = await Promise.all([
      Case.find(filter).sort({ isFeatured: -1, dateOfJudgment: -1, createdAt: -1 }).skip(skip).limit(limitNum).lean(),
      Case.countDocuments(filter),
    ]);

    const normalized = items.map((c) => ({
      id: c._id.toString(),
      providerId: c.providerId || c._id.toString(),
      provider: "curated",
      title: c.title,
      court: c.court,
      courtType: c.courtType,
      dateOfJudgment: c.dateOfJudgment ? c.dateOfJudgment.toISOString() : (c.year ? String(c.year) : ""),
      citation: c.citation || "",
      snippet: c.summary || c.simpleExplanation || "",
      summary: c.summary || "",
      simpleExplanation: c.simpleExplanation || "",
      isCurated: true,
      isFeatured: c.isFeatured,
      sourceUrl: c.judgmentPdfUrl || "",
    }));

    res.json({
      items: normalized,
      total,
      page: pageNum,
      limit: limitNum,
      provider: "curated",
    });
  }),
);

/**
 * Public: List curated cases with standard filtering
 */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { q, court, year, category, tag, isFeatured, page = 1, limit = 20, all } = req.query;
    const filter = {};
    if (!all) filter.published = true;
    if (court && court !== "All") filter.courtType = court;
    if (year) filter.year = Number(year);
    if (category) filter.categories = category;
    if (tag) filter.tags = tag;
    if (isFeatured === "true") filter.isFeatured = true;

    if (q) {
      const rx = new RegExp(q.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      filter.$or = [{ title: rx }, { citation: rx }, { summary: rx }, { court: rx }, { tags: rx }];
    }

    const pageNum = Math.max(1, Number(page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(limit) || 20));
    const skip = (pageNum - 1) * limitNum;

    const [items, total] = await Promise.all([
      Case.find(filter).sort({ isFeatured: -1, dateOfJudgment: -1, createdAt: -1 }).skip(skip).limit(limitNum),
      Case.countDocuments(filter),
    ]);

    res.json({ items, total, page: pageNum, limit: limitNum });
  }),
);

/**
 * Direct Document retrieval by Indian Kanoon docId
 */
router.get(
  "/doc/:docId",
  asyncHandler(async (req, res) => {
    const { docId } = req.params;
    try {
      const doc = await IndianKanoonService.getDocument(docId);
      res.json({ item: doc });
    } catch (err) {
      res.status(404).json({ error: err.message || "Failed to retrieve judgment document" });
    }
  }),
);

/**
 * Fetch original court copy (PDF or binary) if available
 */
router.get(
  "/doc/:docId/fragments",
  asyncHandler(async (req, res) => {
    const { docId } = req.params;
    const { q = "" } = req.query;
    try {
      const fragments = await IndianKanoonService.getDocumentFragments(docId, q);
      res.json({ item: fragments });
    } catch (err) {
      res.status(404).json({ error: err.message || "Document fragments unavailable." });
    }
  }),
);

router.get(
  "/doc/:docId/orig",
  asyncHandler(async (req, res) => {
    const { docId } = req.params;
    try {
      const orig = await IndianKanoonService.getOriginalDocument(docId);
      if (orig && orig.isBinary) {
        res.setHeader("Content-Type", orig.contentType || "application/pdf");
        return res.send(Buffer.from(orig.buffer));
      } else if (orig && orig.text) {
        return res.type("text/html").send(orig.text);
      }
      res.status(404).json({ error: "Original court copy not available for this document." });
    } catch (err) {
      res.status(404).json({ error: err.message || "Original court copy unavailable." });
    }
  }),
);

/**
 * Case details by ID (Supports MongoDB ObjectId or Indian Kanoon 'ik_<id>' format)
 */
router.get(
  "/:id",
  asyncHandler(async (req, res) => {
    const { id } = req.params;

    // If ID is an Indian Kanoon identifier
    if (id.startsWith("ik_")) {
      try {
        const kanoonDoc = await IndianKanoonService.getDocument(id);
        return res.json({ item: kanoonDoc });
      } catch (err) {
        return res.status(404).json({ error: err.message || "Judgment not found on Indian Kanoon" });
      }
    }

    // Check if valid Mongo ObjectId
    if (mongoose.Types.ObjectId.isValid(id)) {
      const item = await Case.findById(id);
      if (item) {
        // If the curated case links to a Kanoon doc and lacks full text, enrich it
        let citedCases = [];
        let citingCases = [];

        if (item.providerId && IndianKanoonService.isConfigured()) {
          try {
            const remote = await IndianKanoonService.getDocument(item.providerId);
            citedCases = remote.cites || [];
            citingCases = remote.citedBy || [];
            if (!item.fullText && remote.fullText) {
              item.fullText = remote.fullText;
            }
          } catch (e) {
            // Non-fatal if enrichment fails
          }
        }

        return res.json({
          item: {
            ...item.toObject(),
            cites: citedCases,
            citedBy: citingCases,
            isCurated: true,
          },
        });
      }
    }

    // Fallback attempt with provider ID if numeric
    if (/^\d+$/.test(id)) {
      try {
        const kanoonDoc = await IndianKanoonService.getDocument(id);
        return res.json({ item: kanoonDoc });
      } catch (err) {
        // Continue to 404
      }
    }

    res.status(404).json({ error: "Case not found" });
  }),
);

/* ---------------- Admin CRUD (Curated Landmark Judgments) ---------------- */
router.post(
  "/",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const item = await Case.create(req.body);
    res.status(201).json({ item });
  }),
);

router.put(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const item = await Case.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!item) return res.status(404).json({ error: "Case not found" });
    res.json({ item });
  }),
);

router.delete(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    await Case.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  }),
);

export default router;
