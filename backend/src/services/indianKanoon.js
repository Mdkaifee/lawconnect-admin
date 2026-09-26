

import { sanitizeHtmlText, sanitizeLogOutput } from "../utils/security.js";
import { LANDMARK_CASES } from "../config/landmarkCasesData.js";

const IK_BASE_URL = "https://api.indiankanoon.org";
const REQUEST_TIMEOUT_MS = 8000;
const COURT_DOCTYPES = {
  "Supreme Court": "supremecourt",
  "High Court": "highcourts",
};

// Simple in-memory cache to avoid redundant billable provider requests
const cache = new Map();
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

function getCached(key) {
  const item = cache.get(key);
  if (!item) return null;
  if (Date.now() > item.expiresAt) {
    cache.delete(key);
    return null;
  }
  return item.data;
}

function setCache(key, data, ttl = CACHE_TTL_MS) {
  if (cache.size > 500) {
    const firstKey = cache.keys().next().value;
    if (firstKey) cache.delete(firstKey);
  }
  cache.set(key, { data, expiresAt: Date.now() + ttl });
}

const syncMetadata = {
  lastSyncTime: null,
  lastSyncCount: 0,
  lastSyncError: null,
  isSyncing: false,
};

export class IndianKanoonService {
  static getApiKey() {
    return (process.env.INDIAN_KANOON_API_KEY || "").trim();
  }

  static isConfigured() {
    return Boolean(IndianKanoonService.getApiKey());
  }

