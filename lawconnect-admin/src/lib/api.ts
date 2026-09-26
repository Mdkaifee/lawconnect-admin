const DEFAULT_API =
  typeof window !== "undefined" && window.location.hostname === "localhost"
    ? "http://localhost:4000"
    : "https://lawconnect-admin.onrender.com";

export function getApiBase(): string {
  if (typeof window !== "undefined") {
    const stored = window.localStorage.getItem("lawhub_api_base");
    // If we're on production, ignore any stale localhost setting from local dev
    if (stored && (window.location.hostname === "localhost" || !stored.includes("localhost"))) {
      return stored.replace(/\/$/, "");
    }
  }
  const env = import.meta.env["VITE_API_URL"] as string | undefined;
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
  const base = getApiBase();
  try {
    res = await fetch(`${base}${path}`, {
      method,
      headers,
      credentials: "omit",
      ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
    });
  } catch {
    throw new Error(`Can't reach the backend server at ${base}. Please ensure the backend is running.`);
  }

  const text = await res.text();
  let data: Record<string, unknown> = {};
  try {
    data = text ? (JSON.parse(text) as Record<string, unknown>) : {};
  } catch {
    data = { error: text || `HTTP ${res.status}` };
  }

  if (!res.ok) {
    if (res.status === 401) setToken(null);
    throw new Error((data["error"] as string) || `Request failed (${res.status})`);
  }
  return data as T;
}
