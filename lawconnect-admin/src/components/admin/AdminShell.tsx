import { Link, useNavigate, useRouterState } from "@tanstack/react-router";
import {
  BookOpen,
  FileText,
  Gavel,
  LayoutDashboard,
  LogOut,
  Newspaper,
  ScrollText,
  Scale,
  Settings,
  ShieldCheck,
  Trash2,
  Users,
} from "lucide-react";
import type { ReactNode } from "react";
import { setToken } from "@/lib/api";

const NAV = [
  { to: "/admin", label: "Dashboard", icon: LayoutDashboard, exact: true },
  { to: "/admin/cases", label: "Cases & Judgments", icon: Gavel },
  { to: "/admin/acts", label: "Acts & Sections", icon: BookOpen },
  { to: "/admin/updates", label: "Legal Updates", icon: Newspaper },
  { to: "/admin/posts", label: "Law Posts", icon: FileText },
  { to: "/admin/users", label: "App Users", icon: Users },
  { to: "/admin/settings", label: "Settings", icon: Settings },
  { to: "/privacy-policy", label: "Privacy Policy", icon: ShieldCheck },
  { to: "/terms-of-service", label: "Terms of Service", icon: ScrollText },
  { to: "/delete-account", label: "Delete Account", icon: Trash2 },
] as const;

export function AdminShell({ title, subtitle, actions, children }: {
  title: string;
  subtitle?: string;
  actions?: ReactNode;
  children: ReactNode;
}) {
  const navigate = useNavigate();
  const pathname = useRouterState({ select: (s) => s.location.pathname });

  function signOut() {
    setToken(null);
    navigate({ to: "/", replace: true });
  }

  return (
    <div className="flex min-h-screen bg-background">
      <aside className="hidden w-64 shrink-0 flex-col bg-sidebar text-sidebar-foreground md:flex">
        <div className="flex items-center gap-3 border-b border-sidebar-border px-5 py-5">
          <span className="flex size-10 items-center justify-center rounded-md bg-sidebar-accent text-sidebar-primary">
            <Scale className="size-5" />
          </span>
          <div className="leading-tight">
            <p className="font-display text-base">Rishikesh Law Hub</p>
            <p className="text-xs opacity-70">Admin Panel</p>
          </div>
        </div>
        <nav className="flex-1 space-y-1 p-3">
          {NAV.map(({ to, label, icon: Icon, ...rest }) => {
            const active = "exact" in rest && rest.exact ? pathname === to : pathname.startsWith(to);
            return (
              <Link
                key={to}
                to={to}
                className={`flex items-center gap-3 rounded-md px-3 py-2 text-sm transition-colors ${
                  active
                    ? "bg-sidebar-accent text-sidebar-primary"
                    : "text-sidebar-foreground/80 hover:bg-sidebar-accent/60 hover:text-sidebar-accent-foreground"
                }`}
              >
                <Icon className="size-4" />
                {label}
              </Link>
            );
          })}
        </nav>
        <button
          onClick={signOut}
          className="m-3 flex items-center gap-3 rounded-md px-3 py-2 text-sm text-sidebar-foreground/80 transition-colors hover:bg-sidebar-accent/60"
        >
          <LogOut className="size-4" />
          Log out
        </button>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex flex-wrap items-center justify-between gap-3 border-b border-border bg-card px-6 py-4">
          <div>
            <h1 className="font-display text-2xl">{title}</h1>
            {subtitle ? <p className="text-sm text-muted-foreground">{subtitle}</p> : null}
          </div>
          <div className="flex items-center gap-2">{actions}</div>
        </header>
        <div className="flex gap-2 overflow-x-auto border-b border-border bg-card px-4 py-2 md:hidden">
          {NAV.map(({ to, label }) => (
            <Link key={to} to={to} className="whitespace-nowrap rounded-md px-3 py-1.5 text-xs text-muted-foreground hover:bg-muted">
              {label}
            </Link>
          ))}
        </div>
        <main className="flex-1 p-6">{children}</main>
      </div>
    </div>
  );
}
