import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Field } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { LegalUpdate } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
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
import { Plus, Search, Trash2, Edit } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/updates")({
  head: () => ({ meta: [{ title: "Legal Updates — Admin" }] }),
  component: UpdatesAdmin,
});

const EMPTY_UPDATE: Partial<LegalUpdate> = {
  title: "",
  body: "",
  source: "Official Gazette / Supreme Court",
  court: "Supreme Court",
  badge: "SC",
  published: true,
};

function UpdatesAdmin() {
  const ready = useAdminGuard();
  const [items, setItems] = useState<LegalUpdate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [courtFilter, setCourtFilter] = useState("All");

  const [editing, setEditing] = useState<Partial<LegalUpdate> | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  function load() {
    if (!ready) return;
    setLoading(true);
    setError(null);
    const params = new URLSearchParams({ all: "true" });
    if (query) params.set("q", query);
    if (courtFilter !== "All") params.set("court", courtFilter);

    api<{ items: LegalUpdate[] }>(`/api/updates?${params.toString()}`)
      .then((res) => setItems(res.items))
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, [ready, courtFilter]);

  async function save() {
    if (!editing || !editing.title) return;
    setSaving(true);
    try {
      if (editing._id) {
        await api(`/api/updates/${editing._id}`, { method: "PUT", body: editing });
      } else {
        await api("/api/updates", { method: "POST", body: editing });
      }
      setEditing(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to save update");
    } finally {
      setSaving(false);
    }
  }

  async function confirmDelete() {
    if (!deletingId) return;
    try {
      await api(`/api/updates/${deletingId}`, { method: "DELETE" });
      setDeletingId(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to delete update");
    }
  }

  return (
    <AdminShell
      title="Legal Updates & Notifications"
      subtitle="Publish verified court developments, gazette notifications, and rules"
      actions={
        <Button onClick={() => setEditing({ ...EMPTY_UPDATE })} className="gap-2">
          <Plus className="size-4" /> Add Legal Update
        </Button>
      }
    >
      <div className="mb-4 flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-[240px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
          <Input
            placeholder="Search updates by headline or source..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && load()}
            className="pl-9"
          />
        </div>
        <select
          value={courtFilter}
          onChange={(e) => setCourtFilter(e.target.value)}
          className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
        >
          <option value="All">All Courts</option>
          <option value="Supreme Court">Supreme Court</option>
          <option value="High Court">High Court</option>
          <option value="Other">Other / Gazette</option>
        </select>
        <Button variant="outline" onClick={load}>
          Search
        </Button>
      </div>

      <StateBlock loading={loading} error={error} empty={!loading && items.length === 0} emptyText="No updates found." />

      {!loading && items.length > 0 ? (
        <Panel className="divide-y divide-border">
          {items.map((u) => (
            <div key={u._id} className="flex flex-wrap items-center justify-between gap-4 p-4 hover:bg-muted/30">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">
                    {u.court || "Other"}
                  </span>
                  <span className="text-xs text-muted-foreground">{u.source}</span>
                </div>
                <h3 className="mt-1 font-display text-base font-semibold">{u.title}</h3>
                {u.body ? <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">{u.body}</p> : null}
              </div>
              <div className="flex items-center gap-2">
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

      {/* Edit / Create Dialog */}
      <Dialog open={Boolean(editing)} onOpenChange={(o) => !o && setEditing(null)}>
        <DialogContent className="max-h-[90vh] overflow-y-auto max-w-2xl">
          <DialogHeader>
            <DialogTitle>{editing?._id ? "Edit Legal Update" : "Add Legal Update"}</DialogTitle>
          </DialogHeader>
          {editing ? (
            <div className="space-y-4 py-2">
              <Field label="Headline / Title *">
                <Input
                  value={editing.title ?? ""}
                  onChange={(e) => setEditing({ ...editing, title: e.target.value })}
                  placeholder="e.g. SC seeks response on Waqf Amendment plea"
                />
              </Field>
              <div className="grid gap-4 sm:grid-cols-2">
                <Field label="Source">
                  <Input
                    value={editing.source ?? ""}
                    onChange={(e) => setEditing({ ...editing, source: e.target.value })}
                    placeholder="e.g. Supreme Court of India / LiveLaw"
                  />
                </Field>
                <Field label="Court">
                  <select
                    value={editing.court ?? "Supreme Court"}
                    onChange={(e) => setEditing({ ...editing, court: e.target.value })}
                    className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  >
                    <option value="Supreme Court">Supreme Court</option>
                    <option value="High Court">High Court</option>
                    <option value="Other">Other</option>
                  </select>
                </Field>
              </div>
              <Field label="Body / Description">
                <Textarea
                  rows={4}
                  value={editing.body ?? ""}
                  onChange={(e) => setEditing({ ...editing, body: e.target.value })}
                  placeholder="Details of the update or notification..."
                />
              </Field>
              <Field label="Source Link (URL)">
                <Input
                  value={editing.url ?? ""}
                  onChange={(e) => setEditing({ ...editing, url: e.target.value })}
                  placeholder="https://..."
                />
              </Field>
              <div className="flex items-center justify-between pt-2">
                <span className="text-sm font-medium">Published in App</span>
                <Switch
                  checked={editing.published ?? true}
                  onCheckedChange={(val) => setEditing({ ...editing, published: val })}
                />
              </div>
            </div>
          ) : null}
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditing(null)}>
              Cancel
            </Button>
            <Button onClick={save} disabled={saving || !editing?.title}>
              {saving ? "Saving…" : "Save Update"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Alert */}
      <AlertDialog open={Boolean(deletingId)} onOpenChange={(o) => !o && setDeletingId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Legal Update</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete this legal update?
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-destructive text-destructive-foreground">
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  );
}
