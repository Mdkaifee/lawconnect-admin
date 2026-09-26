

import { sanitizeHtmlText } from "../utils/security.js";

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
  // Cap cache size at 500 items to bound memory usage
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
   * Sync landmark judgments from Indian Kanoon (or curated repository) directly into MongoDB
   */
  static async syncLandmarkCasesToDb(CaseModel) {
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

    const TOP_TOPICS = [
      { query: "Kesavananda Bharati basic structure", court: "Supreme Court" },
      { query: "Maneka Gandhi Article 21 personal liberty", court: "Supreme Court" },
      { query: "Navtej Singh Johar section 377", court: "Supreme Court" },
      { query: "Justice K S Puttaswamy right to privacy", court: "Supreme Court" },
      { query: "Vishaka state of Rajasthan sexual harassment", court: "Supreme Court" },
      { query: "Shreya Singhal Section 66A IT Act", court: "Supreme Court" },
      { query: "Naz Foundation section 377 Delhi High Court", court: "High Court" },
      { query: "Bayer Corp Union of India Delhi High Court", court: "High Court" },
      { query: "State of Maharashtra KM Nanavati Bombay High Court", court: "High Court" },
      { query: "Tata Press MTNL commercial speech Bombay High Court", court: "High Court" },
      { query: "landmark constitutional fundamental rights", court: "Supreme Court" },
      { query: "landmark criminal appeal high court", court: "High Court" },
    ];

    try {
      if (IndianKanoonService.isConfigured()) {
        for (const topic of TOP_TOPICS) {
          try {
            const results = await IndianKanoonService.search({
              query: topic.query,
              court: topic.court,
              page: 1,
            });

            if (results && Array.isArray(results.items)) {
              for (const item of results.items.slice(0, 4)) {
                const cleanTitle = (item.title || "").trim();
                if (!cleanTitle) continue;

                const exists = await CaseModel.findOne({
                  $or: [
                    { providerId: item.providerId },
                    { title: { $regex: new RegExp(`^${cleanTitle.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i") } },
                  ],
                });

                if (!exists) {
                  const dateVal = item.dateOfJudgment ? new Date(item.dateOfJudgment) : new Date();
                  const yearVal = !isNaN(dateVal.getTime()) ? dateVal.getFullYear() : 2024;

                  await CaseModel.create({
                    title: cleanTitle,
                    citation: item.citation || `${item.courtType} (${yearVal})`,
                    court: item.court || (item.courtType === "High Court" ? "Delhi High Court" : "Supreme Court of India"),
                    courtType: item.courtType || (topic.court === "High Court" ? "High Court" : "Supreme Court"),
                    summary: item.summary || item.snippet || `Landmark judgment from ${item.court || item.courtType}`,
                    simpleExplanation: `Judicial decision rendered by ${item.court || item.courtType}. Citation: ${item.citation || 'N/A'}.`,
                    dateOfJudgment: !isNaN(dateVal.getTime()) ? dateVal : new Date(),
                    year: yearVal,
                    judgmentPdfUrl: item.sourceUrl || `https://indiankanoon.org/doc/${item.providerId}/`,
                    providerId: item.providerId,
                    tags: ["Indian Kanoon", item.courtType || "Supreme Court", "Landmark"],
                    published: true,
                    isFeatured: true,
                  });
                  syncedCount++;
                }
              }
            }
          } catch (topicErr) {
            console.warn(`Sync topic warning (${topic.query}):`, sanitizeLogOutput(topicErr.message));
          }
        }
      }

      // Preloaded landmark fallback judgments to guarantee rich DB content
      const PRELOADED = [
        {
          title: "Kesavananda Bharati v. State of Kerala",
          citation: "(1973) 4 SCC 225",
          court: "Supreme Court of India",
          courtType: "Supreme Court",
          year: 1973,
          dateOfJudgment: new Date("1973-04-24"),
          summary: "Established the Basic Structure Doctrine, restricting Parliament from altering fundamental constitutional features.",
          simpleExplanation: "Parliament can amend the Constitution under Article 368, but cannot destroy or emasculate its basic structure.",
          judgmentPdfUrl: "https://indiankanoon.org/doc/257876/",
          providerId: "257876",
        },
        {
          title: "Justice K.S. Puttaswamy (Retd.) v. Union of India",
          citation: "(2017) 10 SCC 1",
          court: "Supreme Court of India",
          courtType: "Supreme Court",
          year: 2017,
          dateOfJudgment: new Date("2017-08-24"),
          summary: "9-judge bench unanimously affirmed Right to Privacy as a Fundamental Right under Article 21.",
          simpleExplanation: "Privacy is intrinsic to freedom, personal dignity, and liberty guaranteed by Part III of the Constitution.",
          judgmentPdfUrl: "https://indiankanoon.org/doc/127517806/",
          providerId: "127517806",
        },
        {
          title: "Naz Foundation v. Govt. of NCT of Delhi",
          citation: "160 DLT 277",
          court: "Delhi High Court",
          courtType: "High Court",
          year: 2009,
          dateOfJudgment: new Date("2009-07-02"),
          summary: "Landmark Delhi High Court ruling holding Section 377 IPC violative of Articles 14, 15 and 21 for consenting adults.",
          simpleExplanation: "Consensual sexual acts of adults in private do not constitute a criminal offense under constitutional morality.",
          judgmentPdfUrl: "https://indiankanoon.org/doc/100472805/",
          providerId: "100472805",
        },
        {
          title: "Bayer Corporation v. Union of India",
          citation: "2019 SCC OnLine Del 8209",
          court: "Delhi High Court",
          courtType: "High Court",
          year: 2019,
          dateOfJudgment: new Date("2019-04-22"),
          summary: "Interpretation of Section 107A of the Patents Act regarding bolar exemptions and generic pharmaceutical exports.",
          simpleExplanation: "Explains non-infringing developmental and research use of patented inventions for regulatory approvals.",
          judgmentPdfUrl: "https://indiankanoon.org/doc/184651322/",
          providerId: "184651322",
        },
        {
          title: "State of Maharashtra v. K.M. Nanavati",
          citation: "1962 AIR 605 / 1962 SCR Supl. (1) 567",
          court: "Bombay High Court",
          courtType: "High Court",
          year: 1961,
          dateOfJudgment: new Date("1961-11-24"),
          summary: "Historic criminal jurisprudence defining grave and sudden provocation vs premeditated murder.",
          simpleExplanation: "Clarified the threshold between Exception 1 to Section 300 IPC and premeditated culpable homicide.",
          judgmentPdfUrl: "https://indiankanoon.org/doc/1572441/",
          providerId: "1572441",
        },
        {
          title: "Tata Press Ltd. v. Mahanagar Telephone Nigam Ltd.",
          citation: "1995 AIR 2438 / 1995 SCC (5) 139",
          court: "Bombay High Court",
          courtType: "High Court",
          year: 1995,
          dateOfJudgment: new Date("1995-08-03"),
          summary: "Commercial speech is protected as part of freedom of speech and expression under Article 19(1)(a).",
          simpleExplanation: "Advertising and commercial speech are fundamental constitutional freedoms subject only to Article 19(2) restrictions.",
          judgmentPdfUrl: "https://indiankanoon.org/doc/1454178/",
          providerId: "1454178",
        },
      ];

      for (const p of PRELOADED) {
        const exists = await CaseModel.findOne({
          $or: [
            { providerId: p.providerId },
            { title: { $regex: new RegExp(`^${p.title.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`, "i") } },
          ],
        });
        if (!exists) {
          await CaseModel.create({
            ...p,
            tags: ["Landmark", p.courtType, "Curated"],
            published: true,
            isFeatured: true,
          });
          syncedCount++;
        }
      }

      const totalInDb = await CaseModel.countDocuments();
      syncMetadata.lastSyncTime = new Date().toISOString();
      syncMetadata.lastSyncCount = syncedCount;
      syncMetadata.lastSyncError = null;

      return {
        success: true,
        count: syncedCount,
        totalInDb,
        lastSyncTime: syncMetadata.lastSyncTime,
        message: `Sync completed! Added ${syncedCount} new landmark judgments into database. Total in DB: ${totalInDb}.`,
      };
    } catch (err) {
      syncMetadata.lastSyncError = err.message;
      throw err;
    } finally {
      syncMetadata.isSyncing = false;
    }
  }
}

