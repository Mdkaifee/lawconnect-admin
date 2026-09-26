const DEFAULT_API = "https://lawconnect-admin.onrender.com";
const LOCAL_API_PATTERN = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/i;

function isProductionHost(): boolean {
  if (typeof window === "undefined") return false;
  return (
    window.location.hostname === "rishikesh-law-hub-admin.onrender.com" ||
    window.location.hostname.endsWith(".onrender.com")
  );
}

export function getApiBase(): string {
  const env = import.meta.env["VITE_API_URL"] as string | undefined;
  if (typeof window !== "undefined") {
    const stored = window.localStorage.getItem("lawhub_api_base");
    if (stored) {
      const normalized = stored.replace(/\/$/, "");
      if (isProductionHost() && LOCAL_API_PATTERN.test(normalized)) {
        window.localStorage.removeItem("lawhub_api_base");
        return DEFAULT_API;
      }
      return normalized;
    }
    if (isProductionHost()) {
      return DEFAULT_API;
    }
  }
  return (env || DEFAULT_API).replace(/\/$/, "");
}

export function setApiBase(url: string) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem("lawhub_api_base", url.replace(/\/$/, ""));
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
  options: { method?: string; body?: unknown; auth?: boolean } = {},
): Promise<T> {
  const { method = "GET", body, auth = true } = options;
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };
  const token = getToken();
  if (auth && token) headers["Authorization"] = `Bearer ${token}`;

  let res: Response;
  const base = getApiBase();
  try {
    res = await fetch(`${base}${path}`, {
      method,
      headers,
      ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
    });
  } catch (err: unknown) {
    console.error(`API Fetch Error [${method} ${base}${path}]:`, err);
    throw new Error("Can't reach the server. Check the server address in Settings.");
  }

  const text = await res.text();
  let data: Record<string, unknown> = {};
  try {
    data = text ? (JSON.parse(text) as Record<string, unknown>) : {};
  } catch {
    data = { error: text };
  }

  if (!res.ok) {
    if (res.status === 401) setToken(null);
    throw new Error((data["error"] as string) || `Request failed (${res.status})`);
  }
  return data as T;
}
