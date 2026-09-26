const DEFAULT_API = "http://localhost:4000";
const LOCAL_API_PATTERN = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?/i;

function isProductionHost(): boolean {
  if (typeof window === "undefined") return false;
  return window.location.hostname === "rishikesh-law-hub-admin.onrender.com";
}

export function getApiBase(): string {
  const env = import.meta.env["VITE_API_URL"] as string | undefined;
  if (typeof window !== "undefined") {
    const stored = window.localStorage.getItem("lawhub_api_base");
    if (stored) {
      const normalized = stored.replace(/\/$/, "");
      if (!(isProductionHost() && LOCAL_API_PATTERN.test(normalized))) {
        return normalized;
      }
      window.localStorage.removeItem("lawhub_api_base");
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
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  const token = getToken();
  if (auth && token) headers["Authorization"] = `Bearer ${token}`;

  let res: Response;
  try {
    res = await fetch(`${getApiBase()}${path}`, {
      method,
      headers,
      ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
    });
  } catch {
    throw new Error("Can't reach the server. Check the server address in Settings.");
  }

  const text = await res.text();
  const data = text ? (JSON.parse(text) as Record<string, unknown>) : {};
  if (!res.ok) {
    if (res.status === 401) setToken(null);
    throw new Error((data["error"] as string) || `Request failed (${res.status})`);
  }
  return data as T;
}
