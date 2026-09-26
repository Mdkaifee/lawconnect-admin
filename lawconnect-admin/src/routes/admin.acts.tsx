import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Field } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { Act, Section } from "@/lib/types";
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
import { Plus, Search, Trash2, Edit, FileUp, AlertTriangle, CheckCircle2 } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/acts")({
  head: () => ({ meta: [{ title: "Acts & Sections — Admin" }] }),
  component: ActsAdmin,
});

const EMPTY_ACT: Partial<Act> = {
  name: "",
  shortName: "",
  year: new Date().getFullYear(),
  type: "Central",
  description: "",
  sections: [],
  published: true,
};

function ActsAdmin() {
  const ready = useAdminGuard();
  const [items, setItems] = useState<Act[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("All");

  const [editing, setEditing] = useState<Partial<Act> | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // Section inline state
  const [newSecNum, setNewSecNum] = useState("");
  const [newSecTitle, setNewSecTitle] = useState("");
  const [newSecText, setNewSecText] = useState("");

  // Import JSON / CSV Modal State
  const [importOpen, setImportOpen] = useState(false);
  const [importFormat, setImportFormat] = useState<"json" | "csv">("json");
  const [importData, setImportData] = useState("");
  const [importPreview, setImportPreview] = useState<any>(null);
  const [importing, setImporting] = useState(false);
  const [overwriteDuplicates, setOverwriteDuplicates] = useState(false);

  function load() {
    if (!ready) return;
    setLoading(true);
    setError(null);
    const params = new URLSearchParams({ all: "true" });
    if (query) params.set("q", query);
    if (typeFilter !== "All") params.set("type", typeFilter);

    api<{ items: Act[] }>(`/api/acts?${params.toString()}`)
      .then((res) => setItems(res.items))
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, [ready, typeFilter]);

  async function save() {
    if (!editing || !editing.name) return;
    setSaving(true);
    try {
      if (editing._id) {
        await api(`/api/acts/${editing._id}`, { method: "PUT", body: editing });
      } else {
        await api("/api/acts", { method: "POST", body: editing });
      }
      setEditing(null);
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to save act");
    } finally {
      setSaving(false);
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

  function addSectionToEditing() {
    if (!newSecNum.trim()) return;
    const currentSections = editing?.sections ?? [];
    setEditing({
      ...editing,
      sections: [
        ...currentSections,
        {
          number: newSecNum.trim(),
          title: newSecTitle.trim(),
          text: newSecText.trim(),
        },
      ],
    });
    setNewSecNum("");
    setNewSecTitle("");
    setNewSecText("");
  }

  function removeSectionFromEditing(index: number) {
    const currentSections = [...(editing?.sections ?? [])];
    currentSections.splice(index, 1);
    setEditing({ ...editing, sections: currentSections });
  }

  // Import handlers
  async function handlePreviewImport() {
    if (!importData.trim()) return;
    setImporting(true);
    try {
      const res = await api("/api/acts/import/preview", {
        method: "POST",
        body: { format: importFormat, data: importData },
      });
      setImportPreview(res);
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to parse import data");
    } finally {
      setImporting(false);
    }
  }

  async function handleConfirmImport() {
    if (!importPreview?.acts || importPreview.acts.length === 0) return;
    setImporting(true);
    try {
      const res = await api<{ message: string }>("/api/acts/import/confirm", {
        method: "POST",
        body: { acts: importPreview.acts, overwriteDuplicates },
      });
      alert(res.message);
      setImportOpen(false);
      setImportPreview(null);
      setImportData("");
      load();
    } catch (e) {
      alert(e instanceof Error ? e.message : "Failed to complete import");
    } finally {
      setImporting(false);
    }
  }

  return (
    <AdminShell
      title="Acts & Sections"
      subtitle="Manage Bare Acts, section breakdowns, and India Code references"
      actions={
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setImportOpen(true)} className="gap-2">
            <FileUp className="size-4" /> Import JSON / CSV
          </Button>
          <Button onClick={() => setEditing({ ...EMPTY_ACT })} className="gap-2">
            <Plus className="size-4" /> Add Bare Act
          </Button>
        </div>
      }
    >
      <div className="mb-4 flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-[240px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-muted-foreground" />
          <Input
            placeholder="Search bare acts by name, short title, or section..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && load()}
            className="pl-9"
          />
        </div>
        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm"
        >
          <option value="All">All Jurisdictions</option>
          <option value="Central">Central Acts</option>
          <option value="State">State Acts</option>
        </select>
        <Button variant="outline" onClick={load}>
          Search
        </Button>
      </div>

      <StateBlock loading={loading} error={error} empty={!loading && items.length === 0} emptyText="No bare acts found." />

      {!loading && items.length > 0 ? (
        <Panel className="divide-y divide-border">
          {items.map((act) => (
            <div key={act._id} className="flex flex-wrap items-center justify-between gap-4 p-4 hover:bg-muted/30">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">
                    {act.type || "Central"}
                  </span>
                  {act.year ? <span className="text-xs text-muted-foreground">{act.year}</span> : null}
                  <span className="rounded bg-accent/20 px-2 py-0.5 text-xs font-semibold text-accent-foreground">
                    {act.sections?.length ?? 0} Sections
                  </span>
                </div>
                <h3 className="mt-1 font-display text-base font-semibold">{act.name}</h3>
                {act.shortName ? <p className="text-xs font-medium text-muted-foreground">{act.shortName}</p> : null}
              </div>
              <div className="flex items-center gap-2">
                <Button size="sm" variant="outline" onClick={() => setEditing(act)}>
                  <Edit className="size-4" />
                </Button>
                <Button size="sm" variant="ghost" className="text-destructive" onClick={() => setDeletingId(act._id)}>
                  <Trash2 className="size-4" />
                </Button>
              </div>
            </div>
          ))}
        </Panel>
      ) : null}

      {/* Edit / Create Bare Act Dialog */}
      <Dialog open={Boolean(editing)} onOpenChange={(o) => !o && setEditing(null)}>
        <DialogContent className="max-h-[90vh] overflow-y-auto max-w-3xl">
          <DialogHeader>
            <DialogTitle>{editing?._id ? "Edit Bare Act" : "Add Bare Act"}</DialogTitle>
          </DialogHeader>
          {editing ? (
            <div className="space-y-4 py-2">
              <Field label="Full Act Name *">
                <Input
                  value={editing.name ?? ""}
                  onChange={(e) => setEditing({ ...editing, name: e.target.value })}
                  placeholder="e.g. Bharatiya Nyaya Sanhita, 2023"
                />
              </Field>
              <div className="grid gap-4 sm:grid-cols-3">
                <Field label="Short Title">
                  <Input
                    value={editing.shortName ?? ""}
                    onChange={(e) => setEditing({ ...editing, shortName: e.target.value })}
                    placeholder="e.g. BNS"
                  />
                </Field>
                <Field label="Year">
                  <Input
                    type="number"
                    value={editing.year ?? ""}
                    onChange={(e) => setEditing({ ...editing, year: Number(e.target.value) || undefined })}
                  />
                </Field>
                <Field label="Type">
                  <select
                    value={editing.type ?? "Central"}
                    onChange={(e) => setEditing({ ...editing, type: e.target.value })}
                    className="h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  >
                    <option value="Central">Central</option>
                    <option value="State">State</option>
                  </select>
                </Field>
              </div>
              <Field label="Description / Enactment Info">
                <Input
                  value={editing.description ?? ""}
                  onChange={(e) => setEditing({ ...editing, description: e.target.value })}
                  placeholder="e.g. Comprehensive criminal code replacing IPC 1860"
                />
              </Field>

              {/* Sections Editor */}
              <div className="border-t border-border pt-4">
                <h4 className="font-display text-sm font-semibold mb-2">Sections ({editing.sections?.length ?? 0})</h4>
                <div className="space-y-2 mb-4 max-h-48 overflow-y-auto border border-border rounded-md p-2">
                  {editing.sections && editing.sections.length > 0 ? (
                    editing.sections.map((s, idx) => (
                      <div key={idx} className="flex items-center justify-between p-2 bg-muted/50 rounded text-xs">
                        <div>
                          <span className="font-bold text-primary mr-2">{s.number}</span>
                          <span>{s.title}</span>
                        </div>
                        <Button
                          size="sm"
                          variant="ghost"
                          className="h-6 w-6 p-0 text-destructive"
                          onClick={() => removeSectionFromEditing(idx)}
                        >
                          <Trash2 className="size-3" />
                        </Button>
                      </div>
                    ))
                  ) : (
                    <p className="text-xs text-muted-foreground p-2 text-center">No sections added yet.</p>
                  )}
                </div>

                {/* Add new section row */}
                <div className="bg-muted/30 p-3 rounded-md space-y-2">
                  <p className="text-xs font-semibold text-muted-foreground">Add New Section</p>
                  <div className="grid gap-2 sm:grid-cols-3">
                    <Input
                      placeholder="Section No. (e.g. Section 302)"
                      value={newSecNum}
                      onChange={(e) => setNewSecNum(e.target.value)}
                    />
                    <Input
                      placeholder="Title / Heading"
                      value={newSecTitle}
                      onChange={(e) => setNewSecTitle(e.target.value)}
                      className="sm:col-span-2"
                    />
                  </div>
                  <Textarea
                    placeholder="Full statutory text of section..."
                    rows={2}
                    value={newSecText}
                    onChange={(e) => setNewSecText(e.target.value)}
                  />
                  <Button size="sm" variant="secondary" onClick={addSectionToEditing} disabled={!newSecNum.trim()}>
                    Add Section
                  </Button>
                </div>
              </div>

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
            <Button onClick={save} disabled={saving || !editing?.name}>
              {saving ? "Saving…" : "Save Act"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* JSON / CSV Import Modal */}
      <Dialog open={importOpen} onOpenChange={setImportOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto max-w-3xl">
          <DialogHeader>
            <DialogTitle>Import Acts & Sections (JSON or CSV)</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="flex gap-4">
              <Button
                variant={importFormat === "json" ? "default" : "outline"}
                size="sm"
                onClick={() => setImportFormat("json")}
              >
                JSON Format
              </Button>
              <Button
                variant={importFormat === "csv" ? "default" : "outline"}
                size="sm"
                onClick={() => setImportFormat("csv")}
              >
                CSV Format
              </Button>
            </div>

            <Field label={`Paste ${importFormat.toUpperCase()} Data`}>
              <Textarea
                rows={8}
                value={importData}
                onChange={(e) => setImportData(e.target.value)}
                placeholder={
                  importFormat === "json"
                    ? `[\n  {\n    "name": "Indian Contract Act, 1872",\n    "shortName": "Contract Act",\n    "year": 1872,\n    "type": "Central",\n    "sections": [\n      {"number": "Section 10", "title": "What agreements are contracts", "text": "All agreements are contracts if they are made by free consent..."}\n    ]\n  }\n]`
                    : `actName,shortName,year,type,sectionNumber,sectionTitle,sectionText\nIndian Contract Act,Contract Act,1872,Central,Section 10,What agreements are contracts,"All agreements are contracts if..."`
                }
              />
            </Field>

            <Button onClick={handlePreviewImport} disabled={importing || !importData.trim()}>
              {importing ? "Validating…" : "Validate & Preview Import"}
            </Button>

            {/* Validation & Preview Section */}
            {importPreview ? (
              <div className="border border-border rounded-lg p-4 bg-card space-y-3">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="size-5 text-green-600" />
                  <h4 className="font-display font-semibold text-base">Validation Summary</h4>
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                  <div className="bg-muted p-2 rounded">
                    <p className="text-muted-foreground">Parsed Acts</p>
                    <p className="text-base font-bold">{importPreview.summary.totalActsParsed}</p>
                  </div>
                  <div className="bg-muted p-2 rounded">
                    <p className="text-muted-foreground">Total Sections</p>
                    <p className="text-base font-bold">{importPreview.summary.totalSectionsCount}</p>
                  </div>
                  <div className="bg-muted p-2 rounded">
                    <p className="text-muted-foreground">Duplicates</p>
                    <p className="text-base font-bold text-amber-600">{importPreview.summary.duplicateCount}</p>
                  </div>
                  <div className="bg-muted p-2 rounded">
                    <p className="text-muted-foreground">Errors</p>
                    <p className="text-base font-bold text-destructive">{importPreview.summary.errorCount}</p>
                  </div>
                </div>

                {/* Warnings / Errors */}
                {importPreview.warnings?.length > 0 ? (
                  <div className="text-xs text-amber-600 space-y-1 bg-amber-50 p-2 rounded border border-amber-200">
                    <p className="font-semibold flex items-center gap-1">
                      <AlertTriangle className="size-3" /> Warnings:
                    </p>
                    {importPreview.warnings.map((w: any, idx: number) => (
                      <p key={idx}>• {w.message}</p>
                    ))}
                  </div>
                ) : null}

                <div className="flex items-center justify-between pt-2">
                  <label className="flex items-center gap-2 text-xs font-medium cursor-pointer">
                    <input
                      type="checkbox"
                      checked={overwriteDuplicates}
                      onChange={(e) => setOverwriteDuplicates(e.target.checked)}
                      className="rounded border-input"
                    />
                    Overwrite / update existing duplicate acts in database
                  </label>
                </div>
              </div>
            ) : null}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setImportOpen(false)}>
              Cancel
            </Button>
            {importPreview ? (
              <Button onClick={handleConfirmImport} disabled={importing}>
                {importing ? "Importing…" : "Confirm & Import into Database"}
              </Button>
            ) : null}
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Alert */}
      <AlertDialog open={Boolean(deletingId)} onOpenChange={(o) => !o && setDeletingId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Bare Act</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete this Bare Act and all associated sections?
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
