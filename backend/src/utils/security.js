import { URL } from "url";

/**
 * List of approved public legal source domains for URL verification / imports
 */
const APPROVED_SOURCE_DOMAINS = [
  "indiacode.nic.in",
  "egazette.gov.in",
  "sci.gov.in",
  "main.sci.gov.in",
  "indiankanoon.org",
  "api.indiankanoon.org",
  "ecourts.gov.in",
  "judgments.ecourts.gov.in",
  "delhihighcourt.nic.in",
  "bombayhighcourt.nic.in",
  "allahabadhighcourt.in",
  "karnatakahiighcourt.kar.nic.in",
  "livelaw.in",
  "barandbench.com",
];

const PRIVATE_IP_PATTERNS = [
  /^127\./,
  /^10\./,
  /^172\.(1[6-9]|2[0-9]|3[0-1])\./,
  /^192\.168\./,
  /^169\.254\./,
  /^0\./,
  /^::1$/,
  /^fc00:/i,
  /^fe80:/i,
];

/**
 * Validate external URL against SSRF attacks and approved domain lists
 */
export function validateSafeUrl(urlString, options = { requireApprovedDomain: true }) {
  if (!urlString || typeof urlString !== "string") {
    return { safe: false, reason: "Invalid URL provided" };
  }

  let parsed;
  try {
    parsed = new URL(urlString.trim());
  } catch {
    return { safe: false, reason: "Malformed URL syntax" };
  }

  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
    return { safe: false, reason: `Unsupported protocol '${parsed.protocol}'. Only HTTP/HTTPS allowed.` };
  }

  const hostname = parsed.hostname.toLowerCase();

  if (hostname === "localhost" || hostname === "127.0.0.1" || hostname === "0.0.0.0") {
    return { safe: false, reason: "Access to localhost is blocked." };
  }

  for (const pattern of PRIVATE_IP_PATTERNS) {
    if (pattern.test(hostname)) {
      return { safe: false, reason: "Access to private/internal network addresses is blocked." };
    }
  }

  if (options.requireApprovedDomain) {
    const isApproved = APPROVED_SOURCE_DOMAINS.some(
      (domain) => hostname === domain || hostname.endsWith(`.${domain}`),
    );
    if (!isApproved) {
      return {
        safe: false,
        reason: `Host '${hostname}' is not in the approved legal source domain whitelist. Approved sources: India Code, Supreme Court of India, eGazette, Indian Kanoon, eCourts.`,
      };
    }
  }

  return { safe: true, url: parsed.toString(), hostname };
}

/**
 * Robust HTML Sanitizer to eliminate XSS vectors from external legal texts
 */
export function sanitizeHtmlText(dirtyHtml) {
  if (!dirtyHtml || typeof dirtyHtml !== "string") return "";

  let cleaned = dirtyHtml;

  // Remove script, style, iframe, object, embed, form, input, button tags and their contents
  cleaned = cleaned.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, "");
  cleaned = cleaned.replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, "");
  cleaned = cleaned.replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi, "");
  cleaned = cleaned.replace(/<object\b[^<]*(?:(?!<\/object>)<[^<]*)*<\/object>/gi, "");
  cleaned = cleaned.replace(/<embed\b[^<]*(?:(?!<\/embed>)<[^<]*)*<\/embed>/gi, "");
  cleaned = cleaned.replace(/<form\b[^<]*(?:(?!<\/form>)<[^<]*)*<\/form>/gi, "");

  // Strip inline event handlers (onload, onerror, onclick, onmouseover, etc.)
  cleaned = cleaned.replace(/\son\w+\s*=\s*(['"]).*?\1/gi, "");
  cleaned = cleaned.replace(/\son\w+\s*=\s*[^>\s]+/gi, "");

  // Strip javascript: pseudo-protocols in href/src
  cleaned = cleaned.replace(/href\s*=\s*(['"])javascript:[^'"]*\1/gi, 'href="#"');
  cleaned = cleaned.replace(/src\s*=\s*(['"])javascript:[^'"]*\1/gi, 'src=""');

  return cleaned;
}

/**
 * Sanitize error messages and objects so secrets are never printed in logs or client responses
 */
export function sanitizeLogOutput(value) {
  if (!value) return value;
  const str = typeof value === "string" ? value : JSON.stringify(value);
  return str
    .replace(/(?:Token|Bearer|key|secret|password|INDIAN_KANOON_API_KEY)[=:\s]+(['"]?)[a-zA-Z0-9_\-\.]{8,}\1/gi, "Token [REDACTED]")
    .replace(/mongodb\+srv:\/\/[^:]+:[^@]+@/gi, "mongodb+srv://[REDACTED_USER]:[REDACTED_PASS]@");
}
