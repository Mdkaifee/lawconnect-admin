import { Router } from "express";
import { Act, AppNotification } from "../models/index.js";
import { auth, requireAdmin, asyncHandler } from "../middleware/auth.js";
import { validateSafeUrl } from "../utils/security.js";
import { notifyAllUsers } from "../services/notifications.js";

const router = Router();

/* ---------------- Public: acts list + section search ---------------- */
router.get(
  "/",
  asyncHandler(async (req, res) => {
    const { q, type, year, all, page = 1, limit = 20 } = req.query;
    const filter = {};
    if (!all) filter.published = { $ne: false };
    if (type && type !== "All" && type !== "All Acts") {
      filter.type = type.replace(" Acts", "");
    }
    if (year) {
      filter.year = Number(year);
    }
    if (q) {
      const rx = new RegExp(q.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
      filter.$or = [
        { name: rx },
        { shortName: rx },
        { description: rx },
        { "sections.number": rx },
        { "sections.title": rx },
      ];
    }
    const pageNum = Math.max(1, Number(page) || 1);
    const limitNum = Math.min(100, Math.max(1, Number(limit) || 20));
    const skip = (pageNum - 1) * limitNum;

    const [items, total] = await Promise.all([
      Act.find(filter).sort({ name: 1 }).skip(skip).limit(limitNum).lean(),
      Act.countDocuments(filter),
    ]);
    res.json({ items, total, page: pageNum, limit: limitNum });
  }),
);

router.get(
  "/search/sections",
  asyncHandler(async (req, res) => {
    const q = (req.query.q || "").trim();
    if (!q) return res.json({ items: [] });
    const rx = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i");
    const acts = await Act.find({
      published: { $ne: false },
      $or: [{ "sections.number": rx }, { "sections.title": rx }, { "sections.text": rx }],
    }).lean();

    const items = [];
    for (const act of acts) {
      for (const s of act.sections || []) {
        if (rx.test(s.number || "") || rx.test(s.title || "") || rx.test(s.text || "")) {
          items.push({
            actId: act._id,
            actName: act.name,
            actShortName: act.shortName,
            sectionId: s._id,
            number: s.number,
            title: s.title,
            chapter: s.chapter,
            text: s.text,
            explanation: s.explanation,
          });
        }
      }
    }
    res.json({ items, total: items.length });
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

/* ---------------- Admin: JSON / CSV Import Preview & Validation ---------------- */
/**
 * Accepts raw JSON string or structured array or CSV text of Acts and Sections.
 * Validates mandatory fields, checks for duplicate acts in database, checks source URLs against SSRF whitelist.
 */
router.post(
  "/import/preview",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const { format = "json", data } = req.body || {};

    if (!data) {
      return res.status(400).json({ error: "No data payload provided for import." });
    }

    let parsedActs = [];
    const errors = [];
    const warnings = [];

    // 1. Parsing payload
    if (format === "csv" || typeof data === "string") {
      const text = String(data).trim();
      if (text.startsWith("{") || text.startsWith("[")) {
        try {
          const parsed = JSON.parse(text);
          parsedActs = Array.isArray(parsed) ? parsed : [parsed];
        } catch (e) {
          return res.status(400).json({ error: `Invalid JSON syntax: ${e.message}` });
        }
      } else {
        // Parse CSV format: Expecting header "actName,shortName,year,type,sectionNumber,sectionTitle,sectionText,chapter"
        const lines = text.split(/\r?\n/).filter((l) => l.trim().length > 0);
        if (lines.length < 2) {
          return res.status(400).json({ error: "CSV data must contain header and at least 1 data row." });
        }

        const headerLine = lines[0];
        const headers = headerLine.split(",").map((h) => h.trim().toLowerCase().replace(/['"]/g, ""));
        const actMap = new Map();

        for (let i = 1; i < lines.length; i++) {
          const line = lines[i];
          // Simple CSV line parser handling quoted commas
          const regex = /(?:,|\n|^)("(?:(?:"")*[^"]*)*"|[^",\n]*|(?:\n|$))/g;
          const cols = [];
          let match;
          while ((match = regex.exec(line)) !== null && cols.length < headers.length) {
            let val = match[1] || "";
            if (val.startsWith('"') && val.endsWith('"')) {
              val = val.slice(1, -1).replace(/""/g, '"');
            }
            cols.push(val.trim());
          }

          const row = {};
          headers.forEach((h, idx) => {
            row[h] = cols[idx] || "";
          });

          const actName = row["actname"] || row["act_name"] || row["name"] || row["act"];
          if (!actName) {
            errors.push({ row: i + 1, message: "Missing Act Name." });
            continue;
          }

          if (!actMap.has(actName)) {
            actMap.set(actName, {
              name: actName,
              shortName: row["shortname"] || row["short_name"] || actName,
              year: Number(row["year"]) || new Date().getFullYear(),
              type: (row["type"] || "Central").toLowerCase().includes("state") ? "State" : "Central",
              description: row["description"] || "",
              sourceUrl: row["sourceurl"] || row["source_url"] || "",
              sections: [],
            });
          }

          const secNum = row["sectionnumber"] || row["section_number"] || row["section"] || row["number"];
          if (secNum) {
            actMap.get(actName).sections.push({
              number: String(secNum),
              title: row["sectiontitle"] || row["section_title"] || row["title"] || "",
              chapter: row["chapter"] || "",
              text: row["sectiontext"] || row["section_text"] || row["text"] || "",
              explanation: row["explanation"] || "",
            });
          }
        }
        parsedActs = Array.from(actMap.values());
      }
    } else if (Array.isArray(data)) {
      parsedActs = data;
    } else if (typeof data === "object") {
      parsedActs = [data];
    }

    if (parsedActs.length === 0) {
      return res.status(400).json({ error: "No valid acts could be parsed from input." });
    }

    // 2. Validate Acts and Sections
    const validatedActs = [];
    const existingActs = await Act.find({}, "name shortName").lean();
    const existingNameSet = new Set(existingActs.map((a) => a.name.toLowerCase()));
    const existingShortSet = new Set(existingActs.map((a) => (a.shortName || "").toLowerCase()).filter(Boolean));

    let totalSections = 0;

    for (let index = 0; index < parsedActs.length; index++) {
      const act = parsedActs[index];
      const rowIdx = index + 1;

      if (!act.name || typeof act.name !== "string" || !act.name.trim()) {
        errors.push({ row: rowIdx, message: "Act 'name' is required." });
        continue;
      }

      const cleanName = act.name.trim();
      const isDuplicate =
        existingNameSet.has(cleanName.toLowerCase()) ||
        (act.shortName && existingShortSet.has(act.shortName.toLowerCase()));

      // URL SSRF check
      if (act.sourceUrl) {
        const urlCheck = validateSafeUrl(act.sourceUrl);
        if (!urlCheck.safe) {
          warnings.push({
            row: rowIdx,
            message: `Source URL '${act.sourceUrl}' is outside trusted legal domains: ${urlCheck.reason}`,
          });
        }
      }

      const sections = Array.isArray(act.sections) ? act.sections : [];
      const validSections = [];
      const seenSecNums = new Set();

      for (let sIdx = 0; sIdx < sections.length; sIdx++) {
        const sec = sections[sIdx];
        if (!sec.number || !String(sec.number).trim()) {
          warnings.push({
            row: rowIdx,
            message: `Act '${cleanName}' section #${sIdx + 1} is missing a section number; skipped.`,
          });
          continue;
        }

        const secNumber = String(sec.number).trim();
        if (seenSecNums.has(secNumber)) {
          warnings.push({
            row: rowIdx,
            message: `Act '${cleanName}' has duplicate section number '${secNumber}'.`,
          });
        }
        seenSecNums.add(secNumber);

        validSections.push({
          number: secNumber,
          title: String(sec.title || "").trim(),
          chapter: String(sec.chapter || "").trim(),
          text: String(sec.text || "").trim(),
          explanation: String(sec.explanation || "").trim(),
          lastVerifiedDate: new Date(),
        });
      }

      totalSections += validSections.length;

      validatedActs.push({
        name: cleanName,
        shortName: act.shortName ? act.shortName.trim() : cleanName,
        actNumber: act.actNumber ? String(act.actNumber).trim() : "",
        year: Number(act.year) || new Date().getFullYear(),
        type: act.type === "State" ? "State" : "Central",
        jurisdiction: act.jurisdiction || "India",
        description: act.description || "",
        sourceUrl: act.sourceUrl || "https://www.indiacode.nic.in",
        repealStatus: act.repealStatus || "active",
        sectionsCount: validSections.length,
        isDuplicate,
        sections: validSections,
      });
    }

    res.json({
      summary: {
        totalActsParsed: parsedActs.length,
        validActsCount: validatedActs.length,
        totalSectionsCount: totalSections,
        duplicateCount: validatedActs.filter((a) => a.isDuplicate).length,
        errorCount: errors.length,
        warningCount: warnings.length,
      },
      errors,
      warnings,
      acts: validatedActs,
    });
  }),
);

/**
 * Commits verified acts to MongoDB
 */
router.post(
  "/import/confirm",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const { acts, overwriteDuplicates = false } = req.body || {};
    if (!Array.isArray(acts) || acts.length === 0) {
      return res.status(400).json({ error: "No acts provided to import." });
    }

    let createdCount = 0;
    let updatedCount = 0;

    for (const act of acts) {
      if (!act.name) continue;

      const existing = await Act.findOne({
        $or: [{ name: act.name }, { shortName: act.shortName }],
      });

      if (existing) {
        if (overwriteDuplicates) {
          existing.shortName = act.shortName || existing.shortName;
          existing.actNumber = act.actNumber || existing.actNumber;
          existing.year = act.year || existing.year;
          existing.type = act.type || existing.type;
          existing.description = act.description || existing.description;
          existing.sourceUrl = act.sourceUrl || existing.sourceUrl;
          existing.lastVerifiedDate = new Date();
          if (Array.isArray(act.sections) && act.sections.length > 0) {
            existing.sections = act.sections;
          }
          await existing.save();
          updatedCount++;
        }
      } else {
        await Act.create({
          ...act,
          lastVerifiedDate: new Date(),
          published: true,
        });
        createdCount++;
      }
    }

    if (createdCount > 0 || updatedCount > 0) {
      await notifyAllUsers({
        title: "Bare acts updated",
        body: `Imported ${createdCount} new acts and updated ${updatedCount} acts.`,
        data: { type: "acts_import", createdCount, updatedCount },
      });
    }

    res.json({
      ok: true,
      message: `Successfully imported ${createdCount} new acts and updated ${updatedCount} existing acts.`,
      createdCount,
      updatedCount,
    });
  }),
);

