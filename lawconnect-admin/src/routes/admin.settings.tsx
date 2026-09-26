import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Field } from "@/components/admin/DataPanel";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useAdminGuard } from "@/lib/useAdmin";
import { api, getApiBase, setApiBase } from "@/lib/api";

export const Route = createFileRoute("/admin/settings")({
  head: () => ({ meta: [{ title: "Settings | Rishikesh Law Hub Admin" }] }),
  component: Settings,
});

function Settings() {
  const ready = useAdminGuard();
  const [apiUrl, setApiUrl] = useState("");
  const [saved, setSaved] = useState(false);
  const [status, setStatus] = useState<{ configured?: boolean; message?: string } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => setApiUrl(getApiBase()), []);
  useEffect(() => {
    if (!ready) return;
    api<{ configured?: boolean; message?: string }>("/api/cases/integration-status")
      .then(setStatus)
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }, [ready]);

  function saveApiUrl() {
    setApiBase(apiUrl.trim());
    setSaved(true);
    window.setTimeout(() => setSaved(false), 2500);
  }

  return (
    <AdminShell title="Settings" subtitle="Configure the admin panel connection and integrations">
      <div className="mx-auto max-w-3xl space-y-6">
        <Panel className="p-5">
          <h2 className="font-display text-lg">Backend connection</h2>
          <p className="mt-1 text-sm text-muted-foreground">The API URL used by this admin panel.</p>
          <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-end">
            <div className="flex-1">
              <Field label="API base URL">
                <Input value={apiUrl} onChange={(e) => setApiUrl(e.target.value)} placeholder="http://localhost:4000" />
              </Field>
            </div>
            <Button onClick={saveApiUrl}>Save connection</Button>
          </div>
          {saved ? <p className="mt-3 text-sm text-green-700">Connection saved.</p> : null}
        </Panel>
        <Panel className="p-5">
          <h2 className="font-display text-lg">Indian Kanoon integration</h2>
          <p className="mt-1 text-sm text-muted-foreground">The API key is kept on the backend and is never displayed here.</p>
          <div className="mt-4">
            {loading ? <StateBlock loading /> : null}
            {!loading && error ? <StateBlock error={error} /> : null}
            {!loading && !error && status ? (
              <div className="rounded-md border border-border bg-muted/30 p-4 text-sm">
                <p className="font-medium">{status.configured ? "Connected" : "Not configured"}</p>
                <p className="mt-1 text-muted-foreground">{status.message}</p>
              </div>
            ) : null}
          </div>
        </Panel>
      </div>
    </AdminShell>
  );
}
