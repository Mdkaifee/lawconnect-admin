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
import type { Post } from "@/lib/types";
import { Plus, Search, Trash2, Edit3, Heart, MessageSquare } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/posts")({
  component: PostsPage,
});

function PostsPage() {
  const ready = useAdminGuard();
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");

  // Dialogs
  const [editPost, setEditPost] = useState<Partial<Post> | null>(null);
  const [isNew, setIsNew] = useState(false);
  const [saveBusy, setSaveBusy] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  async function loadPosts() {
    try {
      setLoading(true);
      setError(null);
      const params = new URLSearchParams({ all: "true" });
      if (search.trim()) params.set("q", search.trim());
      const res = await api<{ items: Post[]; total: number }>(`/api/posts?${params.toString()}`);
      setPosts(res.items || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load posts");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!ready) return;
    loadPosts();
  }, [ready]);

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    loadPosts();
  }

  function openCreate() {
    setIsNew(true);
    setEditPost({
      title: "",
      content: "",
      category: "Constitution",
      authorName: "Rishikesh Yadav",
      authorType: "admin",
      tags: [],
      status: "published",
    });
  }

  function openEdit(p: Post) {
    setIsNew(false);
    setEditPost({ ...p });
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!editPost || !editPost.title) return;
    setSaveBusy(true);
    try {
      if (isNew) {
        await api("/api/posts/admin", { method: "POST", body: editPost });
      } else {
        await api(`/api/posts/${editPost._id}`, { method: "PUT", body: editPost });
      }
      setEditPost(null);
      await loadPosts();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Save failed");
    } finally {
      setSaveBusy(false);
    }
  }

  async function handleDelete() {
    if (!deleteId) return;
    try {
      await api(`/api/posts/${deleteId}`, { method: "DELETE" });
      setDeleteId(null);
      await loadPosts();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Delete failed");
    }
  }

  return (
    <AdminShell
      title="Law Posts & Community"
      subtitle="Publish official articles, insights and moderate community discussions"
      actions={
        <Button onClick={openCreate} className="gap-2">
          <Plus className="size-4" /> Create Official Post
        </Button>
      }
    >
      <div className="space-y-4">
        {/* Search */}
        <form onSubmit={handleSearch} className="flex gap-2 max-w-md">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
            <Input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search posts by title, content or author..."
              className="pl-9"
            />
          </div>
          <Button type="submit" variant="secondary">Search</Button>
        </form>

        <StateBlock
          loading={loading}
          error={error}
          empty={!loading && posts.length === 0}
          emptyText="No posts found."
        />

        {!loading && posts.length > 0 ? (
          <div className="space-y-3">
            {posts.map((p) => (
              <Panel key={p._id} className="p-4 transition hover:border-primary/40">
                <div className="flex flex-col justify-between gap-3 md:flex-row md:items-start">
                  <div className="space-y-1.5 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="rounded bg-accent/20 px-2 py-0.5 text-xs font-semibold text-accent-foreground">
                        {p.category || "General Law"}
                      </span>
                      <h3 className="font-display text-base font-semibold">{p.title}</h3>
                      {p.authorType === "admin" ? (
                        <span className="rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary font-medium">
                          Official
                        </span>
                      ) : null}
                    </div>

                    <p className="text-xs text-muted-foreground">
                      By <span className="font-medium text-foreground">{p.authorName || "Anonymous"}</span> •{" "}
                      {p.createdAt ? new Date(p.createdAt).toLocaleDateString() : "Recent"}
                    </p>

                    <p className="text-sm text-foreground/80 line-clamp-3 whitespace-pre-wrap mt-1">
                      {p.content}
                    </p>

                    {p.tags && p.tags.length > 0 ? (
                      <div className="flex flex-wrap gap-1.5 pt-1">
                        {p.tags.map((t) => (
                          <span key={t} className="rounded bg-muted px-2 py-0.5 text-[11px] text-muted-foreground">
                            #{t}
                          </span>
                        ))}
                      </div>
                    ) : null}

                    <div className="flex items-center gap-4 text-xs text-muted-foreground pt-1">
                      <span className="flex items-center gap-1">
                        <Heart className="size-3.5 text-rose-500" /> {p.likes || 0} Likes
                      </span>
                      <span className="flex items-center gap-1">
                        <MessageSquare className="size-3.5 text-primary" /> {p.commentsCount || 0} Comments
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <Button variant="outline" size="sm" onClick={() => openEdit(p)} className="gap-1">
                      <Edit3 className="size-3.5" /> Edit
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setDeleteId(p._id)}
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
      <Dialog open={!!editPost} onOpenChange={(open) => !open && setEditPost(null)}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{isNew ? "Create Law Post" : "Edit Post"}</DialogTitle>
          </DialogHeader>

          {editPost ? (
            <form onSubmit={handleSave} className="space-y-4 py-2">
              <Field label="Post Title *">
                <Input
                  required
                  value={editPost.title || ""}
                  onChange={(e) => setEditPost({ ...editPost, title: e.target.value })}
                  placeholder="e.g. SC grants interim relief on bail plea in PMLA case"
                />
              </Field>

              <div className="grid grid-cols-2 gap-3">
                <Field label="Category">
                  <Input
                    value={editPost.category || ""}
                    onChange={(e) => setEditPost({ ...editPost, category: e.target.value })}
                    placeholder="e.g. Constitution, Criminal Law"
                  />
                </Field>
                <Field label="Author Name">
                  <Input
                    value={editPost.authorName || ""}
                    onChange={(e) => setEditPost({ ...editPost, authorName: e.target.value })}
                    placeholder="Rishikesh Yadav"
                  />
                </Field>
              </div>

              <Field label="Content *">
                <Textarea
                  required
                  rows={5}
                  value={editPost.content || ""}
                  onChange={(e) => setEditPost({ ...editPost, content: e.target.value })}
                  placeholder="Write post content, legal analysis or discussion..."
                />
              </Field>

              <Field label="Hashtags (comma-separated)">
                <Input
                  value={(editPost.tags || []).join(", ")}
                  onChange={(e) =>
                    setEditPost({
                      ...editPost,
                      tags: e.target.value.split(",").map((t) => t.trim()).filter(Boolean),
                    })
                  }
                  placeholder="SupremeCourt, Bail, PMLA, Article21"
                />
              </Field>

              <DialogFooter className="pt-3">
                <Button type="button" variant="outline" onClick={() => setEditPost(null)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={saveBusy}>
                  {saveBusy ? "Saving..." : isNew ? "Publish Post" : "Save Changes"}
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
            <AlertDialogTitle>Delete Post</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to permanently delete this post?
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
