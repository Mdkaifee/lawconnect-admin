import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Pager } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { AppUser } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Ban, BadgeCheck, CheckCircle2, Edit, Search, Trash2 } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/users")({
  head: () => ({ meta: [{ title: "App Users — Admin" }] }),
  component: UsersAdmin,
});

function UsersAdmin() {
  const ready = useAdminGuard();
  const [items, setItems] = useState<AppUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const limit = 20;

  const [editingUser, setEditingUser] = useState<AppUser | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [statusUser, setStatusUser] = useState<AppUser | null>(null);
  const [saving, setSaving] = useState(false);

  // Edit Form State
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [college, setCollege] = useState("");
  const [headline, setHeadline] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [chatPlanEnabled, setChatPlanEnabled] = useState(false);
  const [chatPlanDurationMonths, setChatPlanDurationMonths] = useState(3);

  function load(nextPage = page) {
    if (!ready) return;
    setLoading(true);
    setError(null);
    const params = new URLSearchParams({ page: String(nextPage), limit: String(limit) });
    if (query) params.set("q", query);
    api<{ items: AppUser[]; total: number; page: number; chatPlanDurationMonths?: number }>(`/api/users?${params.toString()}`)
      .then((res) => {
        setItems(res.items || []);
        setTotal(res.total || 0);
        setPage(res.page || nextPage);
        setChatPlanDurationMonths(res.chatPlanDurationMonths || 3);
      })
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, [ready]);

  function openEdit(u: AppUser) {
    setEditingUser(u);
    setName(u.name || "");
    setEmail(u.email || "");
    setCollege(u.college || "");
    setHeadline(u.headline || "");
    setNewPassword("");
    setChatPlanEnabled(Boolean(u.isChatPaid));
  }

  async function saveUser() {
    if (!editingUser) return;
    setSaving(true);
    try {
      const payload: Record<string, any> = {
        name: name.trim(),
        email: email.trim(),
        college: college.trim(),
        headline: headline.trim(),
      };
      if (chatPlanEnabled !== Boolean(editingUser.isChatPaid)) {
        payload.chatPlanEnabled = chatPlanEnabled;
      }
      if (newPassword.trim()) {
        payload["password"] = newPassword.trim();
      }

      await api(`/api/users/${editingUser._id}`, { method: "PUT", body: payload });
      setEditingUser(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to update user");
    } finally {
      setSaving(false);
    }
  }

  async function confirmDelete() {
    if (!deletingId) return;
    try {
      await api(`/api/users/${deletingId}`, { method: "DELETE" });
      setDeletingId(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to delete user");
    }
  }

  async function toggleUserStatus() {
    if (!statusUser) return;
    try {
      await api(`/api/users/${statusUser._id}`, {
        method: "PUT",
        body: { blocked: !statusUser.blocked },
      });
      setStatusUser(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to update user status");
    }
  }

  return (
    <AdminShell
      title="App Users & Advocates"
      subtitle="View, manage and monitor registered advocates, law students and public users"
    >
      {/* Search Bar */}
      <div className="mb-6 flex flex-wrap items-center gap-3">
        <div className="relative min-w-64 flex-1">
          <Search className="absolute left-3 top-2.5 size-4 text-muted-foreground" />
          <Input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") load(1);
            }}
            placeholder="Search users by name, email or college/firm..."
            className="pl-9"
          />
        </div>
        <Button onClick={() => load(1)} variant="secondary">
          Search
        </Button>
      </div>

      {/* Main List */}
      {loading ? (
        <StateBlock message="Loading registered app users..." loading />
      ) : error ? (
        <StateBlock message={error} onRetry={load} />
      ) : items.length === 0 ? (
        <StateBlock
          message="No app users found. When advocates or law students sign up on the Rishikesh Law Hub mobile app, they will automatically appear here with full account details."
        />
      ) : (
        <div className="rounded-lg border border-border bg-card overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-border bg-muted/40 text-xs uppercase font-semibold text-muted-foreground">
                <tr>
                  <th className="px-5 py-3.5">User</th>
                  <th className="px-5 py-3.5">Email</th>
                  <th className="px-5 py-3.5">Designation / College</th>
                  <th className="px-5 py-3.5">Joined Date</th>
                  <th className="px-5 py-3.5">Chat Plan</th>
                  <th className="px-5 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {items.map((user) => (
                  <tr key={user._id} className="hover:bg-muted/30 transition-colors">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        {user.photoUrl ? (
                          <img
                            src={user.photoUrl}
                            alt={user.name || "User"}
                            className="size-9 shrink-0 rounded-full object-cover"
                          />
                        ) : (
                          <div className="flex size-9 shrink-0 items-center justify-center rounded-full bg-primary/10 font-bold text-primary text-sm">
                            {user.name ? user.name.slice(0, 2).toUpperCase() : "U"}
                          </div>
                        )}
                        <div>
                          <div className="flex items-center gap-2">
                            <p className="font-semibold text-card-foreground">{user.name}</p>
                            {user.blocked && (
                              <span className="rounded-full bg-destructive/10 px-2 py-0.5 text-[10px] font-semibold uppercase text-destructive">
                                Deactivated
                              </span>
                            )}
                          </div>
                          {user.headline && (
                            <p className="text-xs text-muted-foreground">{user.headline}</p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-muted-foreground font-mono text-xs">
                      {user.email}
                    </td>
                    <td className="px-5 py-4 text-muted-foreground">
                      {user.college || <span className="italic text-muted-foreground/60">—</span>}
                    </td>
                    <td className="px-5 py-4 text-xs text-muted-foreground">
                      {user.createdAt ? new Date(user.createdAt).toLocaleDateString() : "N/A"}
                    </td>
                    <td className="px-5 py-4 text-xs">
                      {user.isChatPaid ? (
                        <span className="inline-flex items-center gap-1.5 font-semibold text-teal-600">
                          <BadgeCheck className="size-4" />
                          Paid{user.chatPaidUntil ? ` until ${new Date(user.chatPaidUntil).toLocaleDateString()}` : ""}
                        </span>
                      ) : (
                        <span className="text-muted-foreground">Free</span>
                      )}
                    </td>
                    <td className="px-5 py-4 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <Button size="sm" variant="ghost" onClick={() => openEdit(user)}>
                          <Edit className="size-3.5 text-muted-foreground hover:text-foreground" />
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => setStatusUser(user)}
                          className={user.blocked ? "text-emerald-600 hover:bg-emerald-50" : "text-amber-600 hover:bg-amber-50"}
                        >
                          {user.blocked ? <CheckCircle2 className="size-3.5" /> : <Ban className="size-3.5" />}
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => setDeletingId(user._id)}
                          className="text-destructive hover:bg-destructive/10"
                        >
                          <Trash2 className="size-3.5" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="border-t border-border px-5 pb-4">
            <Pager page={page} limit={limit} total={total} onPageChange={load} />
          </div>
        </div>
      )}

      {/* Edit User Modal */}
      {editingUser && (
        <Dialog open={Boolean(editingUser)} onOpenChange={() => setEditingUser(null)}>
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle className="text-lg font-display">Edit User Profile</DialogTitle>
            </DialogHeader>

            <div className="space-y-3 py-2 text-sm">
              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Full Name</label>
                <Input value={name} onChange={(e) => setName(e.target.value)} className="mt-1" />
              </div>

              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Email Address</label>
                <Input value={email} onChange={(e) => setEmail(e.target.value)} className="mt-1" />
              </div>

              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">College / Law Firm</label>
                <Input value={college} onChange={(e) => setCollege(e.target.value)} placeholder="e.g. Faculty of Law, DU" className="mt-1" />
              </div>

              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Headline / Bio</label>
                <Input value={headline} onChange={(e) => setHeadline(e.target.value)} placeholder="e.g. Advocate, High Court" className="mt-1" />
              </div>

              <div className="flex items-start gap-3 rounded-md border border-border p-3">
                <Checkbox
                  id="chat-plan-enabled"
                  checked={chatPlanEnabled}
                  onCheckedChange={(checked) => setChatPlanEnabled(checked === true)}
                  className="mt-0.5"
                />
                <div className="space-y-1">
                  <label htmlFor="chat-plan-enabled" className="cursor-pointer font-medium">Paid chat plan</label>
                  <p className="text-xs text-muted-foreground">
                    {chatPlanEnabled
                      ? `Enables unlimited outgoing chat for ${chatPlanDurationMonths} months from the current expiry.`
                      : "Unchecking removes paid chat access immediately."}
                  </p>
                  {editingUser.isChatPaid && editingUser.chatPaidUntil && (
                    <p className="text-xs text-muted-foreground">
                      Current expiry: {new Date(editingUser.chatPaidUntil).toLocaleDateString()}
                    </p>
                  )}
                </div>
              </div>

              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Reset Password (Optional)</label>
                <Input
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="Leave blank to keep current password"
                  className="mt-1"
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setEditingUser(null)}>
                Cancel
              </Button>
              <Button onClick={saveUser} disabled={saving || !name.trim() || !email.trim()}>
                {saving ? "Saving..." : "Save Changes"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* Delete Confirmation */}
      <AlertDialog open={Boolean(deletingId)} onOpenChange={() => setDeletingId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure you want to delete this user account?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete the user account and associated profile records.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Delete User
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <AlertDialog open={Boolean(statusUser)} onOpenChange={() => setStatusUser(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {statusUser?.blocked ? "Reactivate this user account?" : "Deactivate this user account?"}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {statusUser?.blocked
                ? "The user will be able to sign in again."
                : "The user will be blocked from signing in until you reactivate the account."}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={toggleUserStatus}
              className={statusUser?.blocked ? "bg-emerald-600 text-white hover:bg-emerald-700" : "bg-amber-600 text-white hover:bg-amber-700"}
            >
              {statusUser?.blocked ? "Reactivate" : "Deactivate"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  );
}