/* ---------------- Admin CRUD (Acts and Sections) ---------------- */
router.post(
  "/",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const item = await Act.create(req.body);
    await AppNotification.create({
      userId: null,
      title: "New Bare Act Added",
      body: item.name,
      type: "act",
      refType: "act",
      refId: item._id.toString(),
    });
    await notifyAllUsers({
      title: "New Bare Act Added",
      body: item.name,
      data: { type: "act", refType: "act", refId: item._id.toString(), actId: item._id.toString() },
    });
    res.status(201).json({ item });
  }),
);

router.put(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const item = await Act.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!item) return res.status(404).json({ error: "Act not found" });
    await notifyAllUsers({
      title: "Bare act updated",
      body: item.name,
      data: { type: "act_update", actId: item._id.toString() },
    });
    res.json({ item });
  }),
);

router.delete(
  "/:id",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    await Act.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  }),
);

router.post(
  "/:id/sections",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const act = await Act.findById(req.params.id);
    if (!act) return res.status(404).json({ error: "Act not found" });
    act.sections.push({ ...req.body, lastVerifiedDate: new Date() });
    await act.save();
    const sectionNumber = req.body?.number || "";
    await AppNotification.create({
      userId: null,
      title: "New Bare Act Section Added",
      body: `${act.shortName || act.name} - Section ${sectionNumber}`,
      type: "act",
      refType: "act",
      refId: act._id.toString(),
    });
    await notifyAllUsers({
      title: "New Bare Act Section Added",
      body: `${act.shortName || act.name} - Section ${sectionNumber}`,
      data: { type: "act", refType: "act", refId: act._id.toString(), actId: act._id.toString() },
    });
    res.status(201).json({ item: act });
  }),
);

router.delete(
  "/:id/sections/:sectionId",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const act = await Act.findById(req.params.id);
    if (!act) return res.status(404).json({ error: "Act not found" });
    act.sections = act.sections.filter((s) => s._id.toString() !== req.params.sectionId);
    await act.save();
    res.json({ item: act });
  }),
);

export default router;
