import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Field } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  ShieldCheck,
  KeyRound,
  Database,
  CloudDownload,
  RefreshCw,
  Server,
  CheckCircle2,
  AlertCircle,
  Clock,
  ExternalLink,
} from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/settings")({
  head: () => ({
    meta: [
      { title: "Settings — Law Hub Admin" },
      { name: "description", content: "Manage admin security, Indian Kanoon data synchronization, and system configuration." },
    ],
  }),
  component: SettingsAdmin,
});

interface IntegrationStatus {
  configured: boolean;
  status: string;
  message: string;
  totalCases?: number;
  totalUpdates?: number;
}

interface AdminProfile {
  id: string;
  username: string;
  name: string;
  role: string;
}

function SettingsAdmin() {
  const ready = useAdminGuard();

  // Profile & Password State
  const [admin, setAdmin] = useState<AdminProfile | null>(null);
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passError, setPassError] = useState<string | null>(null);
  const [passSuccess, setPassSuccess] = useState<string | null>(null);
  const [passSaving, setPassSaving] = useState(false);

  // Kanoon Integration State
  const [integration, setIntegration] = useState<IntegrationStatus | null>(null);
  const [loadingStatus, setLoadingStatus] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [syncResult, setSyncResult] = useState<{ type: "success" | "error"; text: string } | null>(null);

  function loadData() {
    if (!ready) return;
    setLoadingStatus(true);
    Promise.allSettled([
      api<{ admin: AdminProfile }>("/api/auth/admin/me"),
      api<IntegrationStatus>("/api/cases/integration-status"),
    ]).then(([admRes, intRes]) => {
      if (admRes.status === "fulfilled") setAdmin(admRes.value.admin);
      if (intRes.status === "fulfilled") setIntegration(intRes.value);
      setLoadingStatus(false);
    });
  }

  useEffect(() => {
    loadData();
  }, [ready]);

  async function handlePasswordChange(e: React.FormEvent) {
    e.preventDefault();
    setPassError(null);
    setPassSuccess(null);

    if (!currentPassword) {
      setPassError("Please enter your current password");
      return;
    }
    if (newPassword.length < 6) {
      setPassError("New password must be at least 6 characters");
      return;
    }
    if (newPassword !== confirmPassword) {
      setPassError("New passwords do not match");
      return;
    }

    setPassSaving(true);
    try {
      await api("/api/auth/admin/change-password", {
        method: "POST",
        body: { currentPassword, newPassword },
      });
      setPassSuccess("Password updated successfully!");
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
    } catch (err) {
      setPassError(err instanceof Error ? err.message : "Failed to change password");
    } finally {
      setPassSaving(false);
    }
  }

  async function handleSyncKanoon() {
    setSyncing(true);
    setSyncResult(null);
    try {
      const res = await api<{ ok: boolean; message: string; totalCasesInDb: number; totalUpdatesInDb: number }>(
        "/api/cases/sync-kanoon",
        { method: "POST" }
      );
      setSyncResult({
        type: "success",
        text: res.message || "Database successfully synchronized from Indian Kanoon!",
      });
      // Refresh integration metrics
      const updatedStatus = await api<IntegrationStatus>("/api/cases/integration-status");
      setIntegration(updatedStatus);
    } catch (err) {
      setSyncResult({
        type: "error",
        text: err instanceof Error ? err.message : "Synchronization failed. Please check server logs.",
      });
    } finally {
      setSyncing(false);
    }
  }

  return (
    <AdminShell
      title="System Settings"
      subtitle="Security credentials, Indian Kanoon synchronization, and server infrastructure"
    >
      <div className="max-w-4xl space-y-8">
        {/* Kanoon & Database Synchronization Panel */}
        <Panel className="p-6">
          <div className="flex items-center justify-between border-b border-border pb-4">
            <div className="flex items-center gap-3">
              <span className="flex size-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
                <Database className="size-5" />
              </span>
              <div>
                <h2 className="font-display text-lg font-semibold">Indian Kanoon & Database Synchronization</h2>
                <p className="text-xs text-muted-foreground">
                  Synchronize judgments and legal updates into MongoDB for high-speed offline serving
                </p>
              </div>
            </div>
            <Button
              onClick={handleSyncKanoon}
              disabled={syncing}
              className="gap-2 shadow-sm font-medium"
            >
              {syncing ? (
                <>
                  <RefreshCw className="size-4 animate-spin" />
                  Syncing...
                </>
              ) : (
                <>
                  <CloudDownload className="size-4" />
                  Sync Kanoon to DB Now
                </>
              )}
            </Button>
          </div>

          {syncResult && (
            <div
              className={`mt-4 flex items-start gap-3 rounded-lg border p-4 text-sm ${
                syncResult.type === "success"
                  ? "border-emerald-500/20 bg-emerald-500/10 text-emerald-900 dark:text-emerald-200"
                  : "border-destructive/20 bg-destructive/10 text-destructive"
              }`}
            >
              {syncResult.type === "success" ? (
                <CheckCircle2 className="size-5 shrink-0 text-emerald-600 mt-0.5" />
              ) : (
                <AlertCircle className="size-5 shrink-0 mt-0.5" />
              )}
              <div className="flex-1">
                <p className="font-semibold">{syncResult.type === "success" ? "Sync Succeeded" : "Sync Error"}</p>
                <p className="mt-0.5 text-xs opacity-90">{syncResult.text}</p>
              </div>
              <button
                onClick={() => setSyncResult(null)}
                className="text-xs opacity-60 hover:opacity-100 font-semibold"
              >
                Dismiss
              </button>
            </div>
          )}

          <div className="mt-6 grid gap-4 sm:grid-cols-2">
            <div className="rounded-lg border border-border bg-card/50 p-4">
              <p className="text-xs font-semibold uppercase text-muted-foreground">API Connection Status</p>
              <div className="mt-2 flex items-center gap-2">
                {integration?.configured ? (
                  <span className="flex items-center gap-1.5 font-medium text-emerald-600 text-sm">
                    <span className="size-2 rounded-full bg-emerald-500" /> Active & Configured
                  </span>
                ) : (
                  <span className="flex items-center gap-1.5 font-medium text-amber-600 text-sm">
                    <span className="size-2 rounded-full bg-amber-500" /> Curated Database Fallback Mode
                  </span>
                )}
              </div>
              <p className="mt-2 text-xs text-muted-foreground leading-relaxed">
                {integration?.message || "Checking status..."}
              </p>
            </div>

            <div className="rounded-lg border border-border bg-card/50 p-4">
              <p className="text-xs font-semibold uppercase text-muted-foreground">Automated Sync Schedule</p>
              <div className="mt-2 flex items-center gap-2">
                <Clock className="size-4 text-primary" />
                <span className="text-sm font-semibold text-foreground">Every 12 Hours (6:00 AM & 6:00 PM IST)</span>
              </div>
              <p className="mt-2 text-xs text-muted-foreground leading-relaxed">
                The backend scheduler automatically fetches new judgments and updates twice daily, upserting them into MongoDB.
              </p>
            </div>
          </div>
        </Panel>

        {/* Admin Account & Security Panel */}
        <Panel className="p-6">
          <div className="flex items-center gap-3 border-b border-border pb-4">
            <span className="flex size-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <ShieldCheck className="size-5" />
            </span>
            <div>
              <h2 className="font-display text-lg font-semibold">Admin Account & Security</h2>
              <p className="text-xs text-muted-foreground">Manage your owner login credentials and password</p>
            </div>
          </div>

          <div className="mt-6 grid gap-6 md:grid-cols-2">
            <div>
              <h3 className="text-sm font-semibold text-foreground mb-3">Owner Profile Details</h3>
              <div className="space-y-3 text-sm">
                <div>
                  <p className="text-xs font-medium text-muted-foreground">Username</p>
                  <p className="font-mono text-sm font-semibold mt-0.5">{admin?.username || "Admin"}</p>
                </div>
                <div>
                  <p className="text-xs font-medium text-muted-foreground">Full Name</p>
                  <p className="text-sm font-medium mt-0.5">{admin?.name || "Rishikesh Yadav"}</p>
                </div>
                <div>
                  <p className="text-xs font-medium text-muted-foreground">Role</p>
                  <p className="inline-block rounded bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary uppercase mt-0.5">
                    {admin?.role || "Owner"}
                  </p>
                </div>
              </div>
            </div>

            <div>
              <h3 className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                <KeyRound className="size-4 text-primary" /> Change Password
              </h3>
              <form onSubmit={handlePasswordChange} className="space-y-3">
                <Field label="Current Password">
                  <Input
                    type="password"
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                    placeholder="Current password"
                  />
                </Field>
                <Field label="New Password">
                  <Input
                    type="password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    placeholder="New password (min 6 chars)"
                  />
                </Field>
                <Field label="Confirm New Password">
                  <Input
                    type="password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="Confirm new password"
                  />
                </Field>

                {passError && <p className="text-xs text-destructive">{passError}</p>}
                {passSuccess && <p className="text-xs text-emerald-600 font-medium">{passSuccess}</p>}

                <Button type="submit" disabled={passSaving} className="w-full mt-2">
                  {passSaving ? "Updating Password..." : "Update Password"}
                </Button>
              </form>
            </div>
          </div>
        </Panel>

        {/* Server & Deployment Info Panel */}
        <Panel className="p-6">
          <div className="flex items-center gap-3 border-b border-border pb-4">
            <span className="flex size-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
              <Server className="size-5" />
            </span>
            <div>
              <h2 className="font-display text-lg font-semibold">Deployment & Environment</h2>
              <p className="text-xs text-muted-foreground">System architecture and live cloud endpoints</p>
            </div>
          </div>

          <div className="mt-4 grid gap-3 text-sm sm:grid-cols-2">
            <div className="rounded-md border border-border p-3">
              <p className="text-xs font-semibold text-muted-foreground">Application Name</p>
              <p className="font-medium text-foreground mt-0.5">Law Hub Admin Panel</p>
            </div>
            <div className="rounded-md border border-border p-3">
              <p className="text-xs font-semibold text-muted-foreground">Backend API</p>
              <p className="font-mono text-xs text-muted-foreground mt-0.5 truncate">
                https://lawconnect-admin.onrender.com
              </p>
            </div>
            <div className="rounded-md border border-border p-3">
              <p className="text-xs font-semibold text-muted-foreground">Database Storage</p>
              <p className="font-medium text-foreground mt-0.5">MongoDB Atlas (Persistent Collection)</p>
            </div>
            <div className="rounded-md border border-border p-3">
              <p className="text-xs font-semibold text-muted-foreground">External Legal Provider</p>
              <p className="font-medium text-foreground mt-0.5">Indian Kanoon API (api.indiankanoon.org)</p>
            </div>
          </div>
        </Panel>
      </div>
    </AdminShell>
  );
}
