import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { Stats } from "@/lib/types";
import { Button } from "@/components/ui/button";
import {
  CloudDownload,
  RefreshCw,
  CheckCircle2,
  AlertCircle,
  Clock,
  Database,
  ShieldCheck,
  Server,
  Scale,
  Sparkles,
  Info,
} from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/settings")({
  head: () => ({
    meta: [
      { title: "Settings & Integrations — Rishikesh Law Hub Admin" },
      { name: "description", content: "Configure Indian Kanoon sync, system integrations and platform settings." },
    ],
  }),
  component: SettingsAdmin,
});

interface SyncStatus {
  configured: boolean;
  isSyncing: boolean;
  lastSyncTime: string | null;
  lastSyncCount: number;
  lastSyncError: string | null;
  totalInDb: number;
  schedule: string;
}

interface IntegrationStatus {
  configured: boolean;
  status: string;
  message: string;
}

function SettingsAdmin() {
  const ready = useAdminGuard();
  const [stats, setStats] = useState<Stats | null>(null);
  const [syncStatus, setSyncStatus] = useState<SyncStatus | null>(null);
  const [integration, setIntegration] = useState<IntegrationStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [feedback, setFeedback] = useState<{ type: "success" | "error"; message: string } | null>(null);

  function loadSettings() {
    if (!ready) return;
    setLoading(true);
    Promise.all([
      api<Stats>("/api/stats").catch(() => null),
      api<SyncStatus>("/api/cases/sync-status").catch(() => null),
      api<IntegrationStatus>("/api/cases/integration-status").catch(() => null),
    ])
      .then(([statsRes, syncRes, intRes]) => {
        if (statsRes) setStats(statsRes);
        if (syncRes) setSyncStatus(syncRes);
        if (intRes) setIntegration(intRes);
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    loadSettings();
  }, [ready]);

  async function triggerKanoonSync() {
    setSyncing(true);
    setFeedback(null);
    try {
      const res = await api<{ success: boolean; count: number; totalInDb: number; message: string }>(
        "/api/cases/sync-kanoon",
        { method: "POST" }
      );
      setFeedback({
        type: "success",
        message: res.message || `Sync completed! Added ${res.count} new judgments into MongoDB database. Total in DB: ${res.totalInDb}.`,
      });
      loadSettings();
    } catch (err) {
      setFeedback({
        type: "error",
        message: err instanceof Error ? `Sync failed: ${err.message}` : "Failed to sync with Indian Kanoon.",
      });
    } finally {
      setSyncing(false);
    }
  }

  return (
    <AdminShell
      title="Settings & Integrations"
      subtitle="Indian Kanoon database synchronization, schedule management, and system overview"
      actions={
        <Button
          onClick={triggerKanoonSync}
          disabled={syncing}
          className="gap-2 bg-primary text-primary-foreground shadow-sm hover:bg-primary/90"
        >
          {syncing ? (
            <>
              <RefreshCw className="size-4 animate-spin" />
              <span>Fetching Kanoon...</span>
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
      <StateBlock loading={loading} />

      {/* Feedback Banner */}
      {feedback && (
        <div
          className={`mb-6 flex items-center justify-between rounded-lg border p-4 text-sm font-medium ${
            feedback.type === "success"
              ? "border-emerald-500/30 bg-emerald-500/10 text-emerald-700 dark:text-emerald-300"
              : "border-destructive/30 bg-destructive/10 text-destructive"
          }`}
        >
          <div className="flex items-center gap-2">
            {feedback.type === "success" ? (
              <CheckCircle2 className="size-5 shrink-0 text-emerald-600 dark:text-emerald-400" />
            ) : (
              <AlertCircle className="size-5 shrink-0 text-destructive" />
            )}
            <span>{feedback.message}</span>
          </div>
          <Button variant="ghost" size="sm" onClick={() => setFeedback(null)}>
            Dismiss
          </Button>
        </div>
      )}

      <div className="space-y-6">
        {/* 1. Indian Kanoon Sync & Integration Section */}
        <Panel className="p-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-border pb-5 mb-6">
            <div className="flex items-center gap-3">
              <div className="flex size-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
                <Scale className="size-5" />
              </div>
              <div>
                <h2 className="font-display text-lg font-semibold">Indian Kanoon Cloud Sync</h2>
                <p className="text-xs text-muted-foreground">
                  Synchronize landmark Supreme Court & High Court judgments into MongoDB for instant offline/online app access
                </p>
              </div>
            </div>

            <Button
              onClick={triggerKanoonSync}
              disabled={syncing}
              size="default"
              className="gap-2 bg-primary text-primary-foreground shadow-sm hover:bg-primary/90 shrink-0"
            >
              {syncing ? (
                <>
                  <RefreshCw className="size-4 animate-spin" />
                  <span>Syncing to Database...</span>
                </>
              ) : (
                <>
                  <CloudDownload className="size-4" />
                  <span>Fetch Data from Indian Kanoon</span>
                </>
              )}
            </Button>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div className="rounded-lg border border-border/80 bg-muted/20 p-4">
              <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Provider Status</p>
              <div className="mt-2 flex items-center gap-2">
                <span className="flex size-2 rounded-full bg-emerald-500" />
                <span className="font-semibold text-foreground">
                  {integration?.configured ? "Active & Configured" : "Curated Landmark Mode"}
                </span>
              </div>
              <p className="mt-1.5 text-xs text-muted-foreground">
                {integration?.message || "Connected to database and fallback repository."}
              </p>
            </div>

            <div className="rounded-lg border border-border/80 bg-muted/20 p-4">
              <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Auto-Sync Schedule</p>
              <div className="mt-2 flex items-center gap-2">
                <Clock className="size-4 text-primary" />
                <span className="font-semibold text-foreground">Every 12 Hours</span>
              </div>
              <p className="mt-1.5 text-xs text-muted-foreground">
                Automatic scheduled sync at 6:00 AM & 6:00 PM IST daily.
              </p>
            </div>

            <div className="rounded-lg border border-border/80 bg-muted/20 p-4">
              <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Database Records</p>
              <div className="mt-2 flex items-center gap-2">
                <Database className="size-4 text-primary" />
                <span className="font-display text-xl font-bold">{syncStatus?.totalInDb ?? stats?.counts?.cases ?? 0}</span>
                <span className="text-xs text-muted-foreground">Cases in DB</span>
              </div>
              <p className="mt-1.5 text-xs text-muted-foreground">
                {syncStatus?.lastSyncTime
                  ? `Last synced: ${new Date(syncStatus.lastSyncTime).toLocaleString()}`
                  : "Sync available anytime using button above"}
              </p>
            </div>
          </div>
        </Panel>

        {/* 2. Platform Branding & System Status */}
        <div className="grid gap-6 md:grid-cols-2">
          <Panel className="p-6">
            <div className="flex items-center gap-2.5 mb-4">
              <Sparkles className="size-5 text-primary" />
              <h2 className="font-display text-base font-semibold">Application Profile</h2>
            </div>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between border-b border-border/60 pb-2">
                <span className="text-muted-foreground">Application Name</span>
                <span className="font-medium">Law Hub (Rishikesh Law Hub)</span>
              </div>
              <div className="flex justify-between border-b border-border/60 pb-2">
                <span className="text-muted-foreground">Administrator</span>
                <span className="font-medium">Rishikesh Yadav</span>
              </div>
              <div className="flex justify-between border-b border-border/60 pb-2">
                <span className="text-muted-foreground">Target Audience</span>
                <span className="font-medium">Law Students, Advocates & Legal Professionals</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Admin Session</span>
                <span className="inline-flex items-center gap-1.5 text-xs font-medium text-emerald-600 dark:text-emerald-400">
                  <ShieldCheck className="size-3.5" /> Authenticated
                </span>
              </div>
            </div>
          </Panel>

          <Panel className="p-6">
            <div className="flex items-center gap-2.5 mb-4">
              <Server className="size-5 text-primary" />
              <h2 className="font-display text-base font-semibold">Database Content Totals</h2>
            </div>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between border-b border-border/60 pb-2">
                <span className="text-muted-foreground">Cases & Judgments</span>
                <span className="font-semibold">{stats?.counts?.cases ?? 0}</span>
              </div>
              <div className="flex justify-between border-b border-border/60 pb-2">
                <span className="text-muted-foreground">Statutory Acts & Codes</span>
                <span className="font-semibold">{stats?.counts?.acts ?? 0}</span>
              </div>
              <div className="flex justify-between border-b border-border/60 pb-2">
                <span className="text-muted-foreground">Legal Updates</span>
                <span className="font-semibold">{stats?.counts?.updates ?? 0}</span>
              </div>
              <div className="flex justify-between border-b border-border/60 pb-2">
                <span className="text-muted-foreground">Community Posts</span>
                <span className="font-semibold">{stats?.counts?.posts ?? 0}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Registered App Users</span>
                <span className="font-semibold">{stats?.counts?.users ?? 0}</span>
              </div>
            </div>
          </Panel>
        </div>

        {/* 3. Operational Information */}
        <Panel className="p-6 bg-muted/10 border-border/80">
          <div className="flex items-start gap-3">
            <Info className="size-5 text-primary shrink-0 mt-0.5" />
            <div className="space-y-1">
              <p className="text-sm font-semibold text-foreground">How Indian Kanoon Sync Works</p>
              <p className="text-xs text-muted-foreground leading-relaxed">
                When you click <strong>"Fetch Data from Indian Kanoon"</strong>, the backend searches landmark legal topics across Supreme Court and High Courts on Indian Kanoon, parses the judgments, and saves them directly into your MongoDB database. The mobile Flutter app and Admin Panel read directly from the database, guaranteeing instant search speeds and seamless offline support.
              </p>
            </div>
          </div>
        </Panel>
      </div>
    </AdminShell>
  );
}
