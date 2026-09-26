import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Pager } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { LegalUpdate } from "@/lib/types";
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
import { Plus, Search, Trash2, Edit, Newspaper, ExternalLink, ShieldCheck } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/updates")({
  head: () => ({ meta: [{ title: "Legal Updates — Admin" }] }),
  component: UpdatesAdmin,
});

function UpdatesAdmin() {
  const ready = useAdminGuard();
  const [items, setItems] = useState<LegalUpdate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const limit = 20;

  const [modalOpen, setModalOpen] = useState(false);
  const [editingUpdate, setEditingUpdate] = useState<LegalUpdate | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // Form State
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [source, setSource] = useState("LiveLaw");
  const [court, setCourt] = useState("Supreme Court");
  const [badge, setBadge] = useState("Verified");
  const [url, setUrl] = useState("");
  const [published, setPublished] = useState(true);

  function load(nextPage = page) {
    if (!ready) return;
    setLoading(true);
    setError(null);
    const params = new URLSearchParams({ all: "true", page: String(nextPage), limit: String(limit) });
    if (query) params.set("q", query);
    api<{ items: LegalUpdate[]; total: number; page: number }>(`/api/updates?${params.toString()}`)
      .then((res) => {
        setItems(res.items || []);
        setTotal(res.total || 0);
        setPage(res.page || nextPage);
      })
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, [ready]);

  function openCreate() {
    setEditingUpdate(null);
    setTitle("");
    setBody("");
    setSource("LiveLaw");
    setCourt("Supreme Court");
    setBadge("Verified");
    setUrl("");
    setPublished(true);
    setModalOpen(true);
  }

  function openEdit(u: LegalUpdate) {
    setEditingUpdate(u);
    setTitle(u.title || "");
    setBody(u.body || "");
    setSource(u.source || "LiveLaw");
    setCourt(u.court || "Supreme Court");
    setBadge(u.badge || "Verified");
    setUrl(u.url || "");
    setPublished(u.published !== false);
    setModalOpen(true);
  }

  async function saveUpdate() {
    if (!title.trim() || !body.trim()) return;
    setSaving(true);
    try {
      const payload = {
        title: title.trim(),
        body: body.trim(),
        source: source.trim(),
        court: court.trim(),
        badge,
        url: url.trim() || undefined,
        published,
      };

      if (editingUpdate) {
        await api(`/api/updates/${editingUpdate._id}`, { method: "PUT", body: payload });
      } else {
        await api("/api/updates", { method: "POST", body: payload });
      }
      setModalOpen(false);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to save legal update");
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
      alert(e instanceof Error ? e.message : "Failed to delete legal update");
    }
  }

  return (
    <AdminShell
      title="Legal Updates & Daily News"
      subtitle="Publish verified legal headlines, notifications and Supreme Court/High Court updates"
      actions={
        <Button onClick={openCreate} className="gap-2 bg-primary hover:bg-primary/90 text-primary-foreground">
          <Plus className="size-4" /> Add Legal Update
        </Button>
      }
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
            placeholder="Search updates by headline or content..."
            className="pl-9"
          />
        </div>
        <Button onClick={() => load(1)} variant="secondary">
          Search
        </Button>
      </div>

      {/* Main List */}
      {loading ? (
        <StateBlock message="Loading legal updates..." loading />
      ) : error ? (
        <StateBlock message={error} onRetry={load} />
      ) : items.length === 0 ? (
        <StateBlock
          message="No legal updates published yet. Tap 'Add Legal Update' to create the first headline."
          action={
            <Button onClick={openCreate} className="gap-2">
              <Plus className="size-4" /> Add First Update
            </Button>
          }
        />
      ) : (
        <div className="space-y-3">
          {items.map((item) => (
            <div
              key={item._id}
              className="flex flex-col md:flex-row md:items-center justify-between gap-4 rounded-lg border border-border bg-card p-5 shadow-sm transition-all hover:border-primary/40"
            >
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2 mb-1.5">
                  <span className="flex items-center gap-1 rounded bg-secondary/15 px-2 py-0.5 text-xs font-semibold text-secondary-foreground">
                    <ShieldCheck className="size-3 text-secondary-foreground" />
                    {item.badge || "Verified"}
                  </span>
                  {item.court && (
                    <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">
                      {item.court}
                    </span>
                  )}
                  {item.source && (
                    <span className="text-xs text-muted-foreground">
                      Source: {item.source}
                    </span>
                  )}
                  {item.publishedAt && (
                    <span className="text-xs text-muted-foreground">
                      {new Date(item.publishedAt).toLocaleDateString()}
                    </span>
                  )}
                </div>

                <h3 className="font-display text-base font-semibold text-card-foreground">
                  {item.title}
                </h3>

                {item.body && (
                  <p className="mt-1 line-clamp-2 text-sm text-muted-foreground leading-relaxed">
                    {item.body}
                  </p>
                )}

                {item.url && (
                  <a
                    href={item.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="mt-2 inline-flex items-center gap-1 text-xs text-primary hover:underline"
                  >
                    View Original Source <ExternalLink className="size-3" />
                  </a>
                )}
              </div>

              {/* Actions */}
              <div className="flex shrink-0 items-center gap-2 self-end md:self-center">
                <Button size="sm" variant="outline" onClick={() => openEdit(item)} className="gap-1.5">
                  <Edit className="size-3.5" /> Edit
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => setDeletingId(item._id)}
                  className="text-destructive hover:bg-destructive/10"
                >
                  <Trash2 className="size-4" />
                </Button>
              </div>
            </div>
          ))}
          <Pager page={page} limit={limit} total={total} onPageChange={load} />
        </div>
      )}

      {/* Create / Edit Modal */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-lg font-display">
              {editingUpdate ? "Edit Legal Update" : "Publish Legal Update"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-3.5 py-2">
            <div>
              <label className="text-xs font-semibold uppercase text-muted-foreground">Headline / Title *</label>
              <Input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. SC upholds fundamental right to privacy in digital era"
                className="mt-1"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Source</label>
                <Input
                  value={source}
                  onChange={(e) => setSource(e.target.value)}
                  placeholder="e.g. LiveLaw / Bar & Bench"
                  className="mt-1"
                />
              </div>

              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Court</label>
                <Input
                  value={court}
                  onChange={(e) => setCourt(e.target.value)}
                  placeholder="e.g. Supreme Court"
                  className="mt-1"
                />
              </div>

              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Badge</label>
                <select
                  value={badge}
                  onChange={(e) => setBadge(e.target.value)}
                  className="mt-1 flex h-9 w-full rounded-md border border-input bg-card px-3 text-sm"
                >
                  <option value="Verified">Verified</option>
                  <option value="Breaking">Breaking</option>
                  <option value="Important">Important</option>
                  <option value="Amendment">Amendment</option>
                </select>
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold uppercase text-muted-foreground">Source URL</label>
              <Input
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="https://..."
                className="mt-1"
              />
            </div>

            <div>
              <label className="text-xs font-semibold uppercase text-muted-foreground">Update Content / Summary *</label>
              <Textarea
                rows={5}
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Detailed summary of the judgment, notification or legal development..."
                className="mt-1"
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={saveUpdate} disabled={saving || !title.trim() || !body.trim()}>
              {saving ? "Saving..." : editingUpdate ? "Update News" : "Publish News"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={Boolean(deletingId)} onOpenChange={() => setDeletingId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure you want to delete this legal update?</AlertDialogTitle>
            <AlertDialogDescription>
              This will remove the update from both the admin panel and mobile feed.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Delete Update
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  );
}
