import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { CheckCircle2, ExternalLink, KeyRound, RefreshCw, RotateCcw, Server, ShieldCheck, Wifi, XCircle } from "lucide-react";
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
  const [checking, setChecking] = useState(false);

  useEffect(() => setApiUrl(getApiBase()), []);
  async function checkIntegration() {
    setChecking(true);
    setError(null);
    try {
      setStatus(await api<{ configured?: boolean; message?: string }>("/api/cases/integration-status"));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not check integration status");
    } finally {
      setLoading(false);
      setChecking(false);
    }
  }

  useEffect(() => {
    if (ready) checkIntegration();
  }, [ready]);

  function saveApiUrl() {
    setApiBase(apiUrl.trim());
    setSaved(true);
    window.setTimeout(() => setSaved(false), 2500);
  }

  function resetApiUrl() {
    const defaultUrl = "http://localhost:4000";
    setApiUrl(defaultUrl);
    setApiBase(defaultUrl);
    setSaved(true);
    window.setTimeout(() => setSaved(false), 2500);
  }

  return (
    <AdminShell title="Settings" subtitle="Control the admin workspace, integrations and deployment connection">
      <div className="mx-auto max-w-5xl space-y-6">
        <div className="grid gap-4 sm:grid-cols-3">
          <Panel className="flex items-center gap-3 p-4">
            <span className="flex size-10 items-center justify-center rounded-md bg-primary/10 text-primary"><Server className="size-5" /></span>
            <div><p className="text-xs uppercase tracking-wide text-muted-foreground">Backend</p><p className="font-semibold">{apiUrl || "Loading..."}</p></div>
          </Panel>
          <Panel className="flex items-center gap-3 p-4">
            <span className={`flex size-10 items-center justify-center rounded-md ${status?.configured ? "bg-emerald-100 text-emerald-700" : "bg-amber-100 text-amber-700"}`}>
              {status?.configured ? <CheckCircle2 className="size-5" /> : <KeyRound className="size-5" />}
            </span>
            <div><p className="text-xs uppercase tracking-wide text-muted-foreground">Indian Kanoon</p><p className="font-semibold">{status?.configured ? "Connected" : "Needs setup"}</p></div>
          </Panel>
          <Panel className="flex items-center gap-3 p-4">
            <span className="flex size-10 items-center justify-center rounded-md bg-blue-100 text-blue-700"><ShieldCheck className="size-5" /></span>
            <div><p className="text-xs uppercase tracking-wide text-muted-foreground">Access</p><p className="font-semibold">Administrator</p></div>
          </Panel>
        </div>

        <div className="grid gap-6 lg:grid-cols-[1.35fr_1fr]">
          <Panel className="p-6">
            <div className="flex items-start justify-between gap-4">
              <div><h2 className="font-display text-xl">Backend connection</h2><p className="mt-1 text-sm text-muted-foreground">Choose which API environment this panel uses.</p></div>
              <Wifi className="size-5 text-primary" />
            </div>
            <div className="mt-6 space-y-4">
              <Field label="API base URL">
                <Input value={apiUrl} onChange={(e) => setApiUrl(e.target.value)} placeholder="https://your-api.example.com" />
              </Field>
              <p className="text-xs text-muted-foreground">Use the backend origin only, without a trailing slash or <code>/api</code>.</p>
              <div className="flex flex-wrap gap-2">
                <Button onClick={saveApiUrl}>Save connection</Button>
                <Button variant="outline" onClick={resetApiUrl} className="gap-2"><RotateCcw className="size-4" /> Reset local URL</Button>
                <Button variant="outline" onClick={checkIntegration} disabled={checking} className="gap-2"><RefreshCw className={`size-4 ${checking ? "animate-spin" : ""}`} /> Test connection</Button>
              </div>
              {saved ? <p className="text-sm text-emerald-700">Connection settings saved locally.</p> : null}
            </div>
          </Panel>

          <Panel className="p-6">
            <div className="flex items-start justify-between gap-4"><div><h2 className="font-display text-xl">Indian Kanoon</h2><p className="mt-1 text-sm text-muted-foreground">Live legal search and document retrieval.</p></div><KeyRound className="size-5 text-primary" /></div>
            <div className="mt-6 rounded-md border border-border bg-muted/30 p-4">
              {loading ? <StateBlock loading /> : error ? <div className="flex gap-2 text-sm text-destructive"><XCircle className="size-4 shrink-0" />{error}</div> : status ? <div className="flex gap-2 text-sm"><CheckCircle2 className={`size-4 shrink-0 ${status.configured ? "text-emerald-600" : "text-amber-600"}`} /><span>{status.message}</span></div> : null}
            </div>
            <p className="mt-4 text-xs leading-relaxed text-muted-foreground">The API key is stored only in the backend environment. Use <strong>Cases &amp; Judgments</strong> to fetch permitted results into the database.</p>
            <Button variant="link" className="mt-2 h-auto gap-1 px-0" asChild><a href="https://indiankanoon.org" target="_blank" rel="noreferrer">Open Indian Kanoon <ExternalLink className="size-3" /></a></Button>
          </Panel>
        </div>

        <Panel className="p-6">
          <h2 className="font-display text-xl">About this panel</h2>
          <div className="mt-4 grid gap-4 text-sm sm:grid-cols-3">
            <div><p className="text-xs uppercase tracking-wide text-muted-foreground">Product</p><p className="mt-1 font-medium">Rishikesh Law Hub Admin</p></div>
            <div><p className="text-xs uppercase tracking-wide text-muted-foreground">Purpose</p><p className="mt-1 font-medium">Manage app content and legal data</p></div>
            <div><p className="text-xs uppercase tracking-wide text-muted-foreground">Environment</p><p className="mt-1 font-medium">{import.meta.env.MODE}</p></div>
          </div>
        </Panel>
      </div>
    </AdminShell>
  );
}
