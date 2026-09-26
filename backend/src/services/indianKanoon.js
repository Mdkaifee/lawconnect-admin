import { sanitizeHtmlText } from "../utils/security.js";
import { Case, LegalUpdate } from "../models/index.js";

const IK_BASE_URL = "https://api.indiankanoon.org";
const REQUEST_TIMEOUT_MS = 8000;
const COURT_DOCTYPES = {
  "Supreme Court": "supremecourt",
  "High Court": "highcourts",
};

// In-memory LRU cache to avoid redundant provider requests
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

// Built-in Comprehensive Landmark Judgments Library for India
const CORE_LANDMARK_CASES = [
  {
    title: "Kesavananda Bharati v. State of Kerala",
    citation: "(1973) 4 SCC 225",
    year: 1973,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "Chief Justice S.M. Sikri & 12 other Judges (13-Judge Bench)",
    petitioners: "Kesavananda Bharati Sripadagalvaru",
    respondents: "State of Kerala and Another",
    dateOfJudgment: new Date("1973-04-24"),
    tags: ["Constitutional Law", "Basic Structure", "Article 368", "Judicial Review", "Landmark"],
    categories: ["constitution"],
    summary:
      "Landmark 13-judge bench ruling establishing the 'Basic Structure Doctrine' of the Indian Constitution, holding that Parliament cannot alter or destroy the basic framework of the Constitution under Article 368.",
    simpleExplanation:
      "Parliament has the power to amend the Constitution, but it cannot destroy its core foundation — such as democracy, rule of law, federalism, secularism, and judicial independence.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/257876/",
    providerId: "257876",
    isFeatured: true,
    published: true,
  },
  {
    title: "Maneka Gandhi v. Union of India",
    citation: "(1978) 1 SCC 248",
    year: 1978,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "Justice M.H. Beg (CJI), P.N. Bhagwati, V.R. Krishna Iyer & Others (7-Judge Bench)",
    petitioners: "Maneka Gandhi",
    respondents: "Union of India",
    dateOfJudgment: new Date("1978-01-25"),
    tags: ["Article 21", "Right to Travel Abroad", "Due Process", "Personal Liberty", "Natural Justice"],
    categories: ["constitution"],
    summary:
      "Expanded the scope of Article 21 to mandate that any procedure depriving a person of life or liberty must be just, fair, and reasonable, incorporating the doctrine of substantive due process.",
    simpleExplanation:
      "A law taking away personal freedom must not merely exist on paper; it must be just, reasonable, and non-arbitrary. The right to travel abroad is part of personal liberty.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/1766147/",
    providerId: "1766147",
    isFeatured: true,
    published: true,
  },
  {
    title: "Justice K.S. Puttaswamy (Retd.) v. Union of India",
    citation: "(2017) 10 SCC 1",
    year: 2017,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "9-Judge Constitutional Bench (CJI J.S. Khehar, J. Chelameswar, S.A. Bobde, D.Y. Chandrachud, et al.)",
    petitioners: "Justice K.S. Puttaswamy (Retd.)",
    respondents: "Union of India",
    dateOfJudgment: new Date("2017-08-24"),
    tags: ["Privacy", "Article 21", "Fundamental Rights", "Aadhaar", "Data Protection"],
    categories: ["constitution"],
    summary:
      "Unanimously declared that the Right to Privacy is a protected fundamental right under Article 21 (Life and Personal Liberty) and Part III of the Indian Constitution.",
    simpleExplanation:
      "Every citizen has a fundamental right to privacy regarding their personal data, bodily integrity, personal choices, and informational autonomy.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/91938676/",
    providerId: "91938676",
    isFeatured: true,
    published: true,
  },
  {
    title: "Navtej Singh Johar v. Union of India",
    citation: "(2018) 10 SCC 1",
    year: 2018,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "5-Judge Constitution Bench (CJI Dipak Misra, R.F. Nariman, A.M. Khanwilkar, D.Y. Chandrachud, Indu Malhotra)",
    petitioners: "Navtej Singh Johar & Others",
    respondents: "Union of India",
    dateOfJudgment: new Date("2018-09-06"),
    tags: ["Section 377", "LGBTQ+ Rights", "Article 14", "Article 19", "Article 21"],
    categories: ["constitution", "criminal-law"],
    summary:
      "Decriminalized consensual same-sex adult sexual relationships by reading down Section 377 of the Indian Penal Code, upholding equality, human dignity, and non-discrimination.",
    simpleExplanation:
      "Consensual intimacy between adults of the same sex is protected under the Constitution. Section 377 cannot criminalize private consensual relations.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/119980704/",
    providerId: "119980704",
    isFeatured: true,
    published: true,
  },
  {
    title: "Shayara Bano v. Union of India",
    citation: "(2017) 9 SCC 1",
    year: 2017,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "5-Judge Constitutional Bench",
    petitioners: "Shayara Bano",
    respondents: "Union of India & Others",
    dateOfJudgment: new Date("2017-08-22"),
    tags: ["Triple Talaq", "Talaq-e-Biddat", "Gender Equality", "Article 14", "Article 25", "Family Law"],
    categories: ["family-law", "constitution"],
    summary:
      "Declared the practice of instantaneous Triple Talaq (Talaq-e-Biddat) unconstitutional and void for being arbitrary and violative of Article 14 (Equality before Law).",
    simpleExplanation:
      "Instant Triple Talaq is arbitrary, unequal towards women, and not an essential religious practice, hence declared illegal and void.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/115701246/",
    providerId: "115701246",
    isFeatured: true,
    published: true,
  },
  {
    title: "Vishaka v. State of Rajasthan",
    citation: "(1997) 6 SCC 241",
    year: 1997,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "Chief Justice J.S. Verma, Sujata V. Manohar, B.N. Kirpal",
    petitioners: "Vishaka and Others",
    respondents: "State of Rajasthan and Others",
    dateOfJudgment: new Date("1997-08-13"),
    tags: ["POSH", "Sexual Harassment", "Gender Justice", "Article 14", "Article 19", "Article 21"],
    categories: ["constitution", "labour-law"],
    summary:
      "Laid down comprehensive binding guidelines (Vishaka Guidelines) to prevent sexual harassment of women at workplaces until enactment of dedicated statutory legislation (POSH Act).",
    simpleExplanation:
      "Every employer must provide safe working conditions for women and establish an Internal Complaints Committee to address harassment.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/1031794/",
    providerId: "1031794",
    isFeatured: true,
    published: true,
  },
  {
    title: "M.C. Mehta v. Union of India (Oleum Gas Leak Case)",
    citation: "(1987) 1 SCC 395",
    year: 1987,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "Chief Justice P.N. Bhagwati & 4 other Judges",
    petitioners: "M.C. Mehta",
    respondents: "Union of India and Shriram Foods & Fertilizer Industries",
    dateOfJudgment: new Date("1986-12-20"),
    tags: ["Environmental Law", "Absolute Liability", "Article 21", "Article 32", "Pollution"],
    categories: ["environment", "torts"],
    summary:
      "Formulated the principle of 'Absolute Liability' for hazardous or inherently dangerous industrial enterprises, eliminating exceptions available under Strict Liability.",
    simpleExplanation:
      "Enterprises engaged in hazardous industries have an absolute, non-delegable duty to ensure no harm is caused, with no legal exceptions for accidents.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/1486949/",
    providerId: "1486949",
    isFeatured: true,
    published: true,
  },
  {
    title: "D.K. Basu v. State of West Bengal",
    citation: "(1997) 1 SCC 416",
    year: 1997,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "Justice Kuldip Singh, Dr. A.S. Anand",
    petitioners: "D.K. Basu, Ashok K. Johri",
    respondents: "State of West Bengal, State of U.P.",
    dateOfJudgment: new Date("1996-12-18"),
    tags: ["Arrest Guidelines", "Custodial Torture", "Article 21", "Article 22", "CrPC", "Police Reforms"],
    categories: ["criminal-law", "constitution"],
    summary:
      "Formulated 11 mandatory guidelines to prevent custodial violence, torture, and arbitrary arrests by law enforcement agencies across India.",
    simpleExplanation:
      "Police officers must prepare arrest memos, inform relatives of arrested persons, conduct regular medical examinations, and wear identification badges.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/501198/",
    providerId: "501198",
    isFeatured: true,
    published: true,
  },
  {
    title: "S.R. Bommai v. Union of India",
    citation: "(1994) 3 SCC 1",
    year: 1994,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "9-Judge Constitution Bench",
    petitioners: "S.R. Bommai",
    respondents: "Union of India",
    dateOfJudgment: new Date("1994-03-11"),
    tags: ["Article 356", "President's Rule", "Federalism", "Secularism", "Basic Structure"],
    categories: ["constitution"],
    summary:
      "Curtailed the arbitrary imposition of President's Rule under Article 356, establishing that presidential proclamations are subject to judicial review.",
    simpleExplanation:
      "President's Rule cannot be imposed on state governments arbitrarily; floor tests in legislative assemblies are mandatory to prove majority.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/60799/",
    providerId: "60799",
    isFeatured: false,
    published: true,
  },
  {
    title: "Lalita Kumari v. Govt. of Uttar Pradesh",
    citation: "(2014) 2 SCC 1",
    year: 2014,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "5-Judge Constitution Bench",
    petitioners: "Lalita Kumari (Minor)",
    respondents: "Govt. of U.P. and Others",
    dateOfJudgment: new Date("2013-11-12"),
    tags: ["FIR", "Section 154 CrPC", "Mandatory FIR", "Cognizable Offence", "Criminal Procedure"],
    categories: ["criminal-law"],
    summary:
      "Held that registration of an FIR is mandatory under Section 154 of CrPC if information discloses commission of a cognizable offence.",
    simpleExplanation:
      "Police cannot conduct preliminary inquiry before registering an FIR if information clearly discloses a serious (cognizable) crime.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/102852623/",
    providerId: "102852623",
    isFeatured: false,
    published: true,
  },
  {
    title: "Arnesh Kumar v. State of Bihar",
    citation: "(2014) 8 SCC 273",
    year: 2014,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "Justice Chandramauli Kr. Prasad, Pinaki Chandra Ghose",
    petitioners: "Arnesh Kumar",
    respondents: "State of Bihar & Another",
    dateOfJudgment: new Date("2014-07-02"),
    tags: ["Section 498A", "Section 41 CrPC", "Arrest Guidelines", "Matrimonial Disputes", "Bail"],
    categories: ["criminal-law", "family-law"],
    summary:
      "Issued strict directions that police officers shall not automatically arrest accused persons in offenses punishable with up to 7 years imprisonment without satisfying Section 41 CrPC parameters.",
    simpleExplanation:
      "Notice under Section 41A must be issued first in offenses carrying less than 7 years imprisonment; arrests cannot be routine or automatic.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/2982624/",
    providerId: "2982624",
    isFeatured: false,
    published: true,
  },
  {
    title: "Mohori Bibee v. Dharmodas Ghose",
    citation: "(1903) ILR 30 Cal 539 (PC)",
    year: 1903,
    court: "Privy Council",
    courtType: "Other",
    bench: "Lord McNaghten & Privy Council Bench",
    petitioners: "Mohori Bibee",
    respondents: "Dharmodas Ghose",
    dateOfJudgment: new Date("1903-03-04"),
    tags: ["Minor's Agreement", "Section 11 Contract Act", "Void ab initio", "Capacity to Contract"],
    categories: ["contract"],
    summary:
      "Landmark ruling establishing that an agreement entered into by a minor is void ab initio (void from the beginning) and completely unenforceable in law.",
    simpleExplanation:
      "Minors cannot enter into valid legal contracts; any loan or mortgage agreement made with a minor cannot be enforced against them.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/679774/",
    providerId: "679774",
    isFeatured: false,
    published: true,
  },
  {
    title: "Donoghue v. Stevenson",
    citation: "[1932] UKHL 100",
    year: 1932,
    court: "House of Lords (Persuasive Precedent)",
    courtType: "Other",
    bench: "Lord Atkin, Lord Thankerton, Lord Macmillan",
    petitioners: "May Donoghue",
    respondents: "David Stevenson",
    dateOfJudgment: new Date("1932-05-26"),
    tags: ["Law of Torts", "Negligence", "Neighbor Principle", "Duty of Care", "Consumer Protection"],
    categories: ["torts"],
    summary:
      "Foundational judgment in the Law of Torts establishing the modern concept of negligence and the famous 'Neighbor Principle'.",
    simpleExplanation:
      "You must take reasonable care to avoid acts or omissions which you can reasonably foresee would be likely to injure your neighbor.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/1844079/",
    providerId: "1844079",
    isFeatured: false,
    published: true,
  },
  {
    title: "Joseph Shine v. Union of India",
    citation: "(2019) 3 SCC 39",
    year: 2018,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "5-Judge Constitution Bench",
    petitioners: "Joseph Shine",
    respondents: "Union of India",
    dateOfJudgment: new Date("2018-09-27"),
    tags: ["Adultery", "Section 497 IPC", "Gender Equality", "Article 14", "Article 21"],
    categories: ["criminal-law", "family-law", "constitution"],
    summary:
      "Struck down Section 497 of the Indian Penal Code (criminalizing adultery) as unconstitutional, paternalistic, and violative of Articles 14 and 21.",
    simpleExplanation:
      "Adultery remains a ground for civil divorce in matrimonial law, but is no longer treated as a criminal offense.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/42186525/",
    providerId: "42186525",
    isFeatured: false,
    published: true,
  },
  {
    title: "Indra Sawhney v. Union of India (Mandal Case)",
    citation: "1992 Supp (3) SCC 217",
    year: 1992,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "9-Judge Constitution Bench",
    petitioners: "Indra Sawhney",
    respondents: "Union of India and Others",
    dateOfJudgment: new Date("1992-11-16"),
    tags: ["Reservation", "OBC Quota", "Article 16(4)", "Creamy Layer", "50 Percent Cap"],
    categories: ["constitution"],
    summary:
      "Upheld 27% reservation for Other Backward Classes (OBCs) while instituting the 'creamy layer' exclusion and capping total reservations at 50%.",
    simpleExplanation:
      "Backward class reservations are constitutional but must exclude affluent individuals (creamy layer) and remain within a 50% limit.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/1363234/",
    providerId: "1363234",
    isFeatured: false,
    published: true,
  },
  {
    title: "Shah Bano Begum v. Mohd. Ahmed Khan",
    citation: "(1985) 2 SCC 556",
    year: 1985,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "Chief Justice Y.V. Chandrachud, D.A. Desai, O. Chinnappa Reddy, E.S. Venkataramiah, R. Misra",
    petitioners: "Mohd. Ahmed Khan",
    respondents: "Shah Bano Begum and Others",
    dateOfJudgment: new Date("1985-04-23"),
    tags: ["Section 125 CrPC", "Maintenance", "Muslim Women Rights", "Uniform Civil Code", "Article 44"],
    categories: ["family-law", "criminal-law"],
    summary:
      "Held that Section 125 of CrPC applies to all citizens irrespective of religion, granting divorced Muslim women the right to maintenance from their ex-husbands.",
    simpleExplanation:
      "The obligation to prevent destitution under CrPC Section 125 overrides personal law limitations regarding post-divorce maintenance.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/823221/",
    providerId: "823221",
    isFeatured: false,
    published: true,
  },
  {
    title: "Common Cause v. Union of India",
    citation: "(2018) 5 SCC 1",
    year: 2018,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "5-Judge Constitution Bench",
    petitioners: "Common Cause (A Regd. Society)",
    respondents: "Union of India & Another",
    dateOfJudgment: new Date("2018-03-09"),
    tags: ["Passive Euthanasia", "Living Will", "Article 21", "Right to Die with Dignity", "Medical Ethics"],
    categories: ["constitution"],
    summary:
      "Recognized that the right to life with dignity under Article 21 includes the right to die with dignity, legalizing passive euthanasia and Advance Medical Directives (Living Wills).",
    simpleExplanation:
      "Terminally ill patients have the right to refuse life-support systems through a verified living will.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/184449972/",
    providerId: "184449972",
    isFeatured: false,
    published: true,
  },
  {
    title: "National Legal Services Authority (NALSA) v. Union of India",
    citation: "(2014) 5 SCC 438",
    year: 2014,
    court: "Supreme Court of India",
    courtType: "Supreme Court",
    bench: "Justice K.S. Radhakrishnan, A.K. Sikri",
    petitioners: "National Legal Services Authority",
    respondents: "Union of India and Others",
    dateOfJudgment: new Date("2014-04-15"),
    tags: ["Transgender Rights", "Gender Identity", "Article 14", "Article 19", "Article 21", "Third Gender"],
    categories: ["constitution"],
    summary:
      "Affirmed the fundamental right of transgender persons to self-identify their gender as male, female, or third gender under the Indian Constitution.",
    simpleExplanation:
      "Gender identity is an integral aspect of personal autonomy and self-determination protected under Articles 14, 19, and 21.",
    judgmentPdfUrl: "https://indiankanoon.org/doc/193543132/",
    providerId: "193543132",
    isFeatured: false,
    published: true,
  },
];

