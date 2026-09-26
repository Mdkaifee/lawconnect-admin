import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { Stats } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { CloudDownload, RefreshCw, CheckCircle2, AlertCircle, Clock } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/")({
  head: () => ({
    meta: [
      { title: "Dashboard — Law Hub Admin" },
      { name: "description", content: "Overview of cases, acts, posts, legal updates and app users." },
      { property: "og:title", content: "Dashboard — Law Hub Admin" },
      { property: "og:description", content: "Overview of content and users in Law Hub." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: Dashboard,
});

const LABELS: Record<string, string> = {
  cases: "Cases & Judgments",
  acts: "Acts & Sections",
  posts: "Community Posts",
  updates: "Legal Updates",
  users: "App Users",
  notes: "User Notes",
  bookmarks: "Bookmarks",
};

function Dashboard() {
  const ready = useAdminGuard();
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // Sync state
  const [syncing, setSyncing] = useState(false);
  const [syncMessage, setSyncMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  function loadStats() {
    if (!ready) return;
    setLoading(true);
    api<Stats>("/api/stats")
      .then(setStats)
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    loadStats();
  }, [ready]);

  async function handleSync() {
    setSyncing(true);
    setSyncMessage(null);
    try {
      const res = await api<{ ok: boolean; message: string; totalCasesInDb: number }>("/api/cases/sync-kanoon", {
        method: "POST",
      });
      setSyncMessage({
        type: "success",
        text: res.message || "Data synchronized from Indian Kanoon and saved to MongoDB successfully!",
      });
      // Refresh stats
      const updated = await api<Stats>("/api/stats");
      setStats(updated);
    } catch (err) {
      setSyncMessage({
        type: "error",
        text: err instanceof Error ? err.message : "Failed to sync data from Indian Kanoon",
      });
    } finally {
      setSyncing(false);
    }
  }

  return (
    <AdminShell
      title="Dashboard"
      subtitle="Overview of cases, statutory acts, community posts and app users"
      actions={
        <div className="flex items-center gap-2">
          <Button
            onClick={handleSync}
            disabled={syncing}
            variant="default"
            className="gap-2 shadow-sm font-medium"
          >
            {syncing ? (
              <>
                <RefreshCw className="size-4 animate-spin" />
                Syncing Kanoon...
              </>
            ) : (
              <>
                <CloudDownload className="size-4" />
                Fetch Data from Indian Kanoon
              </>
            )}
          </Button>
        </div>
      }
    >
      {/* Sync Status Banner */}
      {syncMessage ? (
        <div
          className={`mb-6 flex items-start gap-3 rounded-lg border p-4 text-sm ${
            syncMessage.type === "success"
              ? "border-emerald-500/20 bg-emerald-500/10 text-emerald-900 dark:text-emerald-200"
              : "border-destructive/20 bg-destructive/10 text-destructive"
          }`}
        >
          {syncMessage.type === "success" ? (
            <CheckCircle2 className="size-5 shrink-0 text-emerald-600 mt-0.5" />
          ) : (
            <AlertCircle className="size-5 shrink-0 mt-0.5" />
          )}
          <div className="flex-1">
            <p className="font-semibold">{syncMessage.type === "success" ? "Sync Completed" : "Sync Error"}</p>
            <p className="mt-0.5 text-xs opacity-90">{syncMessage.text}</p>
          </div>
          <button
            onClick={() => setSyncMessage(null)}
            className="text-xs opacity-60 hover:opacity-100 font-semibold"
          >
            Dismiss
          </button>
        </div>
      ) : null}

      {/* Auto-sync Schedule Notice */}
      <div className="mb-6 flex items-center justify-between rounded-lg border border-border bg-card/60 px-4 py-3 text-xs text-muted-foreground">
        <div className="flex items-center gap-2">
          <Clock className="size-4 text-primary" />
          <span>
            <strong>Auto-Sync Active:</strong> Automated background synchronization runs every 12 hours (at <strong>6:00 AM & 6:00 PM IST</strong>). All fetched judgments are stored permanently in MongoDB.
          </span>
        </div>
      </div>

      <StateBlock loading={loading} error={error} />
      {stats ? (
        <div className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {Object.entries(stats.counts).map(([key, value]) => (
              <Panel key={key} className="p-5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">{LABELS[key] ?? key}</p>
                <p className="mt-2 font-display text-3xl font-bold">{value}</p>
              </Panel>
            ))}
          </div>

          <div className="grid gap-4 lg:grid-cols-2">
            <Panel className="p-5">
              <h2 className="mb-3 font-display text-lg font-semibold">Recent cases in Database</h2>
              <ul className="space-y-3 text-sm">
                {stats.recentCases.map((c) => (
                  <li key={c._id} className="border-b border-border/40 pb-2 last:border-b-0">
                    <p className="font-medium text-foreground">{c.title}</p>
                    <p className="text-xs text-muted-foreground">{[c.citation, c.court].filter(Boolean).join(" · ")}</p>
                  </li>
                ))}
                {stats.recentCases.length === 0 ? <li className="text-muted-foreground">No cases saved yet. Click 'Fetch Data from Indian Kanoon' above.</li> : null}
              </ul>
            </Panel>
            <Panel className="p-5">
              <h2 className="mb-3 font-display text-lg font-semibold">Recent community posts</h2>
              <ul className="space-y-3 text-sm">
                {stats.recentPosts.map((p) => (
                  <li key={p._id} className="border-b border-border/40 pb-2 last:border-b-0">
                    <p className="font-medium text-foreground">{p.title}</p>
                    <p className="text-xs text-muted-foreground">{p.authorName} · <span className="uppercase">{p.status}</span></p>
                  </li>
                ))}
                {stats.recentPosts.length === 0 ? <li className="text-muted-foreground">No posts yet.</li> : null}
              </ul>
            </Panel>
          </div>
        </div>
      ) : null}
    </AdminShell>
  );
}
