import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Pager } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { Act, Section } from "@/lib/types";
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
import { Plus, Search, Trash2, Edit, BookOpen, Upload, FileText, ChevronRight, Check } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/acts")({
  head: () => ({ meta: [{ title: "Acts & Sections — Admin" }] }),
  component: ActsAdmin,
});

function ActsAdmin() {
  const ready = useAdminGuard();
  const [items, setItems] = useState<Act[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const limit = 20;

  const [modalOpen, setModalOpen] = useState(false);
  const [importOpen, setImportOpen] = useState(false);
  const [viewingAct, setViewingAct] = useState<Act | null>(null);
  const [editingAct, setEditingAct] = useState<Act | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // Form State
  const [name, setName] = useState("");
  const [shortName, setShortName] = useState("");
  const [year, setYear] = useState<number>(new Date().getFullYear());
  const [type, setType] = useState("Central");
  const [description, setDescription] = useState("");
  const [sections, setSections] = useState<Section[]>([
    { number: "1", title: "Short title, extent and commencement", text: "" },
  ]);

  // Batch Import State
  const [importText, setImportText] = useState("");
  const [importPreview, setImportPreview] = useState<any[] | null>(null);
  const [importing, setImporting] = useState(false);

  function load(nextPage = page) {
    if (!ready) return;
    setLoading(true);
    setError(null);
    const params = new URLSearchParams({ all: "true", page: String(nextPage), limit: String(limit) });
    if (query) params.set("q", query);
    api<{ items: Act[]; total: number; page: number }>(`/api/acts?${params.toString()}`)
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
    setEditingAct(null);
    setName("");
    setShortName("");
    setYear(new Date().getFullYear());
    setType("Central");
    setDescription("");
    setSections([{ number: "1", title: "Short title, extent and commencement", text: "" }]);
    setModalOpen(true);
  }

  function openEdit(a: Act) {
    setEditingAct(a);
    setName(a.name || "");
    setShortName(a.shortName || "");
    setYear(a.year || new Date().getFullYear());
    setType(a.type || "Central");
    setDescription(a.description || "");
    setSections(a.sections && a.sections.length > 0 ? a.sections : [{ number: "1", title: "", text: "" }]);
    setModalOpen(true);
  }

  function addSectionField() {
    const nextNum = String(sections.length + 1);
    setSections([...sections, { number: nextNum, title: "", text: "" }]);
  }

  function removeSectionField(idx: number) {
    setSections(sections.filter((_, i) => i !== idx));
  }

  function updateSection(idx: number, field: keyof Section, val: string) {
    const next = [...sections];
    next[idx] = { ...next[idx], [field]: val };
    setSections(next);
  }

  async function saveAct() {
    if (!name.trim()) return;
    setSaving(true);
    try {
      const payload = {
        name: name.trim(),
        shortName: shortName.trim(),
        year: Number(year) || undefined,
        type,
        description,
        sections: sections.filter((s) => s.number.trim().length > 0),
      };

      if (editingAct) {
        await api(`/api/acts/${editingAct._id}`, { method: "PUT", body: payload });
      } else {
        await api("/api/acts", { method: "POST", body: payload });
      }
      setModalOpen(false);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to save Bare Act");
    } finally {
      setSaving(false);
    }
  }

  async function previewBatchImport() {
    if (!importText.trim()) return;
    setImporting(true);
    try {
      const res = await api<{ preview: any[] }>("/api/acts/import/preview", {
        method: "POST",
        body: { rawData: importText },
      });
      setImportPreview(res.preview || []);
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to parse import preview");
    } finally {
      setImporting(false);
    }
  }

  async function commitBatchImport() {
    if (!importPreview || importPreview.length === 0) return;
    setImporting(true);
    try {
      await api("/api/acts/import/confirm", {
        method: "POST",
        body: { acts: importPreview },
      });
      setImportOpen(false);
      setImportPreview(null);
      setImportText("");
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to commit batch import");
    } finally {
      setImporting(false);
    }
  }

  async function confirmDelete() {
    if (!deletingId) return;
    try {
      await api(`/api/acts/${deletingId}`, { method: "DELETE" });
      setDeletingId(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to delete act");
    }
  }

  return (
    <AdminShell
      title="Bare Acts & Legislation"
      subtitle="Publish, inspect and organize India Code statutes, central acts and interactive section accordions"
      actions={
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setImportOpen(true)} className="gap-2">
            <Upload className="size-4" /> Batch Import (JSON/CSV)
          </Button>
          <Button onClick={openCreate} className="gap-2 bg-primary hover:bg-primary/90 text-primary-foreground">
            <Plus className="size-4" /> Add Bare Act
          </Button>
        </div>
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
            placeholder="Search Bare Acts by name, abbreviation or year..."
            className="pl-9"
          />
        </div>
        <Button onClick={() => load(1)} variant="secondary">
          Search
        </Button>
      </div>

      {/* Main List */}
      {loading ? (
        <StateBlock message="Loading Bare Acts database..." loading />
      ) : error ? (
        <StateBlock message={error} onRetry={load} />
      ) : items.length === 0 ? (
        <StateBlock
          message="No Bare Acts found in the database. You can add one manually or use Batch Import."
          action={
            <Button onClick={openCreate} className="gap-2">
              <Plus className="size-4" /> Add First Bare Act
            </Button>
          }
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {items.map((act) => (
            <div
              key={act._id}
              className="flex flex-col justify-between rounded-lg border border-border bg-card p-5 shadow-sm transition-all hover:border-primary/40"
            >
              <div>
                <div className="flex items-center justify-between gap-2 mb-2">
                  <div className="flex items-center gap-2">
                    <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-bold text-primary">
                      {act.type || "Central"} Act
                    </span>
                    {act.year && (
                      <span className="text-xs text-muted-foreground font-medium">
                        {act.year}
                      </span>
                    )}
                  </div>
                  <span className="rounded-full bg-secondary/15 px-2.5 py-0.5 text-xs font-semibold text-secondary-foreground">
                    {act.sections?.length || 0} Sections
                  </span>
                </div>

                <h3 className="font-display text-base font-semibold text-card-foreground">
                  {act.name}
                </h3>

                {act.shortName && (
                  <p className="text-xs font-mono text-muted-foreground mt-0.5">
                    Abbreviation: {act.shortName}
                  </p>
                )}

                {act.description && (
                  <p className="mt-2 line-clamp-2 text-xs text-muted-foreground leading-relaxed">
                    {act.description}
                  </p>
                )}
              </div>

              {/* Actions */}
              <div className="mt-4 flex items-center justify-between border-t border-border/60 pt-3">
                <Button size="sm" variant="outline" onClick={() => setViewingAct(act)} className="gap-1.5 text-xs">
                  <BookOpen className="size-3.5" /> View Sections
                </Button>
                <div className="flex items-center gap-1">
                  <Button size="sm" variant="ghost" onClick={() => openEdit(act)} className="gap-1 text-xs">
                    <Edit className="size-3.5" /> Edit
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => setDeletingId(act._id)}
                    className="text-destructive hover:bg-destructive/10"
                  >
                    <Trash2 className="size-3.5" />
                  </Button>
                </div>
              </div>
            </div>
          ))}
          <div className="md:col-span-2">
            <Pager page={page} limit={limit} total={total} onPageChange={load} />
          </div>
        </div>
      )}

      {/* View Sections Modal */}
      {viewingAct && (
        <Dialog open={Boolean(viewingAct)} onOpenChange={() => setViewingAct(null)}>
          <DialogContent className="max-w-3xl max-h-[85vh] overflow-y-auto">
            <DialogHeader>
              <div className="flex items-center gap-2">
                <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-bold text-primary">
                  {viewingAct.type} Act {viewingAct.year || ""}
                </span>
                <span className="text-xs text-muted-foreground">
                  {viewingAct.sections?.length || 0} Sections
                </span>
              </div>
              <DialogTitle className="text-xl font-display mt-1">{viewingAct.name}</DialogTitle>
            </DialogHeader>

            <div className="space-y-3 py-3">
              {viewingAct.sections && viewingAct.sections.length > 0 ? (
                viewingAct.sections.map((s, idx) => (
                  <div key={idx} className="rounded-lg border border-border bg-muted/20 p-3.5 text-sm">
                    <div className="flex items-center gap-2 font-semibold text-foreground mb-1">
                      <span className="rounded bg-primary/15 px-1.5 py-0.5 text-xs font-bold text-primary">
                        Sec {s.number}
                      </span>
                      <span>{s.title || `Section ${s.number}`}</span>
                    </div>
                    {s.text && (
                      <p className="mt-2 text-xs leading-relaxed text-muted-foreground whitespace-pre-line">
                        {s.text}
                      </p>
                    )}
                    {s.explanation && (
                      <div className="mt-2 rounded bg-secondary/10 p-2 text-xs text-secondary-foreground border border-secondary/20">
                        <strong>Explanation:</strong> {s.explanation}
                      </div>
                    )}
                  </div>
                ))
              ) : (
                <p className="text-sm text-muted-foreground text-center py-6">No sections added to this act yet.</p>
              )}
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setViewingAct(null)}>
                Close
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* Create / Edit Act Modal */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-lg font-display">
              {editingAct ? "Edit Bare Act" : "Add Bare Act"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-3.5 py-2">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div className="md:col-span-2">
                <label className="text-xs font-semibold uppercase text-muted-foreground">Act Name *</label>
                <Input
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Indian Penal Code, 1860"
                  className="mt-1"
                />
              </div>

              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Short Abbr.</label>
                <Input
                  value={shortName}
                  onChange={(e) => setShortName(e.target.value)}
                  placeholder="e.g. IPC"
                  className="mt-1"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Enacted Year</label>
                <Input
                  type="number"
                  value={year}
                  onChange={(e) => setYear(Number(e.target.value))}
                  className="mt-1"
                />
              </div>

              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Act Type</label>
                <select
                  value={type}
                  onChange={(e) => setType(e.target.value)}
                  className="mt-1 flex h-9 w-full rounded-md border border-input bg-card px-3 text-sm"
                >
                  <option value="Central">Central Act</option>
                  <option value="State">State Act</option>
                  <option value="Constitutional">Constitutional</option>
                </select>
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold uppercase text-muted-foreground">Preamble / Description</label>
              <Textarea
                rows={2}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Brief description or preamble..."
                className="mt-1"
              />
            </div>

            {/* Sections Accordion Builder */}
            <div className="border-t border-border pt-3">
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-bold uppercase tracking-wider text-primary">
                  Sections ({sections.length})
                </label>
                <Button size="sm" variant="outline" onClick={addSectionField} className="gap-1 h-7 text-xs">
                  <Plus className="size-3" /> Add Section
                </Button>
              </div>

              <div className="space-y-3 max-h-60 overflow-y-auto pr-1">
                {sections.map((sec, idx) => (
                  <div key={idx} className="rounded-lg border border-border/80 bg-muted/20 p-3 text-xs space-y-2">
                    <div className="flex items-center gap-2">
                      <div className="w-20">
                        <Input
                          value={sec.number}
                          onChange={(e) => updateSection(idx, "number", e.target.value)}
                          placeholder="Sec #"
                          className="h-8 text-xs font-bold"
                        />
                      </div>
                      <div className="flex-1">
                        <Input
                          value={sec.title || ""}
                          onChange={(e) => updateSection(idx, "title", e.target.value)}
                          placeholder="Section Title"
                          className="h-8 text-xs"
                        />
                      </div>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => removeSectionField(idx)}
                        className="h-8 px-2 text-destructive"
                      >
                        <Trash2 className="size-3.5" />
                      </Button>
                    </div>

                    <Textarea
                      rows={2}
                      value={sec.text || ""}
                      onChange={(e) => updateSection(idx, "text", e.target.value)}
                      placeholder="Section Text / Sub-clauses..."
                      className="text-xs"
                    />
                  </div>
                ))}
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={saveAct} disabled={saving || !name.trim()}>
              {saving ? "Saving..." : editingAct ? "Update Act" : "Save Act"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Batch Import Modal */}
      <Dialog open={importOpen} onOpenChange={setImportOpen}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-lg font-display">Batch Import Bare Acts (JSON / CSV)</DialogTitle>
          </DialogHeader>

          <div className="space-y-3 py-2 text-sm">
            <p className="text-xs text-muted-foreground">
              Paste JSON or India Code CSV data below to preview before importing into the database.
            </p>

            <Textarea
              rows={8}
              value={importText}
              onChange={(e) => setImportText(e.target.value)}
              placeholder={`[
  {
    "name": "Constitution of India",
    "shortName": "COI",
    "year": 1950,
    "sections": [
      { "number": "14", "title": "Equality before law", "text": "The State shall not deny to any person..." },
      { "number": "21", "title": "Protection of life and personal liberty", "text": "No person shall be deprived of his life..." }
    ]
  }
]`}
              className="font-mono text-xs"
            />

            <Button onClick={previewBatchImport} disabled={importing || !importText.trim()} variant="secondary" className="gap-2">
              <FileText className="size-4" /> {importing ? "Parsing Preview..." : "Generate Preview"}
            </Button>

            {importPreview && importPreview.length > 0 && (
              <div className="mt-3 rounded-lg border border-border bg-card p-3">
                <h4 className="font-bold text-xs uppercase text-primary mb-2">Import Preview ({importPreview.length} Acts)</h4>
                <div className="space-y-2 max-h-48 overflow-y-auto text-xs">
                  {importPreview.map((item, idx) => (
                    <div key={idx} className="flex items-center justify-between border-b border-border/50 py-1.5">
                      <span className="font-medium text-foreground">{item.name} ({item.year || "N/A"})</span>
                      <span className="text-muted-foreground">{item.sections?.length || 0} sections</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setImportOpen(false)}>
              Cancel
            </Button>
            {importPreview && importPreview.length > 0 && (
              <Button onClick={commitBatchImport} disabled={importing} className="gap-2 bg-primary">
                <Check className="size-4" /> {importing ? "Importing..." : "Confirm & Import Acts"}
              </Button>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={Boolean(deletingId)} onOpenChange={() => setDeletingId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure you want to delete this Bare Act?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently remove the act and all its sections from the app.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Delete Act
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  );
}