const CORE_LEGAL_UPDATES = [
  {
    title: "Supreme Court holds right against climate change effects as fundamental under Articles 14 & 21",
    summary: "In MK Ranjitsinh v. Union of India, SC recognized a distinct fundamental right to be free from the adverse effects of climate change.",
    category: "Judgments",
    source: "Supreme Court of India",
    sourceUrl: "https://main.sci.gov.in",
    court: "Supreme Court",
    badge: "SC Landmark",
    publishedAt: new Date("2024-04-05"),
    published: true,
  },
  {
    title: "Delhi High Court clarifies pre-institution mediation requirements under Commercial Courts Act",
    summary: "Division Bench held Section 12A mediation is mandatory unless urgent interim relief is explicitly pleaded with concrete material.",
    category: "Judgments",
    source: "Delhi High Court",
    sourceUrl: "https://delhihighcourt.nic.in",
    court: "High Court",
    badge: "HC Ruling",
    publishedAt: new Date("2024-05-12"),
    published: true,
  },
  {
    title: "Ministry of Law & Justice notifies Implementation of Bharatiya Nyaya Sanhita across all states",
    summary: "Modernized criminal justice codes officially came into effect, digitizing e-FIR and zero FIR nationwide.",
    category: "Government Notifications",
    source: "Ministry of Law and Justice",
    sourceUrl: "https://egazette.gov.in",
    court: "Other",
    badge: "Statute Notice",
    publishedAt: new Date("2024-07-01"),
    published: true,
  },
  {
    title: "Supreme Court issues directions for speedy trial and bail disposal under Section 436A CrPC / BNSS",
    summary: "Directs undertrial review committees to periodically inspect jails and expedite bail hearings for long-term detainees.",
    category: "Judgments",
    source: "Bar & Bench",
    sourceUrl: "https://www.barandbench.com",
    court: "Supreme Court",
    badge: "SC Directive",
    publishedAt: new Date("2024-08-20"),
    published: true,
  },
];

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
          "User-Agent": "LawHubApp/1.0",
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
   * Search Judgments on Indian Kanoon & auto-save to MongoDB
   */
  static async search({ query, page = 1, court, fromYear, toYear }) {
    if (!query || !query.trim()) {
      return { items: [], total: 0, page: Number(page), provider: "indian_kanoon" };
    }

    const pagenum = Math.max(0, Number(page) - 1);
    let formInput = query.trim();

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

    // Asynchronously upsert returned results into MongoDB so DB permanently grows
    setImmediate(async () => {
      try {
        for (const item of normalized) {
          if (!item.providerId || !item.title) continue;
          await Case.findOneAndUpdate(
            { $or: [{ providerId: item.providerId }, { title: item.title }] },
            {
              $set: {
                title: item.title,
                citation: item.citation,
                court: item.court,
                courtType: item.courtType,
                providerId: item.providerId,
                summary: item.summary || item.snippet,
                judgmentPdfUrl: item.sourceUrl,
                published: true,
              },
            },
            { upsert: true },
          );
        }
      } catch {
        // Non-blocking background sync error
      }
    });

    const result = {
      items: normalized,
      total,
      page: Number(page),
      provider: "indian_kanoon",
    };

    setCache(cacheKey, result, 15 * 60 * 1000);
    return result;
  }

  /**
   * Fetch full judgment text and metadata & auto-save to MongoDB
   */
  static async getDocument(docId) {
    const cleanId = String(docId).replace(/^ik_/, "");
    const cacheKey = `doc:${cleanId}`;
    const cached = getCached(cacheKey);
    if (cached) return cached;

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

    // Auto-update MongoDB with fullText if record exists or upsert it
    setImmediate(async () => {
      try {
        await Case.findOneAndUpdate(
          { $or: [{ providerId: cleanId }, { title }] },
          {
            $set: {
              title,
              court: result.court,
              courtType: result.courtType,
              providerId: cleanId,
              fullText: sanitizedHtml,
              summary: result.summary,
              judgmentPdfUrl: result.sourceUrl,
              published: true,
            },
          },
          { upsert: true },
        );
      } catch {
        // ignore background error
      }
    });

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
   * Complete Bulk Sync from Indian Kanoon + Authoritative Landmark Library into MongoDB
   */
  static async syncToDatabase() {
    let syncedKanoonCount = 0;
    let syncedLocalCount = 0;
    let syncedUpdatesCount = 0;

    // 1. Always upsert Core Landmark Cases & Updates into MongoDB
    for (const c of CORE_LANDMARK_CASES) {
      await Case.findOneAndUpdate(
        { $or: [{ providerId: c.providerId }, { title: c.title }] },
        { $set: c },
        { upsert: true, new: true },
      );
      syncedLocalCount++;
    }

    for (const u of CORE_LEGAL_UPDATES) {
      await LegalUpdate.findOneAndUpdate(
        { title: u.title },
        { $set: u },
        { upsert: true, new: true },
      );
      syncedUpdatesCount++;
    }

    // 2. If Indian Kanoon API key is configured, query multiple diverse topics & sync
    if (IndianKanoonService.isConfigured()) {
      const queries = [
        "supreme court landmark judgments",
        "constitution fundamental rights article 21",
        "criminal law murder bail self defence",
        "indian contract act breach damages",
        "law of torts negligence vicarious liability",
        "family law hindu marriage maintenance",
        "environmental law pollution green tribunal",
        "code of criminal procedure arrest bail charge sheet",
        "delhi high court writ commercial arbitration",
        "bombay high court landmark judgment",
      ];

      for (const q of queries) {
        try {
          const res = await IndianKanoonService.search({ query: q, page: 1 });
          if (Array.isArray(res?.items)) {
            for (const item of res.items) {
              if (!item.providerId || !item.title) continue;
              await Case.findOneAndUpdate(
                { $or: [{ providerId: item.providerId }, { title: item.title }] },
                {
                  $set: {
                    title: item.title,
                    citation: item.citation,
                    court: item.court,
                    courtType: item.courtType,
                    providerId: item.providerId,
                    summary: item.summary || item.snippet,
                    judgmentPdfUrl: item.sourceUrl,
                    published: true,
                  },
                },
                { upsert: true },
              );
              syncedKanoonCount++;
            }
          }
        } catch (e) {
          console.error(`Sync query "${q}" failed:`, e?.message || e);
        }
      }
    }

    const totalCasesInDb = await Case.countDocuments();
    const totalUpdatesInDb = await LegalUpdate.countDocuments();

    return {
      ok: true,
      syncedKanoonCount,
      syncedLocalCount,
      totalCasesInDb,
      totalUpdatesInDb,
      message: IndianKanoonService.isConfigured()
        ? `Successfully synced ${syncedKanoonCount} Kanoon judgments and ${syncedLocalCount} landmark cases. Total database judgments: ${totalCasesInDb}.`
        : `Synced ${syncedLocalCount} landmark cases and ${syncedUpdatesCount} legal updates into MongoDB. Note: INDIAN_KANOON_API_KEY is not set for external provider sync.`,
    };
  }

  /**
   * Safe integration status check for admin panel (never reveals key)
   */
  static async checkStatus() {
    const configured = IndianKanoonService.isConfigured();
    const totalCases = await Case.countDocuments();
    const totalUpdates = await LegalUpdate.countDocuments();

    if (!configured) {
      return {
        configured: false,
        status: "unconfigured",
        message: "INDIAN_KANOON_API_KEY is not set in backend environment variables. App & Admin are operating in local database mode with curated judgments.",
        totalCases,
        totalUpdates,
      };
    }

    return {
      configured: true,
      status: "configured",
      message: "INDIAN_KANOON_API_KEY is active and configured. Database sync & live searches are enabled.",
      totalCases,
      totalUpdates,
    };
  }
}
