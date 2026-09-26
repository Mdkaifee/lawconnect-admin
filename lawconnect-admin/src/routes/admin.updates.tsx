import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Field } from "@/components/admin/DataPanel";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
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
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { LegalUpdate } from "@/lib/types";
import { Plus, Trash2, Edit3, ExternalLink } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/updates")({
  component: UpdatesPage,
});

const COURTS = ["All", "Supreme Court", "High Court", "Other"];

function UpdatesPage() {
  const ready = useAdminGuard();
  const [updates, setUpdates] = useState<LegalUpdate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [courtFilter, setCourtFilter] = useState("All");

  // Dialogs
  const [editItem, setEditItem] = useState<Partial<LegalUpdate> | null>(null);
  const [isNew, setIsNew] = useState(false);
  const [saveBusy, setSaveBusy] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  async function loadUpdates() {
    try {
      setLoading(true);
      setError(null);
      const params = new URLSearchParams({ all: "true" });
      if (courtFilter !== "All") params.set("court", courtFilter);
      const res = await api<{ items: LegalUpdate[]; total: number }>(`/api/updates?${params.toString()}`);
      setUpdates(res.items || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load updates");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!ready) return;
    loadUpdates();
  }, [ready, courtFilter]);

  function openCreate() {
    setIsNew(true);
    setEditItem({
      title: "",
      body: "",
      source: "LiveLaw",
      court: "Supreme Court",
      badge: "SC",
      url: "",
      publishedAt: new Date().toISOString(),
      published: true,
    });
  }

  function openEdit(item: LegalUpdate) {
    setIsNew(false);
    setEditItem({ ...item });
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!editItem || !editItem.title) return;
    setSaveBusy(true);
    try {
      if (isNew) {
        await api("/api/updates", { method: "POST", body: editItem });
      } else {
        await api(`/api/updates/${editItem._id}`, { method: "PUT", body: editItem });
      }
      setEditItem(null);
      await loadUpdates();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Save failed");
    } finally {
      setSaveBusy(false);
    }
  }

  async function handleDelete() {
    if (!deleteId) return;
    try {
      await api(`/api/updates/${deleteId}`, { method: "DELETE" });
      setDeleteId(null);
      await loadUpdates();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Delete failed");
    }
  }

  return (
    <AdminShell
      title="Legal Updates"
      subtitle="Publish breaking legal news, court developments, and law notifications"
      actions={
        <Button onClick={openCreate} className="gap-2">
          <Plus className="size-4" /> Add Legal Update
        </Button>
      }
    >
      <div className="space-y-4">
        {/* Filters */}
        <div className="flex gap-1.5 overflow-x-auto">
          {COURTS.map((c) => (
            <Button
              key={c}
              variant={courtFilter === c ? "default" : "outline"}
              size="sm"
              onClick={() => setCourtFilter(c)}
            >
              {c}
            </Button>
          ))}
        </div>

        <StateBlock
          loading={loading}
          error={error}
          empty={!loading && updates.length === 0}
          emptyText="No legal updates found."
        />

        {!loading && updates.length > 0 ? (
          <div className="space-y-3">
            {updates.map((item) => (
              <Panel key={item._id} className="p-4 transition hover:border-primary/40">
                <div className="flex flex-col justify-between gap-3 md:flex-row md:items-start">
                  <div className="space-y-1.5 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-bold text-primary">
                        {item.badge || item.court || "NEWS"}
                      </span>
                      <h3 className="font-display text-base font-semibold">{item.title}</h3>
                    </div>

                    <p className="text-xs text-muted-foreground">
                      {[
                        item.source ? `Source: ${item.source}` : null,
                        item.court,
                        item.publishedAt ? new Date(item.publishedAt).toLocaleDateString() : null,
                      ]
                        .filter(Boolean)
                        .join(" • ")}
                    </p>

                    {item.body ? (
                      <p className="text-sm text-foreground/80 line-clamp-2 mt-1">{item.body}</p>
                    ) : null}
                  </div>

                  <div className="flex items-center gap-2 self-end md:self-start shrink-0">
                    {item.url ? (
                      <a
                        href={item.url}
                        target="_blank"
                        rel="noreferrer"
                        className="rounded p-1.5 text-muted-foreground hover:bg-muted hover:text-foreground"
                        title="Open Source Link"
                      >
                        <ExternalLink className="size-4" />
                      </a>
                    ) : null}
                    <Button variant="outline" size="sm" onClick={() => openEdit(item)} className="gap-1">
                      <Edit3 className="size-3.5" /> Edit
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setDeleteId(item._id)}
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

      {/* Edit / Create Modal */}
      <Dialog open={!!editItem} onOpenChange={(open) => !open && setEditItem(null)}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{isNew ? "Create Legal Update" : "Edit Legal Update"}</DialogTitle>
          </DialogHeader>

          {editItem ? (
            <form onSubmit={handleSave} className="space-y-4 py-2">
              <Field label="Headline / Title *">
                <Input
                  required
                  value={editItem.title || ""}
                  onChange={(e) => setEditItem({ ...editItem, title: e.target.value })}
                  placeholder="e.g. SC seeks response from Centre on plea against..."
                />
              </Field>

              <div className="grid grid-cols-3 gap-3">
                <Field label="Court Category">
                  <select
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                    value={editItem.court || "Supreme Court"}
                    onChange={(e) => setEditItem({ ...editItem, court: e.target.value })}
                  >
                    <option value="Supreme Court">Supreme Court</option>
                    <option value="High Court">High Court</option>
                    <option value="Other">Other</option>
                  </select>
                </Field>
                <Field label="Badge Text">
                  <Input
                    value={editItem.badge || ""}
                    onChange={(e) => setEditItem({ ...editItem, badge: e.target.value })}
                    placeholder="SC / HC / GOI"
                  />
                </Field>
                <Field label="Source Name">
                  <Input
                    value={editItem.source || ""}
                    onChange={(e) => setEditItem({ ...editItem, source: e.target.value })}
                    placeholder="LiveLaw, Bar & Bench"
                  />
                </Field>
              </div>

              <Field label="Summary / Content">
                <Textarea
                  rows={4}
                  value={editItem.body || ""}
                  onChange={(e) => setEditItem({ ...editItem, body: e.target.value })}
                  placeholder="Details of the update, verdict summary, notification text..."
                />
              </Field>

              <Field label="External Link / Article URL">
                <Input
                  value={editItem.url || ""}
                  onChange={(e) => setEditItem({ ...editItem, url: e.target.value })}
                  placeholder="https://livelaw.in/..."
                />
              </Field>

              <DialogFooter className="pt-3">
                <Button type="button" variant="outline" onClick={() => setEditItem(null)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={saveBusy}>
                  {saveBusy ? "Saving..." : isNew ? "Publish Update" : "Save Changes"}
                </Button>
              </DialogFooter>
            </form>
          ) : null}
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={!!deleteId} onOpenChange={(open) => !open && setDeleteId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Legal Update</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to remove this legal update?
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  );
}
