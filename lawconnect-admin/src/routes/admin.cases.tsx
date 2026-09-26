import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock, Field } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { LawCase } from "@/lib/types";
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
import { Plus, Search, Trash2, Edit, Eye, Gavel, ExternalLink, Download } from "lucide-react";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/cases")({
  head: () => ({ meta: [{ title: "Cases & Judgments — Admin" }] }),
  component: CasesAdmin,
});

function CasesAdmin() {
  const ready = useAdminGuard();
  const [items, setItems] = useState<LawCase[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [courtFilter, setCourtFilter] = useState("all");

  const [modalOpen, setModalOpen] = useState(false);
  const [editingCase, setEditingCase] = useState<LawCase | null>(null);
  const [viewingCase, setViewingCase] = useState<LawCase | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // Form State
  const [title, setTitle] = useState("");
  const [citation, setCitation] = useState("");
  const [court, setCourt] = useState("Supreme Court of India");
  const [dateOfJudgment, setDateOfJudgment] = useState("");
  const [bench, setBench] = useState("");
  const [petitioners, setPetitioners] = useState("");
  const [respondents, setRespondents] = useState("");
  const [summary, setSummary] = useState("");
  const [simpleExplanation, setSimpleExplanation] = useState("");
  const [fullText, setFullText] = useState("");
  const [judgmentPdfUrl, setJudgmentPdfUrl] = useState("");
  const [published, setPublished] = useState(true);

  function load() {
    if (!ready) return;
    setLoading(true);
    setError(null);

    const params = new URLSearchParams();
    if (query) params.set("q", query);
    if (courtFilter !== "all") params.set("court", courtFilter);

    api<{ items: LawCase[] }>(`/api/cases?${params.toString()}`)
      .then((res) => setItems(res.items || []))
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, [ready]);

  function openCreate() {
    setEditingCase(null);
    setTitle("");
    setCitation("");
    setCourt("Supreme Court of India");
    setDateOfJudgment(new Date().toISOString().slice(0, 10));
    setBench("");
    setPetitioners("");
    setRespondents("");
    setSummary("");
    setSimpleExplanation("");
    setFullText("");
    setJudgmentPdfUrl("");
    setPublished(true);
    setModalOpen(true);
  }

  function openEdit(c: LawCase) {
    setEditingCase(c);
    setTitle(c.title || "");
    setCitation(c.citation || "");
    setCourt(c.court || "Supreme Court of India");
    setDateOfJudgment(c.dateOfJudgment ? c.dateOfJudgment.slice(0, 10) : "");
    setBench(c.bench || "");
    setPetitioners(c.petitioners || "");
    setRespondents(c.respondents || "");
    setSummary(c.summary || "");
    setSimpleExplanation(c.simpleExplanation || "");
    setFullText(c.fullText || "");
    setJudgmentPdfUrl(c.judgmentPdfUrl || "");
    setPublished(c.published !== false);
    setModalOpen(true);
  }

  async function saveCase() {
    if (!title.trim()) return;
    setSaving(true);
    try {
      const payload = {
        title: title.trim(),
        citation: citation.trim(),
        court,
        dateOfJudgment,
        bench,
        petitioners,
        respondents,
        summary,
        simpleExplanation,
        fullText,
        judgmentPdfUrl,
        published,
      };

      if (editingCase) {
        await api(`/api/cases/${editingCase._id}`, { method: "PUT", body: payload });
      } else {
        await api("/api/cases", { method: "POST", body: payload });
      }
      setModalOpen(false);
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

  const courts = ["all", "Supreme Court of India", "Delhi High Court", "Bombay High Court", "Allahabad High Court", "Calcutta High Court", "Madras High Court", "Karnataka High Court"];

  return (
    <AdminShell
      title="Cases & Judgments"
      subtitle="Publish, inspect and manage landmark judgments, case briefs and Kanoon citations"
      actions={
        <Button onClick={openCreate} className="gap-2 bg-primary hover:bg-primary/90 text-primary-foreground">
          <Plus className="size-4" /> Add Case Judgment
        </Button>
      }
    >
      {/* Search & Filter Bar */}
      <div className="mb-6 flex flex-wrap items-center gap-3">
        <div className="relative min-w-64 flex-1">
          <Search className="absolute left-3 top-2.5 size-4 text-muted-foreground" />
          <Input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && load()}
            placeholder="Search cases by title, citation or keywords..."
            className="pl-9"
          />
        </div>

        <select
          value={courtFilter}
          onChange={(e) => {
            setCourtFilter(e.target.value);
            setTimeout(load, 50);
          }}
          className="h-10 rounded-md border border-input bg-card px-3 text-sm"
        >
          <option value="all">All Courts</option>
          <option value="Supreme Court of India">Supreme Court of India</option>
          <option value="Delhi High Court">Delhi High Court</option>
          <option value="Bombay High Court">Bombay High Court</option>
          <option value="Allahabad High Court">Allahabad High Court</option>
          <option value="Calcutta High Court">Calcutta High Court</option>
          <option value="Madras High Court">Madras High Court</option>
        </select>

        <Button onClick={load} variant="secondary">
          Search
        </Button>
      </div>

      {/* Main List */}
      {loading ? (
        <StateBlock message="Loading cases and judgments database..." loading />
      ) : error ? (
        <StateBlock message={error} onRetry={load} />
      ) : items.length === 0 ? (
        <StateBlock
          message="No case judgments found. Tap 'Add Case Judgment' above to create your first judgment."
          action={
            <Button onClick={openCreate} className="gap-2">
              <Plus className="size-4" /> Add First Case
            </Button>
          }
        />
      ) : (
        <div className="space-y-3">
          {items.map((c) => (
            <div
              key={c._id}
              className="flex flex-col md:flex-row md:items-center justify-between gap-4 rounded-lg border border-border bg-card p-5 shadow-sm transition-all hover:border-primary/40"
            >
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2 mb-1.5">
                  <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-semibold text-primary">
                    {c.court || "Supreme Court"}
                  </span>
                  {c.citation && (
                    <span className="rounded bg-secondary/20 px-2 py-0.5 text-xs font-mono text-secondary-foreground font-medium">
                      {c.citation}
                    </span>
                  )}
                  {c.dateOfJudgment && (
                    <span className="text-xs text-muted-foreground">
                      {c.dateOfJudgment.slice(0, 10)}
                    </span>
                  )}
                </div>

                <h3 className="font-display text-base font-semibold text-card-foreground">
                  {c.title}
                </h3>

                {c.summary && (
                  <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">
                    {c.summary}
                  </p>
                )}

                {c.bench && (
                  <p className="mt-1 text-xs text-muted-foreground">
                    <strong className="font-medium text-foreground">Bench:</strong> {c.bench}
                  </p>
                )}
              </div>

              {/* Actions */}
              <div className="flex shrink-0 items-center gap-2 self-end md:self-center">
                <Button size="sm" variant="outline" onClick={() => setViewingCase(c)} className="gap-1.5">
                  <Eye className="size-3.5" /> View
                </Button>
                <Button size="sm" variant="outline" onClick={() => openEdit(c)} className="gap-1.5">
                  <Edit className="size-3.5" /> Edit
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => setDeletingId(c._id)}
                  className="text-destructive hover:bg-destructive/10"
                >
                  <Trash2 className="size-4" />
                </Button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* View Case Modal */}
      {viewingCase && (
        <Dialog open={Boolean(viewingCase)} onOpenChange={() => setViewingCase(null)}>
          <DialogContent className="max-w-3xl max-h-[85vh] overflow-y-auto">
            <DialogHeader>
              <div className="flex items-center gap-2">
                <span className="rounded bg-primary/10 px-2 py-0.5 text-xs font-bold text-primary">
                  {viewingCase.court || "Court Judgment"}
                </span>
                {viewingCase.citation && (
                  <span className="font-mono text-xs text-muted-foreground">
                    {viewingCase.citation}
                  </span>
                )}
              </div>
              <DialogTitle className="text-xl font-display mt-1">{viewingCase.title}</DialogTitle>
            </DialogHeader>

            <div className="space-y-4 py-3 text-sm">
              {viewingCase.bench && (
                <div>
                  <h4 className="font-semibold text-xs uppercase tracking-wider text-muted-foreground mb-1">Bench / Judges</h4>
                  <p>{viewingCase.bench}</p>
                </div>
              )}

              {viewingCase.summary && (
                <div>
                  <h4 className="font-semibold text-xs uppercase tracking-wider text-muted-foreground mb-1">Case Summary</h4>
                  <p className="whitespace-pre-line leading-relaxed text-foreground/90 bg-muted/30 p-3.5 rounded-lg border border-border">
                    {viewingCase.summary}
                  </p>
                </div>
              )}

              {viewingCase.simpleExplanation && (
                <div>
                  <h4 className="font-semibold text-xs uppercase tracking-wider text-muted-foreground mb-1">Plain English Explanation</h4>
                  <p className="whitespace-pre-line leading-relaxed text-foreground/90 bg-primary/5 p-3.5 rounded-lg border border-primary/20">
                    {viewingCase.simpleExplanation}
                  </p>
                </div>
              )}

              {viewingCase.fullText && (
                <div>
                  <h4 className="font-semibold text-xs uppercase tracking-wider text-muted-foreground mb-1">Full Judgment Text</h4>
                  <div className="max-h-60 overflow-y-auto whitespace-pre-line rounded-lg border border-border bg-muted/20 p-3 text-xs leading-relaxed font-mono">
                    {viewingCase.fullText}
                  </div>
                </div>
              )}
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setViewingCase(null)}>
                Close
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* Create / Edit Case Modal */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-lg font-display">
              {editingCase ? "Edit Case Judgment" : "Create New Case Judgment"}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-3.5 py-2">
            <div>
              <label className="text-xs font-semibold uppercase text-muted-foreground">Case Title *</label>
              <Input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. Kesavananda Bharati v. State of Kerala"
                className="mt-1"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Citation</label>
                <Input
                  value={citation}
                  onChange={(e) => setCitation(e.target.value)}
                  placeholder="e.g. (1973) 4 SCC 225"
                  className="mt-1"
                />
              </div>

              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Court</label>
                <select
                  value={court}
                  onChange={(e) => setCourt(e.target.value)}
                  className="mt-1 flex h-9 w-full rounded-md border border-input bg-card px-3 text-sm"
                >
                  <option value="Supreme Court of India">Supreme Court of India</option>
                  <option value="Delhi High Court">Delhi High Court</option>
                  <option value="Bombay High Court">Bombay High Court</option>
                  <option value="Allahabad High Court">Allahabad High Court</option>
                  <option value="Calcutta High Court">Calcutta High Court</option>
                  <option value="Madras High Court">Madras High Court</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Judgment Date</label>
                <Input
                  type="date"
                  value={dateOfJudgment}
                  onChange={(e) => setDateOfJudgment(e.target.value)}
                  className="mt-1"
                />
              </div>

              <div>
                <label className="text-xs font-semibold uppercase text-muted-foreground">Bench / Judges</label>
                <Input
                  value={bench}
                  onChange={(e) => setBench(e.target.value)}
                  placeholder="e.g. S.M. Sikri, C.J., J.M. Shelat, K.S. Hegde"
                  className="mt-1"
                />
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold uppercase text-muted-foreground">Case Summary</label>
              <Textarea
                rows={3}
                value={summary}
                onChange={(e) => setSummary(e.target.value)}
                placeholder="Key ratio decidendi and legal summary..."
                className="mt-1"
              />
            </div>

            <div>
              <label className="text-xs font-semibold uppercase text-muted-foreground">Plain English / Simple Explanation</label>
              <Textarea
                rows={3}
                value={simpleExplanation}
                onChange={(e) => setSimpleExplanation(e.target.value)}
                placeholder="Easy to understand explanation for law students..."
                className="mt-1"
              />
            </div>

            <div>
              <label className="text-xs font-semibold uppercase text-muted-foreground">Full Judgment Text / Kanoon Headnotes</label>
              <Textarea
                rows={5}
                value={fullText}
                onChange={(e) => setFullText(e.target.value)}
                placeholder="Full text of the judgment or headnotes..."
                className="mt-1 font-mono text-xs"
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={saveCase} disabled={saving || !title.trim()}>
              {saving ? "Saving..." : editingCase ? "Update Case" : "Create Case"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation */}
      <AlertDialog open={Boolean(deletingId)} onOpenChange={() => setDeletingId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure you want to delete this case?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently remove the case and its summary from the database.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
              Delete Case
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  );
}
