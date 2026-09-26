import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Field } from "@/components/admin/DataPanel";
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
import { Search, Trash2, Edit, Ban, CheckCircle } from "lucide-react";
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

  const [editing, setEditing] = useState<Partial<AppUser> | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  function load() {
    if (!ready) return;
    setLoading(true);
    setError(null);
    const params = new URLSearchParams();
    if (query) params.set("q", query);

    api<{ items: AppUser[] }>(`/api/users?${params.toString()}`)
      .then((res) => setItems(res.items))
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, [ready]);

  async function toggleBlock(user: AppUser) {
    try {
      await api(`/api/users/${user._id}`, {
        method: "PUT",
        body: { blocked: !user.blocked },
      });
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to update user");
    }
  }

  async function saveUser() {
    if (!editing || !editing._id) return;
    setSaving(true);
    try {
      await api(`/api/users/${editing._id}`, {
        method: "PUT",
        body: editing,
      });
      setEditing(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to save user");
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
    <AdminShell title="App Users" subtitle="Manage registered law students, advocates and their access">
      <div className="mb-4 flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-[240px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
          <Input
            placeholder="Search by name or email address..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && load()}
            className="pl-9"
          />
        </div>
        <Button variant="outline" onClick={load}>
          Search
        </Button>
      </div>

      <StateBlock loading={loading} error={error} empty={!loading && items.length === 0} emptyText="No users found." />

      {!loading && items.length > 0 ? (
        <Panel className="divide-y divide-border">
          {items.map((u) => (
            <div key={u._id} className="flex flex-wrap items-center justify-between gap-4 p-4 hover:bg-muted/30">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <h3 className="font-display text-base font-semibold">{u.name}</h3>
                  {u.blocked && (
                    <span className="rounded bg-destructive/10 px-2 py-0.5 text-xs font-semibold text-destructive">
                      Blocked
                    </span>
                  )}
                </div>
                <p className="text-xs text-muted-foreground">{u.email}</p>
                {u.college && <p className="text-xs text-accent-foreground mt-0.5">{u.college}</p>}
              </div>
              <div className="flex items-center gap-2">
                <Button
                  size="sm"
                  variant={u.blocked ? "secondary" : "outline"}
                  onClick={() => toggleBlock(u)}
                  title={u.blocked ? "Unblock user" : "Block user"}
                >
                  {u.blocked ? <CheckCircle className="size-4 text-green-600" /> : <Ban className="size-4 text-amber-600" />}
                </Button>
                <Button size="sm" variant="outline" onClick={() => setEditing(u)}>
                  <Edit className="size-4" />
                </Button>
                <Button size="sm" variant="ghost" className="text-destructive" onClick={() => setDeletingId(u._id)}>
                  <Trash2 className="size-4" />
                </Button>
              </div>
            </div>
          ))}
        </Panel>
      ) : null}

      {/* Edit User Dialog */}
      <Dialog open={Boolean(editing)} onOpenChange={(o) => !o && setEditing(null)}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Edit User Profile</DialogTitle>
          </DialogHeader>
          {editing ? (
            <div className="space-y-4 py-2">
              <Field label="Full Name">
                <Input
                  value={editing.name ?? ""}
                  onChange={(e) => setEditing({ ...editing, name: e.target.value })}
                />
              </Field>
              <Field label="Email Address">
                <Input
                  value={editing.email ?? ""}
                  onChange={(e) => setEditing({ ...editing, email: e.target.value })}
                />
              </Field>
              <Field label="Law School / College">
                <Input
                  value={editing.college ?? ""}
                  onChange={(e) => setEditing({ ...editing, college: e.target.value })}
                  placeholder="e.g. Galgotias University"
                />
              </Field>
              <Field label="Headline">
                <Input
                  value={editing.headline ?? ""}
                  onChange={(e) => setEditing({ ...editing, headline: e.target.value })}
                  placeholder="e.g. Law Student | Future Advocate"
                />
              </Field>
            </div>
          ) : null}
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditing(null)}>
              Cancel
            </Button>
            <Button onClick={saveUser} disabled={saving}>
              {saving ? "Saving…" : "Save Changes"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete User Dialog */}
      <AlertDialog open={Boolean(deletingId)} onOpenChange={(o) => !o && setDeletingId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete User Account</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to permanently delete this user account?
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-destructive text-destructive-foreground">
              Delete User
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  );
}
