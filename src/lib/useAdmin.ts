import { useNavigate } from "@tanstack/react-router";
import { useCallback, useEffect, useState } from "react";
import { api, getToken } from "@/lib/api";

export function useAdminGuard() {
  const navigate = useNavigate();
  const [ready, setReady] = useState(false);
  useEffect(() => {
    if (!getToken()) navigate({ to: "/", replace: true });
    else setReady(true);
  }, [navigate]);
  return ready;
}

export function useResource<T>(path: string, key = "items") {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api<Record<string, unknown>>(path);
      setData((res[key] as T[]) ?? []);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong");
    } finally {
      setLoading(false);
    }
  }, [path, key]);

  useEffect(() => {
    void reload();
  }, [reload]);

  return { data, loading, error, reload, setData };
}