  static async _request(path, params = {}) {
    const apiKey = IndianKanoonService.getApiKey();
    if (!apiKey) {
      throw new Error("INDIAN_KANOON_API_KEY is not configured on the server.");
    }

    const url = new URL(`${IK_BASE_URL}${path}`);
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== "") {
        url.searchParams.append(k, String(v));
      }
    });

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

    try {
      const response = await fetch(url.toString(), {
        method: "POST",
        headers: {
          Authorization: `Token ${apiKey}`,
          Accept: "application/json",
          "User-Agent": "RishikeshLawHub/1.0",
        },
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        if (response.status === 401 || response.status === 403) {
          throw new Error("Indian Kanoon authentication failed. Check server INDIAN_KANOON_API_KEY.");
        }
        if (response.status === 402 || response.status === 429) {
          throw new Error("Indian Kanoon API quota or rate limit exceeded.");
        }
        if (response.status === 404) {
          throw new Error("Document not found on Indian Kanoon.");
        }
        throw new Error(`Indian Kanoon provider error (${response.status})`);
      }

      const contentType = response.headers.get("content-type") || "";
      if (contentType.includes("application/json")) {
        return await response.json();
      } else if (contentType.includes("application/pdf")) {
        const buffer = await response.arrayBuffer();
        return { isBinary: true, contentType: "application/pdf", buffer };
      } else {
        const text = await response.text();
        try {
          return JSON.parse(text);
        } catch {
          return { text };
        }
      }
    } catch (err) {
      clearTimeout(timeoutId);
      if (err.name === "AbortError") {
        throw new Error("Indian Kanoon request timed out after 8 seconds.");
      }
      throw err;
    }
  }

  /**
   * Search Judgments on Indian Kanoon
   * @param {Object} opts
   * @param {string} opts.query - Search keywords, title or citation
   * @param {number} [opts.page=1] - 1-based page index from client (translated to 0-based for API)
   * @param {string} [opts.court] - Filter court (e.g. 'Supreme Court', 'High Court')
   * @param {string} [opts.fromYear]
   * @param {string} [opts.toYear]
   */
  static async search({ query, page = 1, court, fromYear, toYear }) {
    if (!query || !query.trim()) {
      return { items: [], total: 0, page: Number(page), provider: "indian_kanoon" };
    }

    const pagenum = Math.max(0, Number(page) - 1); // Translate 1-indexed to 0-indexed
    let formInput = query.trim();

    // Map court filters to Indian Kanoon doctypes or search modifiers
    if (court && COURT_DOCTYPES[court]) {
      formInput += ` doctypes:${COURT_DOCTYPES[court]}`;
    } else {
      formInput += " doctypes:judgments";
    }

    if (fromYear && toYear) {
      formInput += ` fromdate:1-1-${fromYear} todate:31-12-${toYear}`;
    } else if (fromYear) {
      formInput += ` fromdate:1-1-${fromYear}`;
    }

    const cacheKey = `search:${formInput}:${pagenum}`;
    const cached = getCached(cacheKey);
    if (cached) return cached;

    const data = await IndianKanoonService._request("/search/", {
      formInput,
      pagenum,
    });

    const docs = Array.isArray(data?.docs) ? data.docs : [];
    const total = Number(data?.found) || docs.length;

    const normalized = docs.map((doc) => {
      const tid = String(doc.tid || doc.id || "");
      const title = doc.title ? doc.title.replace(/<\/?[^>]+(>|$)/g, "") : "Untitled Judgment";
      const snippet = doc.headline ? sanitizeHtmlText(doc.headline) : "";
      const dateStr = doc.publishdate || "";

      let courtType = "Supreme Court";
      const docsource = (doc.docsource || "").toLowerCase();
      if (docsource.includes("high court") || docsource.includes("hc")) {
        courtType = "High Court";
      } else if (!docsource.includes("supreme court")) {
        courtType = "Other";
      }

      return {
        id: `ik_${tid}`,
        providerId: tid,
        provider: "indian_kanoon",
        title,
        court: doc.docsource || courtType,
        courtType,
        dateOfJudgment: dateStr,
        citation: doc.citation || "",
        snippet,
        summary: snippet.replace(/<\/?[^>]+(>|$)/g, "").trim(),
        numCites: Number(doc.numcites) || 0,
        numCitedBy: Number(doc.numcitedby) || 0,
        hasCourtCopy: Boolean(doc.courtcopy),
        sourceUrl: `https://indiankanoon.org/doc/${tid}/`,
        isCurated: false,
      };
    });

    const result = {
      items: normalized,
      total,
      page: Number(page),
      provider: "indian_kanoon",
    };

    setCache(cacheKey, result, 15 * 60 * 1000); // 15 mins TTL for search
    return result;
  }

  /**
   * Fetch full judgment text and metadata
   * @param {string|number} docId
   */
  static async getDocument(docId) {
    const cleanId = String(docId).replace(/^ik_/, "");
    const cacheKey = `doc:${cleanId}`;
    const cached = getCached(cacheKey);
    if (cached) return cached;

    // Fetch document body and metadata in parallel
    const [docData, metaData] = await Promise.allSettled([
      IndianKanoonService._request(`/doc/${cleanId}/`),
      IndianKanoonService._request(`/docmeta/${cleanId}/`),
    ]);

    const doc = docData.status === "fulfilled" ? docData.value : null;
    const meta = metaData.status === "fulfilled" ? metaData.value : null;

    if (!doc && !meta) {
      throw new Error("Unable to retrieve judgment from Indian Kanoon.");
    }

    const rawHtml = doc?.doc || doc?.text || "";
    const sanitizedHtml = sanitizeHtmlText(rawHtml);
    const title = (doc?.title || meta?.title || "Judgment").replace(/<\/?[^>]+(>|$)/g, "");

    const citesList = Array.isArray(meta?.cites)
      ? meta.cites.map((c) => ({
          providerId: String(c.tid || c.id || ""),
          title: (c.title || "Referenced Case").replace(/<\/?[^>]+(>|$)/g, ""),
          relationship: "cites",
          sourceUrl: c.tid ? `https://indiankanoon.org/doc/${c.tid}/` : "",
        }))
      : [];

    const citedByList = Array.isArray(meta?.citedby)
      ? meta.citedby.map((c) => ({
          providerId: String(c.tid || c.id || ""),
          title: (c.title || "Citing Case").replace(/<\/?[^>]+(>|$)/g, ""),
          relationship: "citedby",
          sourceUrl: c.tid ? `https://indiankanoon.org/doc/${c.tid}/` : "",
        }))
      : [];

    const result = {
      id: `ik_${cleanId}`,
      providerId: cleanId,
      provider: "indian_kanoon",
      title,
      court: doc?.docsource || meta?.docsource || "Supreme Court of India",
      courtType: (doc?.docsource || meta?.docsource || "").toLowerCase().includes("high court")
        ? "High Court"
        : "Supreme Court",
      dateOfJudgment: doc?.publishdate || meta?.publishdate || null,
      fullText: sanitizedHtml,
      summary: (doc?.headline || "").replace(/<\/?[^>]+(>|$)/g, "").trim(),
      cites: citesList,
      citedBy: citedByList,
      hasCourtCopy: Boolean(doc?.courtcopy || meta?.courtcopy),
      origDocUrl: doc?.courtcopy ? `/api/cases/doc/${cleanId}/orig` : null,
      sourceUrl: `https://indiankanoon.org/doc/${cleanId}/`,
      isCurated: false,
    };

    setCache(cacheKey, result, CACHE_TTL_MS);
    return result;
  }

  /**
   * Fetch relevant fragments for a document and query.
   */
  static async getDocumentFragments(docId, query) {
    const cleanId = String(docId).replace(/^ik_/, "");
    const formInput = String(query || "").trim();
    if (!formInput) {
      return { providerId: cleanId, title: "", fragments: [], sourceUrl: `https://indiankanoon.org/doc/${cleanId}/` };
    }

    const cacheKey = `fragment:${cleanId}:${formInput}`;
    const cached = getCached(cacheKey);
    if (cached) return cached;

    const data = await IndianKanoonService._request(`/docfragment/${cleanId}/`, { formInput });
    const result = {
      providerId: cleanId,
      title: (data?.title || "").replace(/<\/?[^>]+(>|$)/g, ""),
      formInput: data?.formInput || formInput,
      fragments: data?.headline ? [sanitizeHtmlText(data.headline)] : [],
      sourceUrl: `https://indiankanoon.org/doc/${cleanId}/`,
    };

    setCache(cacheKey, result, 15 * 60 * 1000);
    return result;
  }

  /**
   * Fetch original court copy if available
   */
  static async getOriginalDocument(docId) {
    const cleanId = String(docId).replace(/^ik_/, "");
    return await IndianKanoonService._request(`/origdoc/${cleanId}/`);
  }

  /**
   * Safe integration status check for admin panel (never reveals key)
   */
  static async checkStatus() {
    const configured = IndianKanoonService.isConfigured();
    if (!configured) {
      return {
        configured: false,
        status: "unconfigured",
        message: "INDIAN_KANOON_API_KEY is not set in backend environment variables.",
      };
    }

    return {
      configured: true,
      status: "configured",
      message: "INDIAN_KANOON_API_KEY is configured. Live search and document fetch active.",
    };
  }

  static getSyncStatus(totalCasesInDb = 0) {
    return {
      configured: IndianKanoonService.isConfigured(),
      isSyncing: syncMetadata.isSyncing,
      lastSyncTime: syncMetadata.lastSyncTime,
      lastSyncCount: syncMetadata.lastSyncCount,
      lastSyncError: syncMetadata.lastSyncError,
      totalInDb: totalCasesInDb,
      schedule: "Every 12 hours (6:00 AM & 6:00 PM)",
    };
  }

  /**
   * Deep Multi-Year & Multi-Court Sync from Indian Kanoon + Curated Archive into MongoDB
   * Ingests dozens of cases across 2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 and historical eras.
   */
  static async syncLandmarkCasesToDb(CaseModel, options = {}) {
    if (syncMetadata.isSyncing) {
      return {
        success: false,
        message: "Sync is already in progress.",
        isSyncing: true,
      };
    }

    syncMetadata.isSyncing = true;
    syncMetadata.lastSyncError = null;

    let syncedCount = 0;

    // 1. First ensure all foundational landmark cases across all years (1950 - 2026) are in MongoDB
    for (const c of LANDMARK_CASES) {
      try {
        const cleanTitle = (c.title || "").trim();
        const existing = await CaseModel.findOne({
          $or: [
            { providerId: c.providerId },
            { title: { $regex: new RegExp(`^${cleanTitle.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i") } },
          ],
        });

        if (!existing) {
          await CaseModel.create({
            ...c,
            published: true,
          });
          syncedCount++;
        }
      } catch (err) {
        console.warn("Curated case upsert warning:", err.message);
      }
    }

    // 2. If Indian Kanoon API is configured, perform deep multi-year and multi-topic harvesting
    if (IndianKanoonService.isConfigured()) {
      const SYNC_YEARS = options.year ? [Number(options.year)] : [2026, 2025, 2024, 2023, 2022, 2021, 2020, 2019, 2018];
      
      const TOPICS = [
        { q: "Supreme Court landmark judgment constitution fundamental rights", court: "Supreme Court" },
        { q: "Supreme Court criminal appeal bail Section 482", court: "Supreme Court" },
        { q: "High Court landmark judgment writ petition", court: "High Court" },
        { q: "arbitration contract commercial dispute specific relief", court: undefined },
      ];

      for (const yr of SYNC_YEARS) {
        for (const topic of TOPICS) {
          try {
            const results = await IndianKanoonService.search({
              query: topic.q,
              court: topic.court,
              fromYear: String(yr),
              toYear: String(yr),
              page: 1,
            });

            if (results && Array.isArray(results.items)) {
              for (const item of results.items.slice(0, 10)) {
                const cleanTitle = (item.title || "").trim();
                if (!cleanTitle) continue;

                const exists = await CaseModel.findOne({
                  $or: [
                    { providerId: item.providerId },
                    { title: { $regex: new RegExp(`^${cleanTitle.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i") } },
                  ],
                });

                if (!exists) {
                  const dateVal = item.dateOfJudgment ? new Date(item.dateOfJudgment) : new Date(`${yr}-01-01`);
                  const yearVal = !isNaN(dateVal.getTime()) ? dateVal.getFullYear() : yr;

                  await CaseModel.create({
                    title: cleanTitle,
                    citation: item.citation || `${item.courtType} (${yearVal})`,
                    court: item.court || (item.courtType === "High Court" ? "Delhi High Court" : "Supreme Court of India"),
                    courtType: item.courtType || (topic.court === "High Court" ? "High Court" : "Supreme Court"),
                    summary: item.summary || item.snippet || `Judicial ruling from ${item.court || item.courtType}`,
                    simpleExplanation: `Judgment from ${item.court || item.courtType}. Citation: ${item.citation || 'N/A'}.`,
                    dateOfJudgment: !isNaN(dateVal.getTime()) ? dateVal : new Date(`${yr}-01-01`),
                    year: yearVal,
                    judgmentPdfUrl: item.sourceUrl || `https://indiankanoon.org/doc/${item.providerId}/`,
                    providerId: item.providerId,
                    tags: ["Indian Kanoon", item.courtType || "Supreme Court", String(yearVal)],
                    published: true,
                    isFeatured: false,
                  });
                  syncedCount++;
                }
              }
            }
          } catch (topicErr) {
            console.warn(`Deep sync warning for ${yr} (${topic.q}):`, sanitizeLogOutput(topicErr.message));
          }
        }
      }
    }

    const totalInDb = await CaseModel.countDocuments();
    syncMetadata.lastSyncTime = new Date().toISOString();
    syncMetadata.lastSyncCount = syncedCount;
    syncMetadata.lastSyncError = null;
    syncMetadata.isSyncing = false;

    return {
      success: true,
      count: syncedCount,
      totalInDb,
      lastSyncTime: syncMetadata.lastSyncTime,
      message: `Deep sync complete! Ingested ${syncedCount} judgments across all years. Total database collection: ${totalInDb} judgments.`,
    };
  }
}
