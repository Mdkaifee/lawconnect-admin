import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { AppUser } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
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
import { Search, Trash2, Edit, Users, User, Mail, GraduationCap, Shield } from "lucide-react";
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

  const [editingUser, setEditingUser] = useState<AppUser | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // Edit Form State
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [college, setCollege] = useState("");
  const [headline, setHeadline] = useState("");
  const [newPassword, setNewPassword] = useState("");

  function load() {
    if (!ready) return;
    setLoading(true);
    setError(null);
    api<{ items: AppUser[] }>(`/api/users${query ? `?q=${query}` : ""}`)
      .then((res) => setItems(res.items || []))
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
      if (newPassword.trim()) {
        payload.password = newPassword.trim();
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
            onKeyDown={(e) => e.key === "Enter" && load()}
            placeholder="Search users by name, email or college/firm..."
            className="pl-9"
          />
        </div>
        <Button onClick={load} variant="secondary">
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
                  <th className="px-5 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {items.map((user) => (
                  <tr key={user._id} className="hover:bg-muted/30 transition-colors">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="flex size-9 shrink-0 items-center justify-center rounded-full bg-primary/10 font-bold text-primary text-sm">
                          {user.name ? user.name.slice(0, 2).toUpperCase() : "U"}
                        </div>
                        <div>
                          <p className="font-semibold text-card-foreground">{user.name}</p>
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
                    <td className="px-5 py-4 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <Button size="sm" variant="ghost" onClick={() => openEdit(user)}>
                          <Edit className="size-3.5 text-muted-foreground hover:text-foreground" />
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
    </AdminShell>
  );
}
