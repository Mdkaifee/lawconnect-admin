import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { Stats } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { CloudDownload, RefreshCw, CheckCircle2, Clock, Scale, ArrowRight } from "lucide-react";
import { useEffect, useState } from "react";
import { Link } from "@tanstack/react-router";

export const Route = createFileRoute("/admin/")({
  head: () => ({
    meta: [
      { title: "Dashboard — Rishikesh Law Hub Admin" },
      { name: "description", content: "Overview of cases, acts, posts, legal updates and app users." },
    ],
  }),
  component: Dashboard,
});

const LABELS: Record<string, string> = {
  cases: "Cases & Judgments",
  acts: "Acts & Laws",
  posts: "Community Posts",
  updates: "Legal Updates",
  users: "App Users",
  notes: "User Notes",
  bookmarks: "Bookmarks",
};

interface SyncStatus {
  configured: boolean;
  isSyncing: boolean;
  lastSyncTime: string | null;
  lastSyncCount: number;
  lastSyncError: string | null;
  totalInDb: number;
  schedule: string;
}

function Dashboard() {
  const ready = useAdminGuard();
  const [stats, setStats] = useState<Stats | null>(null);
  const [syncStatus, setSyncStatus] = useState<SyncStatus | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [syncMessage, setSyncMessage] = useState<string | null>(null);

  function loadData() {
    if (!ready) return;
    setLoading(true);
    Promise.all([
      api<Stats>("/api/stats"),
      api<SyncStatus>("/api/cases/sync-status").catch(() => null),
    ])
      .then(([statsRes, syncRes]) => {
        setStats(statsRes);
        if (syncRes) setSyncStatus(syncRes);
      })
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    loadData();
  }, [ready]);

  async function triggerKanoonSync() {
    setSyncing(true);
    setSyncMessage(null);
    try {
      const res = await api<{ success: boolean; count: number; totalInDb: number; message: string }>(
        "/api/cases/sync-kanoon",
        { method: "POST" }
      );
      setSyncMessage(res.message || `Successfully synced ${res.count} judgments to database!`);
      // Refresh stats & sync status
      const [newStats, newSync] = await Promise.all([
        api<Stats>("/api/stats"),
        api<SyncStatus>("/api/cases/sync-status").catch(() => null),
      ]);
      setStats(newStats);
      if (newSync) setSyncStatus(newSync);
    } catch (err) {
      setSyncMessage(err instanceof Error ? `Sync failed: ${err.message}` : "Failed to fetch from Indian Kanoon.");
    } finally {
      setSyncing(false);
    }
  }

  return (
    <AdminShell
      title="Dashboard"
      subtitle="Overview of cases, statutory acts, legal updates, community posts and app users"
      actions={
        <Button
          onClick={triggerKanoonSync}
          disabled={syncing}
          className="gap-2 bg-primary text-primary-foreground shadow-sm hover:bg-primary/90"
        >
          {syncing ? (
            <>
              <RefreshCw className="size-4 animate-spin" />
              <span>Fetching Kanoon Data...</span>
            </>
          ) : (
            <>
              <CloudDownload className="size-4" />
              <span>Fetch Data from Indian Kanoon</span>
            </>
          )}
        </Button>
      }
    >
      <StateBlock loading={loading} error={error} />

      {/* Sync Status Banner */}
      {syncMessage && (
        <div className="mb-6 flex items-center justify-between rounded-lg border border-primary/30 bg-primary/10 p-4 text-sm font-medium text-foreground">
          <div className="flex items-center gap-2">
            <CheckCircle2 className="size-5 text-primary shrink-0" />
            <span>{syncMessage}</span>
          </div>
          <Button variant="ghost" size="sm" onClick={() => setSyncMessage(null)}>
            Dismiss
          </Button>
        </div>
      )}

      {/* Indian Kanoon Cloud Sync Feature Card */}
      <div className="mb-6 overflow-hidden rounded-xl border border-border bg-gradient-to-r from-card via-card to-primary/5 p-6 shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-5">
          <div className="space-y-1.5 max-w-xl">
            <div className="flex items-center gap-2.5">
              <div className="flex size-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
                <Scale className="size-4" />
              </div>
              <h2 className="font-display text-lg font-semibold tracking-tight">Indian Kanoon Database Sync</h2>
              <span className="inline-flex items-center rounded-full bg-emerald-500/10 px-2 py-0.5 text-xs font-medium text-emerald-600 dark:text-emerald-400">
                Ready to Sync
              </span>
            </div>
            <p className="text-sm text-muted-foreground leading-relaxed">
              Fetch landmark judgments across the Supreme Court and High Courts from Indian Kanoon directly into your MongoDB database. Mobile app and admin panel load instantly from database records.
            </p>
            <div className="flex flex-wrap items-center gap-4 pt-1 text-xs text-muted-foreground">
              <div className="flex items-center gap-1.5">
                <Clock className="size-3.5 text-primary" />
                <span>Auto-syncs every 12 hours (6:00 AM & 6:00 PM)</span>
              </div>
              {syncStatus?.lastSyncTime && (
                <div className="flex items-center gap-1.5">
                  <CheckCircle2 className="size-3.5 text-emerald-500" />
                  <span>Last synced: {new Date(syncStatus.lastSyncTime).toLocaleString()}</span>
                </div>
              )}
            </div>
          </div>

          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 shrink-0">
            <Button
              onClick={triggerKanoonSync}
              disabled={syncing}
              size="lg"
              className="gap-2 bg-primary text-primary-foreground hover:bg-primary/90 shadow-md font-medium"
            >
              {syncing ? (
                <>
                  <RefreshCw className="size-4 animate-spin" />
                  <span>Fetching & Saving...</span>
                </>
              ) : (
                <>
                  <CloudDownload className="size-4" />
                  <span>Fetch Data from Indian Kanoon</span>
                </>
              )}
            </Button>
            <Link to="/admin/cases">
              <Button variant="outline" size="lg" className="w-full gap-2">
                <span>View Cases</span>
                <ArrowRight className="size-4" />
              </Button>
            </Link>
          </div>
        </div>
      </div>

      {stats ? (
        <div className="space-y-6">
          {/* Stats Grid */}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {Object.entries(stats.counts).map(([key, value]) => (
              <Panel key={key} className="p-5 hover:border-primary/40 transition-colors">
                <p className="text-xs uppercase tracking-wide text-muted-foreground font-semibold">
                  {LABELS[key] ?? key}
                </p>
                <p className="mt-2 font-display text-3xl font-bold tracking-tight">{value}</p>
              </Panel>
            ))}
          </div>

          {/* Recent Cases and Posts */}
          <div className="grid gap-6 lg:grid-cols-2">
            <Panel className="p-5">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="font-display text-lg font-semibold">Recent Cases & Judgments</h2>
                <Link to="/admin/cases" className="text-xs font-medium text-primary hover:underline">
                  View all →
                </Link>
              </div>
              <ul className="space-y-3 text-sm">
                {stats.recentCases.map((c) => (
                  <li key={c._id} className="rounded-md border border-border/60 bg-muted/20 p-3">
                    <p className="font-medium text-foreground">{c.title}</p>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {[c.citation, c.court].filter(Boolean).join(" · ")}
                    </p>
                  </li>
                ))}
                {stats.recentCases.length === 0 ? (
                  <li className="py-4 text-center text-muted-foreground">
                    No cases in database yet. Click "Fetch Data from Indian Kanoon" above to sync landmark judgments.
                  </li>
                ) : null}
              </ul>
            </Panel>

            <Panel className="p-5">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="font-display text-lg font-semibold">Recent Community Posts</h2>
                <Link to="/admin/posts" className="text-xs font-medium text-primary hover:underline">
                  View all →
                </Link>
              </div>
              <ul className="space-y-3 text-sm">
                {stats.recentPosts.map((p) => (
                  <li key={p._id} className="rounded-md border border-border/60 bg-muted/20 p-3">
                    <p className="font-medium text-foreground">{p.title}</p>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {p.authorName} · <span className="capitalize">{p.status}</span>
                    </p>
                  </li>
                ))}
                {stats.recentPosts.length === 0 ? (
                  <li className="py-4 text-center text-muted-foreground">No posts yet.</li>
                ) : null}
              </ul>
            </Panel>
          </div>
        </div>
      ) : null}
    </AdminShell>
  );
}
