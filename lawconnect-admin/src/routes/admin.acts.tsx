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
import type { Act, Section } from "@/lib/types";
import { Plus, Search, Trash2, Edit3, ChevronDown, ChevronRight } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/acts")({
  component: ActsPage,
});

function ActsPage() {
  const ready = useAdminGuard();
  const [acts, setActs] = useState<Act[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [expandedActId, setExpandedActId] = useState<string | null>(null);

  // Dialogs
  const [editAct, setEditAct] = useState<Partial<Act> | null>(null);
  const [isNewAct, setIsNewAct] = useState(false);
  const [saveBusy, setSaveBusy] = useState(false);
  const [deleteActId, setDeleteActId] = useState<string | null>(null);

  // Section Dialog
  const [sectionModalActId, setSectionModalActId] = useState<string | null>(null);
  const [newSection, setNewSection] = useState<Partial<Section>>({ number: "", title: "", text: "", explanation: "" });

  async function loadActs() {
    try {
      setLoading(true);
      setError(null);
      const params = new URLSearchParams({ all: "true" });
      if (search.trim()) params.set("q", search.trim());
      const res = await api<{ items: Act[]; total: number }>(`/api/acts?${params.toString()}`);
      setActs(res.items || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load acts");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!ready) return;
    loadActs();
  }, [ready]);

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    loadActs();
  }

  function openCreateAct() {
    setIsNewAct(true);
    setEditAct({
      name: "",
      shortName: "",
      year: new Date().getFullYear(),
      type: "Central",
      description: "",
      sections: [],
      published: true,
    });
  }

  function openEditAct(a: Act) {
    setIsNewAct(false);
    setEditAct({ ...a });
  }

  async function handleSaveAct(e: React.FormEvent) {
    e.preventDefault();
    if (!editAct || !editAct.name) return;
    setSaveBusy(true);
    try {
      if (isNewAct) {
        await api("/api/acts", { method: "POST", body: editAct });
      } else {
        await api(`/api/acts/${editAct._id}`, { method: "PUT", body: editAct });
      }
      setEditAct(null);
      await loadActs();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Save failed");
    } finally {
      setSaveBusy(false);
    }
  }

  async function handleDeleteAct() {
    if (!deleteActId) return;
    try {
      await api(`/api/acts/${deleteActId}`, { method: "DELETE" });
      setDeleteActId(null);
      await loadActs();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Delete failed");
    }
  }

  async function handleAddSection(e: React.FormEvent) {
    e.preventDefault();
    if (!sectionModalActId || !newSection.number) return;
    try {
      await api(`/api/acts/${sectionModalActId}/sections`, {
        method: "POST",
        body: newSection,
      });
      setSectionModalActId(null);
      setNewSection({ number: "", title: "", text: "", explanation: "" });
      await loadActs();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Failed to add section");
    }
  }

  async function handleDeleteSection(actId: string, sectionId?: string) {
    if (!sectionId) return;
    if (!window.confirm("Remove this section from the act?")) return;
    try {
      await api(`/api/acts/${actId}/sections/${sectionId}`, { method: "DELETE" });
      await loadActs();
    } catch (err) {
      alert(err instanceof Error ? err.message : "Failed to remove section");
    }
  }

  return (
    <AdminShell
      title="Acts & Sections"
      subtitle="Manage bare acts, penal codes, statutory laws, and section explanations"
      actions={
        <Button onClick={openCreateAct} className="gap-2">
          <Plus className="size-4" /> Add Act
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
              placeholder="Search acts, codes or sections..."
              className="pl-9"
            />
          </div>
          <Button type="submit" variant="secondary">Search</Button>
        </form>

        <StateBlock
          loading={loading}
          error={error}
          empty={!loading && acts.length === 0}
          emptyText="No acts found."
        />

        {!loading && acts.length > 0 ? (
          <div className="space-y-3">
            {acts.map((act) => {
              const expanded = expandedActId === act._id;
              return (
                <Panel key={act._id} className="p-4 transition hover:border-primary/40">
                  <div className="flex flex-col justify-between gap-3 md:flex-row md:items-center">
                    <div className="space-y-1 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <button
                          type="button"
                          onClick={() => setExpandedActId(expanded ? null : act._id)}
                          className="flex items-center gap-1.5 font-display text-base font-semibold hover:text-primary transition-colors text-left"
                        >
                          {expanded ? <ChevronDown className="size-4" /> : <ChevronRight className="size-4" />}
                          {act.name}
                        </button>
                        {act.shortName ? (
                          <span className="rounded bg-muted px-2 py-0.5 text-xs text-muted-foreground font-mono">
                            {act.shortName}
                          </span>
                        ) : null}
                        <span className="rounded-full bg-accent/20 px-2 py-0.5 text-xs font-medium text-accent-foreground">
                          {act.type || "Central"}
                        </span>
                        <span className="rounded-full bg-primary/10 px-2 py-0.5 text-xs text-primary font-medium">
                          {(act.sections || []).length} Sections
                        </span>
                      </div>
                      {act.description ? (
                        <p className="text-xs text-muted-foreground">{act.description}</p>
                      ) : null}
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                      <Button
                        variant="secondary"
                        size="sm"
                        onClick={() => {
                          setSectionModalActId(act._id);
                          setNewSection({ number: "", title: "", text: "", explanation: "" });
                        }}
                        className="gap-1"
                      >
                        <Plus className="size-3.5" /> Add Section
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => openEditAct(act)} className="gap-1">
                        <Edit3 className="size-3.5" /> Edit
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => setDeleteActId(act._id)}
                        className="text-destructive hover:bg-destructive/10"
                      >
                        <Trash2 className="size-3.5" />
                      </Button>
                    </div>
                  </div>

                  {/* Expanded Sections */}
                  {expanded ? (
                    <div className="mt-4 border-t border-border pt-3 space-y-2">
                      <h4 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                        Sections in this Act:
                      </h4>
                      {(act.sections || []).length === 0 ? (
                        <p className="text-xs text-muted-foreground italic">No sections added yet.</p>
                      ) : (
                        <div className="grid gap-2 sm:grid-cols-2">
                          {act.sections.map((s) => (
                            <div key={s._id || s.number} className="rounded-md border border-border/60 bg-muted/30 p-3 space-y-1 text-xs">
                              <div className="flex items-center justify-between">
                                <span className="font-semibold text-primary">{s.number}</span>
                                <button
                                  type="button"
                                  onClick={() => handleDeleteSection(act._id, s._id)}
                                  className="text-muted-foreground hover:text-destructive"
                                  title="Delete Section"
                                >
                                  <Trash2 className="size-3" />
                                </button>
                              </div>
                              {s.title ? <p className="font-medium">{s.title}</p> : null}
                              {s.text ? <p className="text-muted-foreground line-clamp-2">{s.text}</p> : null}
                              {s.explanation ? (
                                <p className="text-[11px] text-accent-foreground/80 bg-accent/10 rounded p-1">
                                  {s.explanation}
                                </p>
                              ) : null}
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  ) : null}
                </Panel>
              );
            })}
          </div>
        ) : null}
      </div>

      {/* Edit / Create Act Modal */}
      <Dialog open={!!editAct} onOpenChange={(open) => !open && setEditAct(null)}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{isNewAct ? "Add Bare Act / Code" : "Edit Act"}</DialogTitle>
          </DialogHeader>

          {editAct ? (
            <form onSubmit={handleSaveAct} className="space-y-4 py-2">
              <Field label="Act Full Name *">
                <Input
                  required
                  value={editAct.name || ""}
                  onChange={(e) => setEditAct({ ...editAct, name: e.target.value })}
                  placeholder="e.g. Constitution of India / Bharatiya Nyaya Sanhita"
                />
              </Field>

              <div className="grid grid-cols-2 gap-3">
                <Field label="Short Name / Acronym">
                  <Input
                    value={editAct.shortName || ""}
                    onChange={(e) => setEditAct({ ...editAct, shortName: e.target.value })}
                    placeholder="e.g. BNS / IPC"
                  />
                </Field>
                <Field label="Enactment Year">
                  <Input
                    type="number"
                    value={editAct.year || ""}
                    onChange={(e) => setEditAct({ ...editAct, year: Number(e.target.value) })}
                    placeholder="1950"
                  />
                </Field>
              </div>

              <Field label="Jurisdiction / Type">
                <select
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                  value={editAct.type || "Central"}
                  onChange={(e) => setEditAct({ ...editAct, type: e.target.value })}
                >
                  <option value="Central">Central Act</option>
                  <option value="State">State Act</option>
                </select>
              </Field>

              <Field label="Description / Overview">
                <Textarea
                  rows={3}
                  value={editAct.description || ""}
                  onChange={(e) => setEditAct({ ...editAct, description: e.target.value })}
                  placeholder="Brief overview or language support details..."
                />
              </Field>

              <DialogFooter className="pt-3">
                <Button type="button" variant="outline" onClick={() => setEditAct(null)}>
                  Cancel
                </Button>
                <Button type="submit" disabled={saveBusy}>
                  {saveBusy ? "Saving..." : isNewAct ? "Create Act" : "Save Changes"}
                </Button>
              </DialogFooter>
            </form>
          ) : null}
        </DialogContent>
      </Dialog>

      {/* Add Section Modal */}
      <Dialog open={!!sectionModalActId} onOpenChange={(open) => !open && setSectionModalActId(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Add Section / Article</DialogTitle>
          </DialogHeader>

          <form onSubmit={handleAddSection} className="space-y-3 py-2">
            <Field label="Section / Article Number *">
              <Input
                required
                value={newSection.number || ""}
                onChange={(e) => setNewSection({ ...newSection, number: e.target.value })}
                placeholder="e.g. Article 21 / Section 302"
              />
            </Field>

            <Field label="Section Title">
              <Input
                value={newSection.title || ""}
                onChange={(e) => setNewSection({ ...newSection, title: e.target.value })}
                placeholder="e.g. Protection of life and personal liberty"
              />
            </Field>

            <Field label="Full Legal Text">
              <Textarea
                rows={3}
                value={newSection.text || ""}
                onChange={(e) => setNewSection({ ...newSection, text: e.target.value })}
                placeholder="Exact statutory text of the section..."
              />
            </Field>

            <Field label="Simple Explanation / Student Notes">
              <Textarea
                rows={2}
                value={newSection.explanation || ""}
                onChange={(e) => setNewSection({ ...newSection, explanation: e.target.value })}
                placeholder="Simplified layman breakdown..."
              />
            </Field>

            <DialogFooter className="pt-3">
              <Button type="button" variant="outline" onClick={() => setSectionModalActId(null)}>
                Cancel
              </Button>
              <Button type="submit">Add Section</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Act Confirmation */}
      <AlertDialog open={!!deleteActId} onOpenChange={(open) => !open && setDeleteActId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Act</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete this Act and all of its sections?
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDeleteAct} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  );
}
