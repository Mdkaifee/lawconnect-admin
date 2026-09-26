import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { Stats } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { CloudDownload, RefreshCw, CheckCircle2, AlertCircle, Clock, Sparkles, Database, ArrowRight } from "lucide-react";
import { useEffect, useState } from "react";
import { Link } from "@tanstack/react-router";

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
      const res = await api<{ ok: boolean; message: string; totalCasesInDb: number; totalUpdatesInDb: number }>(
        "/api/cases/sync-kanoon",
        { method: "POST" }
      );
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
        <Button
          onClick={handleSync}
          disabled={syncing}
          className="gap-2 shadow-sm font-semibold bg-primary text-primary-foreground hover:bg-primary/90"
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
      }
    >
      {/* Prominent Quick-Action Hero Card */}
      <div className="mb-6 overflow-hidden rounded-xl border border-primary/20 bg-gradient-to-r from-primary/10 via-primary/5 to-transparent p-6 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="space-y-1.5">
            <div className="flex items-center gap-2">
              <span className="flex size-7 items-center justify-center rounded-full bg-primary text-primary-foreground">
                <Database className="size-3.5" />
              </span>
              <h2 className="font-display text-lg font-bold text-foreground">
                Indian Kanoon & Database Synchronization
              </h2>
            </div>
            <p className="max-w-2xl text-xs text-muted-foreground leading-relaxed">
              Fetch comprehensive judgments and legal updates from Indian Kanoon and save them into MongoDB. The app and admin panel automatically serve full data offline and online. Auto-sync runs every 12 hours (at <strong>6:00 AM & 6:00 PM IST</strong>).
            </p>
          </div>
          <div className="flex shrink-0 items-center gap-2">
            <Button
              onClick={handleSync}
              disabled={syncing}
              size="lg"
              className="gap-2 font-bold shadow-md bg-primary text-primary-foreground hover:bg-primary/90"
            >
              {syncing ? (
                <>
                  <RefreshCw className="size-4 animate-spin" />
                  Syncing Judgments...
                </>
              ) : (
                <>
                  <CloudDownload className="size-5" />
                  Fetch Data from Indian Kanoon
                </>
              )}
            </Button>
          </div>
        </div>
      </div>

      {/* Sync Feedback Message Banner */}
      {syncMessage ? (
        <div
          className={`mb-6 flex items-start gap-3 rounded-lg border p-4 text-sm ${
            syncMessage.type === "success"
              ? "border-emerald-500/30 bg-emerald-500/10 text-emerald-900 dark:text-emerald-200"
              : "border-destructive/30 bg-destructive/10 text-destructive"
          }`}
        >
          {syncMessage.type === "success" ? (
            <CheckCircle2 className="size-5 shrink-0 text-emerald-600 mt-0.5" />
          ) : (
            <AlertCircle className="size-5 shrink-0 mt-0.5" />
          )}
          <div className="flex-1">
            <p className="font-bold">{syncMessage.type === "success" ? "Synchronization Succeeded" : "Sync Error"}</p>
            <p className="mt-0.5 text-xs opacity-90">{syncMessage.text}</p>
          </div>
          <button
            onClick={() => setSyncMessage(null)}
            className="text-xs font-semibold opacity-60 hover:opacity-100"
          >
            Dismiss
          </button>
        </div>
      ) : null}

      <StateBlock loading={loading} error={error} />
      {stats ? (
        <div className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {Object.entries(stats.counts).map(([key, value]) => (
              <Panel key={key} className="p-5 hover:border-primary/40 transition-colors">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">{LABELS[key] ?? key}</p>
                <p className="mt-2 font-display text-3xl font-bold text-foreground">{value}</p>
              </Panel>
            ))}
          </div>

          <div className="grid gap-4 lg:grid-cols-2">
            <Panel className="p-5">
              <div className="flex items-center justify-between mb-3">
                <h2 className="font-display text-lg font-bold">Recent Judgments in Database</h2>
                <Link to="/admin/cases" className="text-xs font-medium text-primary flex items-center gap-1 hover:underline">
                  View All Cases <ArrowRight className="size-3" />
                </Link>
              </div>
              <ul className="space-y-3 text-sm">
                {stats.recentCases.map((c) => (
                  <li key={c._id} className="border-b border-border/40 pb-2.5 last:border-b-0">
                    <p className="font-semibold text-card-foreground">{c.title}</p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {[c.citation, c.court].filter(Boolean).join(" · ")}
                    </p>
                  </li>
                ))}
                {stats.recentCases.length === 0 ? (
                  <li className="text-muted-foreground py-4 text-center">
                    No cases saved yet. Click the <strong>'Fetch Data from Indian Kanoon'</strong> button above to populate judgments.
                  </li>
                ) : null}
              </ul>
            </Panel>

            <Panel className="p-5">
              <div className="flex items-center justify-between mb-3">
                <h2 className="font-display text-lg font-bold">Recent Community Posts</h2>
                <Link to="/admin/posts" className="text-xs font-medium text-primary flex items-center gap-1 hover:underline">
                  View All Posts <ArrowRight className="size-3" />
                </Link>
              </div>
              <ul className="space-y-3 text-sm">
                {stats.recentPosts.map((p) => (
                  <li key={p._id} className="border-b border-border/40 pb-2.5 last:border-b-0">
                    <p className="font-semibold text-card-foreground">{p.title}</p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {p.authorName} · <span className="uppercase text-[10px] font-bold px-1.5 py-0.5 rounded bg-muted">{p.status}</span>
                    </p>
                  </li>
                ))}
                {stats.recentPosts.length === 0 ? (
                  <li className="text-muted-foreground py-4 text-center">No posts published yet.</li>
                ) : null}
              </ul>
            </Panel>
          </div>
        </div>
      ) : null}
    </AdminShell>
  );
}
