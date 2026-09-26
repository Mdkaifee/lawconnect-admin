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
import type { LawCase } from "@/lib/types";
import { Plus, Search, Trash2, Edit3, ExternalLink } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/cases")({
  component: CasesPage,
});

const COURTS = ["All", "Supreme Court", "High Court", "District Court", "Tribunal"];

function CasesPage() {
  const ready = useAdminGuard();
  const [cases, setCases] = useState<LawCase[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [courtFilter, setCourtFilter] = useState("All");

  // Dialog states
  const [editCase, setEditCase] = useState<Partial<LawCase> | null>(null);
  const [isNew, setIsNew] = useState(false);
  const [saveBusy, setSaveBusy] = useState(false);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  async function loadCases() {
    try {
      setLoading(true);
      setError(null);
      const params = new URLSearchParams({ all: "true" });
      if (search.trim()) params.set("q", search.trim());
      if (courtFilter !== "All") params.set("court", courtFilter);
      const res = await api<{ items: LawCase[]; total: number }>(`/api/cases?${params.toString()}`);
      setCases(res.items || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load cases");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!ready) return;
    loadCases();
  }, [ready, courtFilter]);

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    loadCases();
  }

  function openCreate() {
    setIsNew(true);
    setEditCase({
      title: "",
      citation: "",
      year: new Date().getFullYear(),
      court: "Supreme Court of India",
      courtType: "Supreme Court",
      bench: "",
      petitioners: "",
      respondents: "",
      tags: [],
      summary: "",
      simpleExplanation: "",
      judgmentPdfUrl: "",
      published: true,
    });
  }

  function openEdit(c: LawCase) {
    setIsNew(false);
    setEditCase({ ...c });
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!editCase || !editCase.title) return;
    setSaveBusy(true);
    try {
      if (isNew) {
        await api("/api/cases", { method: "POST", body: editCase });
      } else {
        await api(`/api/cases/${editCase._id}`, { method: "PUT", body: editCase });
      }
      setEditCase(null);
      await loadCases();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Save failed");
    } finally {
      setSaveBusy(false);
    }
  }

  async function handleDelete() {
    if (!deleteId) return;
    try {
      await api(`/api/cases/${deleteId}`, { method: "DELETE" });
      setDeleteId(null);
      await loadCases();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Delete failed");
    }
  }

  return (
    <AdminShell
      title="Cases & Judgments"
      subtitle="Manage landmark judgments, rulings and legal precedents"
      actions={
        <Button onClick={openCreate} className="gap-2">
          <Plus className="size-4" /> Add Case
        </Button>
      }
    >
      <div className="space-y-4">
        {/* Filter Bar */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <form onSubmit={handleSearch} className="flex flex-1 gap-2 max-w-md">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
              <Input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search cases by title, citation, bench..."
                className="pl-9"
              />
            </div>
            <Button type="submit" variant="secondary">Search</Button>
          </form>

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
        </div>

        {/* Content State */}
        <StateBlock
          loading={loading}
          error={error}
          empty={!loading && cases.length === 0}
          emptyText="No cases found matching your criteria."
        />

        {/* Table / List */}
        {!loading && cases.length > 0 ? (
          <div className="space-y-3">
            {cases.map((c) => (
              <Panel key={c._id} className="p-4 transition hover:border-primary/40">
                <div className="flex flex-col justify-between gap-4 md:flex-row md:items-start">
                  <div className="space-y-1.5 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="font-display text-base font-semibold">{c.title}</h3>
                      <span className="rounded-full bg-accent/20 px-2.5 py-0.5 text-xs font-medium text-accent-foreground">
                        {c.courtType || c.court}
                      </span>
                      {c.published === false ? (
                        <span className="rounded-full bg-destructive/10 px-2 py-0.5 text-xs text-destructive">
                          Draft
                        </span>
                      ) : null}
                    </div>

                    <p className="text-xs text-muted-foreground">
                      {[c.citation, c.year, c.court, c.bench ? `Bench: ${c.bench}` : null]
                        .filter(Boolean)
                        .join(" • ")}
                    </p>

                    {c.summary ? (
                      <p className="text-sm text-foreground/80 line-clamp-2 mt-1">{c.summary}</p>
                    ) : null}

                    {c.tags && c.tags.length > 0 ? (
                      <div className="flex flex-wrap gap-1.5 pt-1">
                        {c.tags.map((t) => (
                          <span key={t} className="rounded bg-muted px-2 py-0.5 text-[11px] text-muted-foreground">
                            #{t}
                          </span>
                        ))}
                      </div>
                    ) : null}
                  </div>

                  <div className="flex items-center gap-2 self-end md:self-start shrink-0">
                    {c.judgmentPdfUrl ? (
                      <a
                        href={c.judgmentPdfUrl}
                        target="_blank"
                        rel="noreferrer"
                        className="rounded p-1.5 text-muted-foreground hover:bg-muted hover:text-foreground"
                        title="View PDF"
                      >
                        <ExternalLink className="size-4" />
                      </a>
                    ) : null}
                    <Button variant="outline" size="sm" onClick={() => openEdit(c)} className="gap-1">
                      <Edit3 className="size-3.5" /> Edit
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setDeleteId(c._id)}
                      className="text-destructive hover:bg-destructive/10 hover:text-destructive"
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

      {/* Edit / Create Dialog */}
      <Dialog open={!!editCase} onOpenChange={(open) => !open && setEditCase(null)}>
        <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
          <DialogHeader>
            <DialogTitle>{isNew ? "Add Landmark Case" : "Edit Case Details"}</DialogTitle>
          </DialogHeader>

          {editCase ? (
            <form onSubmit={handleSave} className="space-y-4 py-2">
              <Field label="Case Title *">
                <Input
                  required
                  value={editCase.title || ""}
                  onChange={(e) => setEditCase({ ...editCase, title: e.target.value })}
                  placeholder="e.g. Kesavananda Bharati v. State of Kerala"
                />
              </Field>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <Field label="Citation">
                  <Input
                    value={editCase.citation || ""}
                    onChange={(e) => setEditCase({ ...editCase, citation: e.target.value })}
                    placeholder="(1973) 4 SCC 225"
                  />
                </Field>
                <Field label="Year">
                  <Input
                    type="number"
                    value={editCase.year || ""}
                    onChange={(e) => setEditCase({ ...editCase, year: Number(e.target.value) })}
                    placeholder="1973"
                  />
                </Field>
                <Field label="Court Type">
                  <select
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                    value={editCase.courtType || "Supreme Court"}
                    onChange={(e) => setEditCase({ ...editCase, courtType: e.target.value })}
                  >
                    <option value="Supreme Court">Supreme Court</option>
                    <option value="High Court">High Court</option>
                    <option value="District Court">District Court</option>
                    <option value="Tribunal">Tribunal</option>
                  </select>
                </Field>
              </div>

              <Field label="Court Name">
                <Input
                  value={editCase.court || ""}
                  onChange={(e) => setEditCase({ ...editCase, court: e.target.value })}
                  placeholder="Supreme Court of India"
                />
              </Field>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <Field label="Bench / Judges">
                  <Input
                    value={editCase.bench || ""}
                    onChange={(e) => setEditCase({ ...editCase, bench: e.target.value })}
                    placeholder="Chief Justice S.M. Sikri & Others"
                  />
                </Field>
                <Field label="Tags (comma-separated)">
                  <Input
                    value={(editCase.tags || []).join(", ")}
                    onChange={(e) =>
                      setEditCase({
                        ...editCase,
                        tags: e.target.value.split(",").map((t) => t.trim()).filter(Boolean),
                      })
                    }
                    placeholder="Constitution, Basic Structure, Article 368"
                  />
                </Field>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <Field label="Petitioners">
                  <Input
                    value={editCase.petitioners || ""}
                    onChange={(e) => setEditCase({ ...editCase, petitioners: e.target.value })}
                    placeholder="Kesavananda Bharati (And Others)"
                  />
                </Field>
                <Field label="Respondents">
                  <Input
                    value={editCase.respondents || ""}
                    onChange={(e) => setEditCase({ ...editCase, respondents: e.target.value })}
                    placeholder="State of Kerala (And Others)"
                  />
                </Field>
              </div>

              <Field label="Case Summary">
                <Textarea
                  rows={3}
                  value={editCase.summary || ""}
                  onChange={(e) => setEditCase({ ...editCase, summary: e.target.value })}
                  placeholder="Summary of judgment and principles established..."
                />
              </Field>

              <Field label="Simple Language Explanation">
                <Textarea
                  rows={3}
                  value={editCase.simpleExplanation || ""}
                  onChange={(e) => setEditCase({ ...editCase, simpleExplanation: e.target.value })}
                  placeholder="Easy-to-understand explanation for law students and citizens..."
                />
              </Field>

              <Field label="Judgment PDF Document URL">
                <Input
                  value={editCase.judgmentPdfUrl || ""}
                  onChange={(e) => setEditCase({ ...editCase, judgmentPdfUrl: e.target.value })}
                  placeholder="https://..."
                />
              </Field>

              <div className="flex items-center gap-2 pt-2">
                <input
                  type="checkbox"
                  id="case-published"
                  checked={editCase.published !== false}
                  onChange={(e) => setEditCase({ ...editCase, published: e.target.checked })}
                  className="size-4 rounded border-gray-300 text-primary focus:ring-primary"
                />
                <label htmlFor="case-published" className="text-sm font-medium">
                  Published in mobile app
                </label>
              </div>

              <DialogFooter className="pt-4">
                <Button type="button" variant="outline" onClick={() => setEditCase(null)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={saveBusy}>
                  {saveBusy ? "Saving..." : isNew ? "Create Case" : "Save Changes"}
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
            <AlertDialogTitle>Delete Case</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to permanently delete this case? This action cannot be undone.
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
