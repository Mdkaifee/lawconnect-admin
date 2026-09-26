const LIVE_API_URL = "https://lawconnect-admin.onrender.com";
const LOCAL_API_URL = "http://localhost:4000";
const LOCAL_API_PATTERN = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/i;

function isLocalhost(): boolean {
  if (typeof window === "undefined") return false;
  return window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1";
}

export function getApiBase(): string {
  const env = (import.meta.env["VITE_API_URL"] as string | undefined)?.trim();
  
  if (typeof window !== "undefined") {
    const stored = window.localStorage.getItem("lawhub_api_base");
    if (stored) {
      const normalized = stored.trim().replace(/\/$/, "");
      // If we are on a remote server/render and stored url is localhost, clear and purge it
      if (!isLocalhost() && LOCAL_API_PATTERN.test(normalized)) {
        window.localStorage.removeItem("lawhub_api_base");
      } else if (normalized.length > 0) {
        return normalized;
      }
    }
  }

  if (env && env.length > 0) {
    return env.replace(/\/$/, "");
  }

  // If running in browser locally default to localhost, otherwise live API
  if (isLocalhost()) {
    return LOCAL_API_URL;
  }
  return LIVE_API_URL;
}

export function setApiBase(url: string) {
  if (typeof window === "undefined") return;
  const cleaned = (url || "").trim().replace(/\/$/, "");
  if (!cleaned) {
    window.localStorage.removeItem("lawhub_api_base");
  } else {
    window.localStorage.setItem("lawhub_api_base", cleaned);
  }
}

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem("lawhub_admin_token");
}

export function setToken(token: string | null) {
  if (typeof window === "undefined") return;
  if (token) window.localStorage.setItem("lawhub_admin_token", token);
  else window.localStorage.removeItem("lawhub_admin_token");
}

export async function api<T = unknown>(
  path: string,
  options: { method?: string; body?: unknown; auth?: boolean; retries?: number } = {},
): Promise<T> {
  const { method = "GET", body, auth = true, retries = 1 } = options;
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  const token = getToken();
  if (auth && token) headers["Authorization"] = `Bearer ${token}`;

  const base = getApiBase();
  const url = `${base}${path.startsWith("/") ? path : `/${path}`}`;

  let res: Response;
  try {
    res = await fetch(url, {
      method,
      headers,
      ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
    });
  } catch (netErr: any) {
    // If request failed and we have retries left (Render cold start handling)
    if (retries > 0 && method === "GET") {
      await new Promise((r) => setTimeout(r, 1200));
      return api<T>(path, { ...options, retries: retries - 1 });
    }
    throw new Error(
      `Cannot reach the backend API at ${base}. If Render is waking up from sleep, please wait a few seconds and retry.`,
    );
  }

  const text = await res.text();
  let data: any = {};
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = { raw: text };
    }
  }

  if (!res.ok) {
    if (res.status === 401) setToken(null);
    throw new Error((data?.error as string) || (data?.message as string) || `Request failed (${res.status})`);
  }

  return data as T;
}
