import type { ReactNode } from "react";
import { Loader2 } from "lucide-react";

export function Panel({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <div className={`panel overflow-hidden ${className}`}>{children}</div>;
}

export function StateBlock({
  loading,
  error,
  empty,
  emptyText = "Nothing here yet.",
}: {
  loading?: boolean;
  error?: string | null;
  empty?: boolean;
  emptyText?: string;
}) {
  if (loading) {
    return (
      <div className="flex items-center justify-center gap-2 p-10 text-sm text-muted-foreground">
        <Loader2 className="size-4 animate-spin" /> Loading…
      </div>
    );
  }
  if (error) {
    return <div className="p-10 text-center text-sm text-destructive">{error}</div>;
  }
  if (empty) {
    return <div className="p-10 text-center text-sm text-muted-foreground">{emptyText}</div>;
  }
  return null;
}

export function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="block space-y-1.5">
      <span className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{label}</span>
      {children}
    </label>
  );
}
