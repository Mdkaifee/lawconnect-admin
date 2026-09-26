import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, Field } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Eye, EyeOff, CheckCircle2, XCircle, AlertCircle, RefreshCw, KeyRound, ShieldCheck } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/settings")({
  head: () => ({ meta: [{ title: "Settings — Admin" }] }),
  component: SettingsAdmin,
});

interface KanoonStatus {
  configured: boolean;
  status: "active" | "unconfigured" | "error";
  message: string;
  totalResultsFound?: number;
}

function SettingsAdmin() {
  const ready = useAdminGuard();

  // Indian Kanoon Status
  const [kanoonStatus, setKanoonStatus] = useState<KanoonStatus | null>(null);
  const [checkingKanoon, setCheckingKanoon] = useState(false);

  // Password Change Form
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showCurrent, setShowCurrent] = useState(false);
  const [showNew, setShowNew] = useState(false);
  const [passError, setPassError] = useState<string | null>(null);
  const [passSuccess, setPassSuccess] = useState(false);
  const [passBusy, setPassBusy] = useState(false);

  async function checkIntegrationStatus() {
    setCheckingKanoon(true);
    try {
      const res = await api<KanoonStatus>("/api/cases/integration-status");
      setKanoonStatus(res);
    } catch (err) {
      setKanoonStatus({
        configured: false,
        status: "error",
        message: err instanceof Error ? err.message : "Failed to connect to backend",
      });
    } finally {
      setCheckingKanoon(false);
    }
  }

  useEffect(() => {
    if (ready) {
      checkIntegrationStatus();
    }
  }, [ready]);

  async function handleChangePassword(e: React.FormEvent) {
    e.preventDefault();
    setPassError(null);
    setPassSuccess(false);

    if (newPassword.length < 6) {
      setPassError("New password must be at least 6 characters long.");
      return;
    }
    if (newPassword !== confirmPassword) {
      setPassError("New passwords do not match.");
      return;
    }

    setPassBusy(true);
    try {
      await api("/api/auth/admin/change-password", {
        method: "POST",
        body: { currentPassword, newPassword },
      });
      setPassSuccess(true);
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
    } catch (err) {
      setPassError(err instanceof Error ? err.message : "Failed to change password.");
    } finally {
      setPassBusy(false);
    }
  }

  return (
    <AdminShell title="System Settings" subtitle="Integration status, security credentials, and system diagnostics">
      <div className="space-y-6 max-w-3xl">
        {/* Indian Kanoon Integration Card */}
        <Panel className="p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <ShieldCheck className="size-5 text-primary" />
              <h2 className="font-display text-lg font-semibold">Indian Kanoon API Integration</h2>
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={checkIntegrationStatus}
              disabled={checkingKanoon}
              className="gap-1.5"
            >
              <RefreshCw className={`size-3.5 ${checkingKanoon ? "animate-spin" : ""}`} />
              Test Connection
            </Button>
          </div>

          <div className="border border-border rounded-lg p-4 bg-muted/20">
            {checkingKanoon ? (
              <p className="text-sm text-muted-foreground flex items-center gap-2">
                <RefreshCw className="size-4 animate-spin" /> Verifying Indian Kanoon connectivity...
              </p>
            ) : kanoonStatus ? (
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  {kanoonStatus.status === "active" ? (
                    <CheckCircle2 className="size-5 text-green-600" />
                  ) : kanoonStatus.status === "unconfigured" ? (
                    <AlertCircle className="size-5 text-amber-500" />
                  ) : (
                    <XCircle className="size-5 text-destructive" />
                  )}
                  <span className="font-semibold text-sm capitalize">{kanoonStatus.status}</span>
                </div>
                <p className="text-sm text-muted-foreground">{kanoonStatus.message}</p>
                {kanoonStatus.totalResultsFound !== undefined && (
                  <p className="text-xs text-muted-foreground">
                    Live Kanoon corpus index verified ({kanoonStatus.totalResultsFound.toLocaleString()} judgments reachable).
                  </p>
                )}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">Click "Test Connection" to verify Indian Kanoon status.</p>
            )}
          </div>
        </Panel>

        {/* Change Owner Password */}
        <Panel className="p-6">
          <div className="flex items-center gap-2 mb-4">
            <KeyRound className="size-5 text-primary" />
            <h2 className="font-display text-lg font-semibold">Change Owner Password</h2>
          </div>

          <form onSubmit={handleChangePassword} className="space-y-4 max-w-md">
            <Field label="Current Password">
              <div className="relative">
                <Input
                  type={showCurrent ? "text" : "password"}
                  value={currentPassword}
                  onChange={(e) => setCurrentPassword(e.target.value)}
                  placeholder="••••••••"
                  className="pr-10"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowCurrent(!showCurrent)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                >
                  {showCurrent ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
            </Field>

            <Field label="New Password">
              <div className="relative">
                <Input
                  type={showNew ? "text" : "password"}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="At least 6 characters"
                  className="pr-10"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowNew(!showNew)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                >
                  {showNew ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
                </button>
              </div>
            </Field>

            <Field label="Confirm New Password">
              <Input
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Repeat new password"
                required
              />
            </Field>

            {passError && <p className="text-sm text-destructive">{passError}</p>}
            {passSuccess && (
              <p className="text-sm text-green-600 flex items-center gap-1.5">
                <CheckCircle2 className="size-4" /> Password updated successfully!
              </p>
            )}

            <Button type="submit" disabled={passBusy}>
              {passBusy ? "Updating…" : "Update Password"}
            </Button>
          </form>
        </Panel>
      </div>
    </AdminShell>
  );
}
