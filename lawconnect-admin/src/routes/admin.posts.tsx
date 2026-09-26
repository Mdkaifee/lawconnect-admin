import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Field } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { Post } from "@/lib/types";
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
import { Plus, Search, Trash2, EyeOff, CheckCircle, Flag } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/posts")({
  head: () => ({ meta: [{ title: "Law Posts & Moderation — Admin" }] }),
  component: PostsAdmin,
});

function PostsAdmin() {
  const ready = useAdminGuard();
  const [items, setItems] = useState<Post[]>([]);
  const [reports, setReports] = useState<any[]>([]);
  const [viewTab, setViewTab] = useState<"posts" | "reports">("posts");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");

  const [createOpen, setCreateOpen] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [newContent, setNewContent] = useState("");
  const [newCategory, setNewCategory] = useState("Supreme Court");

  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  function load() {
    if (!ready) return;
    setLoading(true);
    setError(null);

    Promise.all([
      api<{ items: Post[] }>(`/api/posts?all=true${query ? `&q=${query}` : ""}`),
      api<{ items: any[] }>("/api/reports?status=all").catch(() => ({ items: [] })),
    ])
      .then(([postsRes, reportsRes]) => {
        setItems(postsRes.items);
        setReports(reportsRes.items);
      })
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, [ready]);

  async function createOfficialPost() {
    if (!newTitle.trim() || !newContent.trim()) return;
    setSaving(true);
    try {
      await api("/api/posts/admin", {
        method: "POST",
        body: {
          title: newTitle.trim(),
          content: newContent.trim(),
          category: newCategory,
        },
      });
      setCreateOpen(false);
      setNewTitle("");
      setNewContent("");
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to create official post");
    } finally {
      setSaving(false);
    }
  }

  async function toggleHidePost(postId: string, currentStatus: string) {
    try {
      const nextStatus = currentStatus === "hidden" ? "published" : "hidden";
      await api(`/api/posts/${postId}`, {
        method: "PUT",
        body: { status: nextStatus },
      });
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to update post status");
    }
  }

  async function confirmDelete() {
    if (!deletingId) return;
    try {
      await api(`/api/posts/${deletingId}`, { method: "DELETE" });
      setDeletingId(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to delete post");
    }
  }

  async function handleResolveReport(reportId: string, action: string) {
    try {
      await api(`/api/reports/${reportId}`, {
        method: "PUT",
        body: { status: "resolved", action },
      });
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to action report");
    }
  }

  return (
    <AdminShell
      title="Law Posts & Moderation"
      subtitle="Moderate student discussions, community queries, and publish official notes"
      actions={
        <Button onClick={() => setCreateOpen(true)} className="gap-2">
          <Plus className="size-4" /> Publish Official Post
        </Button>
      }
    >
      {/* View Switcher Tabs */}
      <div className="mb-4 flex gap-3 items-center justify-between">
        <div className="flex gap-2">
          <Button
            variant={viewTab === "posts" ? "default" : "outline"}
            size="sm"
            onClick={() => setViewTab("posts")}
          >
            All Posts ({items.length})
          </Button>
          <Button
            variant={viewTab === "reports" ? "default" : "outline"}
            size="sm"
            onClick={() => setViewTab("reports")}
            className="gap-1.5"
          >
            <Flag className="size-3.5 text-amber-500" />
            Reported Queue ({reports.filter((r) => r.status === "pending").length})
          </Button>
        </div>

        {viewTab === "posts" && (
          <div className="flex gap-2">
            <Input
              placeholder="Search posts..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && load()}
              className="h-9 w-60"
            />
            <Button size="sm" variant="outline" onClick={load}>
              <Search className="size-3.5" />
            </Button>
          </div>
        )}
      </div>

      <StateBlock
        loading={loading}
        error={error}
        empty={!loading && (viewTab === "posts" ? items.length === 0 : reports.length === 0)}
        emptyText={viewTab === "posts" ? "No posts found." : "No moderation reports pending."}
      />

      {/* Posts List */}
      {!loading && viewTab === "posts" && items.length > 0 ? (
        <Panel className="divide-y divide-border">
          {items.map((p) => (
            <div key={p._id} className="flex flex-wrap items-center justify-between gap-4 p-4 hover:bg-muted/30">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="rounded bg-accent/20 px-2 py-0.5 text-xs font-semibold text-accent-foreground">
                    {p.category || "General Law"}
                  </span>
                  <span className="text-xs font-medium text-muted-foreground">{p.authorName}</span>
                  {p.authorType === "admin" && (
                    <span className="rounded bg-primary/10 px-1.5 py-0.5 text-[10px] font-bold text-primary">
                      Official
                    </span>
                  )}
                  {p.status === "hidden" && (
                    <span className="rounded bg-destructive/10 px-1.5 py-0.5 text-[10px] font-bold text-destructive">
                      Hidden
                    </span>
                  )}
                </div>
                <h3 className="mt-1 font-display text-base font-semibold">{p.title}</h3>
                <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">{p.content}</p>
                <div className="mt-2 flex gap-4 text-xs text-muted-foreground">
                  <span>{p.likes ?? 0} Likes</span>
                  <span>{p.commentsCount ?? 0} Comments</span>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Button
                  size="sm"
                  variant={p.status === "hidden" ? "secondary" : "outline"}
                  onClick={() => toggleHidePost(p._id, p.status || "published")}
                >
                  <EyeOff className="size-4 mr-1" />
                  {p.status === "hidden" ? "Unhide" : "Hide"}
                </Button>
                <Button size="sm" variant="ghost" className="text-destructive" onClick={() => setDeletingId(p._id)}>
                  <Trash2 className="size-4" />
                </Button>
              </div>
            </div>
          ))}
        </Panel>
      ) : null}

      {/* Reports Queue List */}
      {!loading && viewTab === "reports" && reports.length > 0 ? (
        <Panel className="divide-y divide-border">
          {reports.map((r) => (
            <div key={r._id} className="p-4 space-y-2 hover:bg-muted/30">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="rounded bg-destructive/10 px-2 py-0.5 text-xs font-semibold text-destructive">
                    Reported {r.targetType}
                  </span>
                  <span className="text-xs text-muted-foreground">Reporter: {r.reporterId?.name || "User"}</span>
                </div>
                <span className="text-xs font-semibold uppercase">{r.status}</span>
              </div>
              <p className="text-sm font-medium text-foreground">Reason: "{r.reason}"</p>
              <div className="flex gap-2 pt-1">
                <Button
                  size="sm"
                  variant="outline"
                  className="text-xs"
                  onClick={() => handleResolveReport(r._id, "hide_target")}
                >
                  Hide Content & Resolve
                </Button>
                <Button
                  size="sm"
                  variant="destructive"
                  className="text-xs"
                  onClick={() => handleResolveReport(r._id, "delete_target")}
                >
                  Delete Content & Resolve
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  className="text-xs"
                  onClick={() => handleResolveReport(r._id, "dismiss")}
                >
                  Dismiss Report
                </Button>
              </div>
            </div>
          ))}
        </Panel>
      ) : null}

      {/* Create Official Post Dialog */}
      <Dialog open={createOpen} onOpenChange={setCreateOpen}>
        <DialogContent className="max-w-xl">
          <DialogHeader>
            <DialogTitle>Publish Official Law Hub Post</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <Field label="Category">
              <select
                value={newCategory}
                onChange={(e) => setNewCategory(e.target.value)}
                className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              >
                <option value="Supreme Court">Supreme Court</option>
                <option value="Constitution">Constitution</option>
                <option value="Criminal Law">Criminal Law</option>
                <option value="Civil Law">Civil Law</option>
                <option value="General Law">General Law</option>
              </select>
            </Field>
            <Field label="Title / Subject *">
              <Input
                value={newTitle}
                onChange={(e) => setNewTitle(e.target.value)}
                placeholder="e.g. Landmark Judgment on Article 21 & Bail"
              />
            </Field>
            <Field label="Content *">
              <Textarea
                rows={5}
                value={newContent}
                onChange={(e) => setNewContent(e.target.value)}
                placeholder="Write official legal brief, updates or insights..."
              />
            </Field>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setCreateOpen(false)}>
              Cancel
            </Button>
            <Button onClick={createOfficialPost} disabled={saving || !newTitle.trim() || !newContent.trim()}>
              {saving ? "Publishing…" : "Publish Official Post"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Alert */}
      <AlertDialog open={Boolean(deletingId)} onOpenChange={(o) => !o && setDeletingId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Community Post</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to permanently delete this post and its comments?
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
