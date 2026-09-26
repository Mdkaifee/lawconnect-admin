import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock } from "@/components/admin/DataPanel";
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
} from "@/components/ui/alert-dialog";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { AppUser } from "@/lib/types";
import { Search, Trash2, ShieldAlert, ShieldCheck, UserCheck } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/users")({
  component: UsersPage,
});

function UsersPage() {
  const ready = useAdminGuard();
  const [users, setUsers] = useState<AppUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [deleteId, setDeleteId] = useState<string | null>(null);

  async function loadUsers() {
    try {
      setLoading(true);
      setError(null);
      const params = new URLSearchParams();
      if (search.trim()) params.set("q", search.trim());
      const res = await api<{ items: AppUser[] }>(`/api/users?${params.toString()}`);
      setUsers(res.items || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load users");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!ready) return;
    loadUsers();
  }, [ready]);

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    loadUsers();
  }

  async function toggleBlock(user: AppUser) {
    try {
      const updated = !user.blocked;
      await api(`/api/users/${user._id}`, {
        method: "PUT",
        body: { blocked: updated },
      });
      setUsers((prev) =>
        prev.map((u) => (u._id === user._id ? { ...u, blocked: updated } : u)),
      );
    } catch (err) {
      alert(err instanceof Error ? err.message : "Failed to update user status");
    }
  }

  async function handleDelete() {
    if (!deleteId) return;
    try {
      await api(`/api/users/${deleteId}`, { method: "DELETE" });
      setDeleteId(null);
      await loadUsers();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Failed to delete user");
    }
  }

  return (
    <AdminShell
      title="App Users"
      subtitle="View, monitor and manage student and advocate mobile app accounts"
    >
      <div className="space-y-4">
        {/* Search */}
        <form onSubmit={handleSearch} className="flex gap-2 max-w-md">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
            <Input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search user by name or email..."
              className="pl-9"
            />
          </div>
          <Button type="submit" variant="secondary">Search</Button>
        </form>

        <StateBlock
          loading={loading}
          error={error}
          empty={!loading && users.length === 0}
          emptyText="No registered users found."
        />

        {!loading && users.length > 0 ? (
          <div className="space-y-3">
            {users.map((u) => (
              <Panel key={u._id} className="p-4 transition hover:border-primary/40">
                <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
                  <div className="space-y-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="font-display text-base font-semibold">{u.name}</h3>
                      {u.blocked ? (
                        <span className="rounded bg-destructive/10 px-2 py-0.5 text-xs font-semibold text-destructive flex items-center gap-1">
                          <ShieldAlert className="size-3" /> Blocked
                        </span>
                      ) : (
                        <span className="rounded bg-emerald-500/10 px-2 py-0.5 text-xs font-semibold text-emerald-600 flex items-center gap-1">
                          <UserCheck className="size-3" /> Active
                        </span>
                      )}
                    </div>

                    <p className="text-xs text-muted-foreground">{u.email}</p>

                    {u.headline || u.college ? (
                      <p className="text-xs text-foreground/70">
                        {[u.headline, u.college].filter(Boolean).join(" • ")}
                      </p>
                    ) : null}

                    {u.createdAt ? (
                      <p className="text-[11px] text-muted-foreground">
                        Joined: {new Date(u.createdAt).toLocaleDateString()}
                      </p>
                    ) : null}
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <Button
                      variant={u.blocked ? "outline" : "secondary"}
                      size="sm"
                      onClick={() => toggleBlock(u)}
                      className="gap-1 text-xs"
                    >
                      {u.blocked ? (
                        <>
                          <ShieldCheck className="size-3.5 text-emerald-600" /> Unblock
                        </>
                      ) : (
                        <>
                          <ShieldAlert className="size-3.5 text-destructive" /> Block
                        </>
                      )}
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setDeleteId(u._id)}
                      className="text-destructive hover:bg-destructive/10"
                    >
                      <Trash2 className="size-3.5" />
                    </Button>
                  </div>
                </div>
              </Panel>
            ))}
          </div>
        ) : null}
      </div>

      {/* Delete User Confirmation */}
      <AlertDialog open={!!deleteId} onOpenChange={(open) => !open && setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete User Account</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete this user? All their bookmarks and notes will also be removed.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Delete User
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  );
}
