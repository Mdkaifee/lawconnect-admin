import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api, getApiBase, setApiBase } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  ShieldCheck,
  Server,
  KeyRound,
  CheckCircle2,
  XCircle,
  RefreshCw,
  ExternalLink,
  Lock,
} from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/settings")({
  head: () => ({ meta: [{ title: "Settings & System Diagnostics — Admin" }] }),
  component: SettingsAdmin,
});

function SettingsAdmin() {
  const ready = useAdminGuard();
  const [apiUrl, setApiUrl] = useState("");
  const [apiSaved, setApiSaved] = useState(false);

  // Kanoon Status State
  const [kanoonChecking, setKanoonChecking] = useState(false);
  const [kanoonResult, setKanoonResult] = useState<any | null>(null);

  // Health State
  const [health, setHealth] = useState<any | null>(null);

  // Password Change State
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passwordMsg, setPasswordMsg] = useState<{ type: "success" | "error"; text: string } | null>(null);
  const [changingPassword, setChangingPassword] = useState(false);

  useEffect(() => {
    setApiUrl(getApiBase());
    checkHealth();
    testKanoon();
  }, [ready]);

  function saveApiAddress() {
    if (!apiUrl.trim()) return;
    setApiBase(apiUrl.trim());
    setApiSaved(true);
    setTimeout(() => setApiSaved(false), 2500);
    checkHealth();
  }

  function resetDefaultApi() {
    const def = "https://lawconnect-admin.onrender.com";
    setApiUrl(def);
    setApiBase(def);
    setApiSaved(true);
    setTimeout(() => setApiSaved(false), 2500);
    checkHealth();
  }

  async function checkHealth() {
    try {
      const res = await api<any>("/health", { auth: false });
      setHealth(res);
    } catch {
      setHealth({ ok: false, error: "Server unreachable" });
    }
  }

  async function testKanoon() {
    setKanoonChecking(true);
    try {
      const res = await api<any>("/api/cases/integration-status");
      setKanoonResult(res);
    } catch (e) {
      setKanoonResult({
        configured: false,
        status: "offline",
        message: e instanceof Error ? e.message : "Failed to reach Kanoon proxy",
      });
    } finally {
      setKanoonChecking(false);
    }
  }

  async function changePassword() {
    if (!currentPassword || !newPassword) {
      setPasswordMsg({ type: "error", text: "Please enter current and new password." });
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordMsg({ type: "error", text: "New passwords do not match." });
      return;
    }

    setChangingPassword(true);
    setPasswordMsg(null);
    try {
      await api("/api/auth/change-password", {
        method: "POST",
        body: { currentPassword, newPassword },
      });
      setPasswordMsg({ type: "success", text: "Admin password updated successfully." });
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
    } catch (e) {
      setPasswordMsg({
        type: "error",
        text: e instanceof Error ? e.message : "Failed to update password",
      });
    } finally {
      setChangingPassword(false);
    }
  }

  return (
    <AdminShell
      title="Settings & System Diagnostics"
      subtitle="Configure API routing, verify Indian Kanoon connectivity, and manage administrative security"
    >
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Backend API Configuration */}
        <div className="rounded-lg border border-border bg-card p-6 shadow-sm">
          <div className="flex items-center gap-2 mb-3">
            <Server className="size-5 text-primary" />
            <h2 className="font-display text-lg font-semibold">Backend API Endpoint</h2>
          </div>
          <p className="text-xs text-muted-foreground mb-4">
            The target server URL used by this admin dashboard and mobile client requests.
          </p>

          <div className="space-y-3">
            <div>
              <label className="text-xs font-semibold uppercase text-muted-foreground">Active Server URL</label>
              <Input
                value={apiUrl}
                onChange={(e) => setApiUrl(e.target.value)}
                placeholder="https://lawconnect-admin.onrender.com"
                className="mt-1 font-mono text-xs"
              />
            </div>

            <div className="flex items-center justify-between pt-1">
              <Button size="sm" variant="outline" onClick={resetDefaultApi} className="text-xs">
                Reset to Default Live URL
              </Button>
              <Button size="sm" onClick={saveApiAddress} className="text-xs bg-primary">
                {apiSaved ? "Saved!" : "Save Server Address"}
              </Button>
            </div>

            {health && (
              <div className="mt-4 rounded-lg border border-border bg-muted/20 p-3 text-xs flex items-center justify-between">
                <span className="text-muted-foreground">API Health Check:</span>
                <span className={`font-semibold flex items-center gap-1 ${health.ok ? "text-green-600 dark:text-green-400" : "text-destructive"}`}>
                  {health.ok ? <CheckCircle2 className="size-3.5" /> : <XCircle className="size-3.5" />}
                  {health.ok ? "Online & Healthy" : "Offline / Unreachable"}
                </span>
              </div>
            )}
          </div>
        </div>

        {/* Indian Kanoon API Status */}
        <div className="rounded-lg border border-border bg-card p-6 shadow-sm">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <ShieldCheck className="size-5 text-secondary-foreground" />
              <h2 className="font-display text-lg font-semibold">Indian Kanoon API Integration</h2>
            </div>
            <Button
              size="sm"
              variant="outline"
              onClick={testKanoon}
              disabled={kanoonChecking}
              className="gap-1.5 text-xs"
            >
              <RefreshCw className={`size-3.5 ${kanoonChecking ? "animate-spin" : ""}`} />
              {kanoonChecking ? "Testing..." : "Test Connection"}
            </Button>
          </div>

          <p className="text-xs text-muted-foreground mb-4">
            Backend-only integration with <code className="bg-muted px-1 py-0.5 rounded font-mono">api.indiankanoon.org</code> for Indian court judgments and bare legislation search.
          </p>

          <div className="space-y-3">
            <div className="rounded-lg border border-border bg-muted/20 p-4 space-y-2 text-xs">
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Integration Mode:</span>
                <span className="font-semibold text-foreground">Backend-Only Token Proxy (Secure)</span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Connection Status:</span>
                <span className={`font-semibold flex items-center gap-1 ${
                  kanoonResult?.status === "active" || kanoonResult?.status === "mock_mode" || kanoonResult?.configured
                    ? "text-green-600 dark:text-green-400"
                    : "text-amber-500"
                }`}>
                  {kanoonResult?.status === "active" || kanoonResult?.configured ? (
                    <CheckCircle2 className="size-3.5" />
                  ) : (
                    <XCircle className="size-3.5" />
                  )}
                  {kanoonResult?.status?.toUpperCase() || (kanoonChecking ? "CHECKING..." : "READY")}
                </span>
              </div>

              {kanoonResult?.message && (
                <div className="mt-2 text-muted-foreground border-t border-border/60 pt-2">
                  {kanoonResult.message}
                </div>
              )}
            </div>

            <a
              href="https://api.indiankanoon.org/documentation/"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1 text-xs text-primary hover:underline mt-2"
            >
              Review Official Kanoon API Docs <ExternalLink className="size-3" />
            </a>
          </div>
        </div>

        {/* Admin Password Change */}
        <div className="rounded-lg border border-border bg-card p-6 shadow-sm">
          <div className="flex items-center gap-2 mb-3">
            <Lock className="size-5 text-primary" />
            <h2 className="font-display text-lg font-semibold">Change Admin Password</h2>
          </div>
          <p className="text-xs text-muted-foreground mb-4">
            Update your administrative login credentials.
          </p>

          <div className="space-y-3">
            <div>
              <label className="text-xs font-semibold uppercase text-muted-foreground">Current Password</label>
              <Input
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                className="mt-1 text-sm"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">New Password</label>
                <Input
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="mt-1 text-sm"
                />
              </div>
              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Confirm New Password</label>
                <Input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="mt-1 text-sm"
                />
              </div>
            </div>

            {passwordMsg && (
              <p className={`text-xs font-medium ${passwordMsg.type === "success" ? "text-green-600 dark:text-green-400" : "text-destructive"}`}>
                {passwordMsg.text}
              </p>
            )}

            <Button
              onClick={changePassword}
              disabled={changingPassword || !currentPassword || !newPassword}
              className="mt-2 text-xs bg-primary"
            >
              {changingPassword ? "Updating..." : "Update Password"}
            </Button>
          </div>
        </div>
      </div>
    </AdminShell>
  );
}
