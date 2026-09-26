import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, Field } from "@/components/admin/DataPanel";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { useAdminGuard } from "@/lib/useAdmin";
import { api, getApiBase, setApiBase, setToken } from "@/lib/api";
import { KeyRound, Server, User, Shield, LogOut, CheckCircle2 } from "lucide-react";
import { useState } from "react";

export const Route = createFileRoute("/admin/settings")({
  component: SettingsPage,
});

function SettingsPage() {
  const ready = useAdminGuard();
  const navigate = useNavigate();

  // Password change state
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordSuccess, setPasswordSuccess] = useState(false);
  const [passwordBusy, setPasswordBusy] = useState(false);

  // Server URL state
  const [apiUrl, setApiUrl] = useState(getApiBase());
  const [apiUrlSaved, setApiUrlSaved] = useState(false);

  async function handlePasswordChange(e: React.FormEvent) {
    e.preventDefault();
    setPasswordError(null);
    setPasswordSuccess(false);

    if (newPassword !== confirmPassword) {
      setPasswordError("New passwords do not match");
      return;
    }
    if (newPassword.length < 6) {
      setPasswordError("New password must be at least 6 characters");
      return;
    }

    setPasswordBusy(true);
    try {
      await api("/api/auth/admin/change-password", {
        method: "POST",
        body: { currentPassword, newPassword },
      });
      setPasswordSuccess(true);
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
    } catch (err) {
      setPasswordError(err instanceof Error ? err.message : "Password change failed");
    } finally {
      setPasswordBusy(false);
    }
  }

  function handleSaveApiUrl(e: React.FormEvent) {
    e.preventDefault();
    setApiBase(apiUrl);
    setApiUrlSaved(true);
    setTimeout(() => setApiUrlSaved(false), 3000);
  }

  function handleLogout() {
    setToken(null);
    navigate({ to: "/", replace: true });
  }

  if (!ready) return null;

  return (
    <AdminShell
      title="Settings & Account"
      subtitle="Manage your admin security credentials, server endpoints, and profile"
    >
      <div className="max-w-3xl space-y-6">
        {/* Profile Card */}
        <Panel className="p-6">
          <div className="flex items-center gap-4">
            <div className="flex size-14 items-center justify-center rounded-full bg-accent text-accent-foreground">
              <User className="size-7" />
            </div>
            <div>
              <h2 className="font-display text-xl">Rishikesh Yadav</h2>
              <p className="text-sm text-muted-foreground flex items-center gap-1 mt-0.5">
                <Shield className="size-3.5 text-primary" /> Administrator / Owner Access
              </p>
            </div>
          </div>
        </Panel>

        {/* Change Password */}
        <Panel className="p-6">
          <div className="mb-4 flex items-center gap-2">
            <KeyRound className="size-5 text-primary" />
            <h3 className="font-display text-lg font-semibold">Change Admin Password</h3>
          </div>

          <form onSubmit={handlePasswordChange} className="space-y-4 max-w-md">
            <Field label="Current Password">
              <Input
                type="password"
                required
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                placeholder="Enter current password"
              />
            </Field>

            <Field label="New Password">
              <Input
                type="password"
                required
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="Minimum 6 characters"
              />
            </Field>

            <Field label="Confirm New Password">
              <Input
                type="password"
                required
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Re-enter new password"
              />
            </Field>

            {passwordError ? <p className="text-sm text-destructive">{passwordError}</p> : null}
            {passwordSuccess ? (
              <p className="flex items-center gap-1.5 text-sm text-emerald-600 font-medium">
                <CheckCircle2 className="size-4" /> Password changed successfully!
              </p>
            ) : null}

            <Button type="submit" disabled={passwordBusy}>
              {passwordBusy ? "Updating..." : "Update Password"}
            </Button>
          </form>
        </Panel>

        {/* Backend API Configuration */}
        <Panel className="p-6">
          <div className="mb-4 flex items-center gap-2">
            <Server className="size-5 text-primary" />
            <h3 className="font-display text-lg font-semibold">Backend API Endpoint</h3>
          </div>

          <form onSubmit={handleSaveApiUrl} className="space-y-4 max-w-md">
            <Field label="Server Base URL">
              <Input
                value={apiUrl}
                onChange={(e) => setApiUrl(e.target.value)}
                placeholder="https://lawconnect-admin.onrender.com"
              />
            </Field>

            {apiUrlSaved ? (
              <p className="flex items-center gap-1.5 text-sm text-emerald-600 font-medium">
                <CheckCircle2 className="size-4" /> Endpoint saved.
              </p>
            ) : null}

            <Button type="submit" variant="secondary">
              Save Server URL
            </Button>
          </form>
        </Panel>

        {/* Log Out Box */}
        <Panel className="p-6 border-destructive/30">
          <h3 className="font-display text-lg font-semibold text-destructive mb-2">Session Control</h3>
          <p className="text-sm text-muted-foreground mb-4">
            Sign out of the Rishikesh Law Hub admin panel from this device.
          </p>

          <AlertDialog>
            <AlertDialogTrigger asChild>
              <Button variant="destructive" className="gap-2">
                <LogOut className="size-4" /> Log out of Admin Panel
              </Button>
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>Confirm Log Out</AlertDialogTitle>
                <AlertDialogDescription>
                  Are you sure you want to end your admin session?
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Cancel</AlertDialogCancel>
                <AlertDialogAction onClick={handleLogout} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                  Log out
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        </Panel>
      </div>
    </AdminShell>
  );
}
