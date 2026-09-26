import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Field } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { LawCase } from "@/lib/types";
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

export const Route = createFileRoute("/admin/cases")({
  head: () => ({ meta: [{ title: "Cases & Judgments — Admin" }] }),
  component: CasesAdmin,
});

const EMPTY: Partial<LawCase> = {
  title: "",
  citation: "",
  year: new Date().getFullYear(),
  court: "Supreme Court of India",
  courtType: "Supreme Court",
  bench: "",
  petitioners: "",
  respondents: "",
  summary: "",
  simpleExplanation: "",
  judgmentPdfUrl: "",
  published: true,
};

function CasesAdmin() {
  const ready = useAdminGuard();
  const [items, setItems] = useState<LawCase[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [courtFilter, setCourtFilter] = useState("All");

  const [editing, setEditing] = useState<Partial<LawCase> | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  function load() {
    if (!ready) return;
    setLoading(true);
    setError(null);
    const params = new URLSearchParams({ all: "true" });
    if (query) params.set("q", query);
    if (courtFilter !== "All") params.set("court", courtFilter);

    api<{ items: LawCase[] }>(`/api/cases?${params.toString()}`)
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
        await api(`/api/cases/${editing._id}`, { method: "PUT", body: editing });
      } else {
        await api("/api/cases", { method: "POST", body: editing });
      }
      setEditing(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to save case");
    } finally {
      setSaving(false);
    }
  }

  async function confirmDelete() {
    if (!deletingId) return;
    try {
      await api(`/api/cases/${deletingId}`, { method: "DELETE" });
      setDeletingId(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to delete case");
    }
  }

  return (
    <AdminShell
      title="Cases & Judgments"
      subtitle="Curate landmark rulings and link Indian Kanoon precedents"
      actions={
        <Button onClick={() => setEditing({ ...EMPTY })} className="gap-2">
          <Plus className="size-4" /> Add Landmark Case
        </Button>
      }
    >
      <div className="mb-4 flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-[240px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
          <Input
            placeholder="Search by title, citation, or keywords..."
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
          <option value="District Court">District Court</option>
          <option value="Tribunal">Tribunal</option>
        </select>
        <Button variant="outline" onClick={load}>
          Search
        </Button>
      </div>

      <StateBlock loading={loading} error={error} empty={!loading && items.length === 0} emptyText="No cases found." />

      {!loading && items.length > 0 ? (
        <Panel className="divide-y divide-border">
          {items.map((c) => (
            <div key={c._id} className="flex flex-wrap items-center justify-between gap-4 p-4 hover:bg-muted/30">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">
                    {c.courtType || "Supreme Court"}
                  </span>
                  {c.year ? <span className="text-xs text-muted-foreground">{c.year}</span> : null}
                  {!c.published ? (
                    <span className="rounded bg-destructive/10 px-2 py-0.5 text-xs font-semibold text-destructive">
                      Draft
                    </span>
                  ) : null}
                </div>
                <h3 className="mt-1 font-display text-base font-semibold">{c.title}</h3>
                {c.citation ? <p className="text-xs font-medium text-accent-foreground">{c.citation}</p> : null}
                {c.summary ? (
                  <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">{c.summary}</p>
                ) : null}
              </div>
              <div className="flex items-center gap-2">
                <Button size="sm" variant="outline" onClick={() => setEditing(c)}>
                  <Edit className="size-4" />
                </Button>
                <Button size="sm" variant="ghost" className="text-destructive" onClick={() => setDeletingId(c._id)}>
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
            <DialogTitle>{editing?._id ? "Edit Case" : "Add Landmark Case"}</DialogTitle>
          </DialogHeader>
          {editing ? (
            <div className="space-y-4 py-2">
              <Field label="Case Title *">
                <Input
                  value={editing.title ?? ""}
                  onChange={(e) => setEditing({ ...editing, title: e.target.value })}
                  placeholder="e.g. Kesavananda Bharati v. State of Kerala"
                />
              </Field>
              <div className="grid gap-4 sm:grid-cols-2">
                <Field label="Citation">
                  <Input
                    value={editing.citation ?? ""}
                    onChange={(e) => setEditing({ ...editing, citation: e.target.value })}
                    placeholder="e.g. (1973) 4 SCC 225"
                  />
                </Field>
                <Field label="Year">
                  <Input
                    type="number"
                    value={editing.year ?? ""}
                    onChange={(e) => setEditing({ ...editing, year: Number(e.target.value) || undefined })}
                  />
                </Field>
              </div>
              <div className="grid gap-4 sm:grid-cols-2">
                <Field label="Court">
                  <Input
                    value={editing.court ?? ""}
                    onChange={(e) => setEditing({ ...editing, court: e.target.value })}
                    placeholder="e.g. Supreme Court of India"
                  />
                </Field>
                <Field label="Court Type">
                  <select
                    value={editing.courtType ?? "Supreme Court"}
                    onChange={(e) => setEditing({ ...editing, courtType: e.target.value })}
                    className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  >
                    <option value="Supreme Court">Supreme Court</option>
                    <option value="High Court">High Court</option>
                    <option value="District Court">District Court</option>
                    <option value="Tribunal">Tribunal</option>
                    <option value="Other">Other</option>
                  </select>
                </Field>
              </div>
              <Field label="Bench / Judges">
                <Input
                  value={editing.bench ?? ""}
                  onChange={(e) => setEditing({ ...editing, bench: e.target.value })}
                  placeholder="e.g. Chief Justice S.M. Sikri & 12 Judges"
                />
              </Field>
              <Field label="Executive Summary">
                <Textarea
                  rows={3}
                  value={editing.summary ?? ""}
                  onChange={(e) => setEditing({ ...editing, summary: e.target.value })}
                  placeholder="Core facts, issues and ruling..."
                />
              </Field>
              <Field label="Simple Ratio / Student Breakdown">
                <Textarea
                  rows={3}
                  value={editing.simpleExplanation ?? ""}
                  onChange={(e) => setEditing({ ...editing, simpleExplanation: e.target.value })}
                  placeholder="Key principle explained in plain language..."
                />
              </Field>
              <Field label="Judgment Document / Court Copy URL">
                <Input
                  value={editing.judgmentPdfUrl ?? ""}
                  onChange={(e) => setEditing({ ...editing, judgmentPdfUrl: e.target.value })}
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
              {saving ? "Saving…" : "Save Case"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Alert */}
      <AlertDialog open={Boolean(deletingId)} onOpenChange={(o) => !o && setDeletingId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Landmark Case</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete this case? This action cannot be undone.
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
