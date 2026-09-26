import { createFileRoute } from "@tanstack/react-router";
import { AdminShell } from "@/components/admin/AdminShell";
import { Panel, StateBlock } from "@/components/admin/DataPanel";
import { useAdminGuard } from "@/lib/useAdmin";
import { api } from "@/lib/api";
import type { Stats } from "@/lib/types";
import { useEffect, useState } from "react";

export const Route = createFileRoute("/admin/")({
  head: () => ({
    meta: [
      { title: "Dashboard — Rishikesh Law Hub Admin" },
      { name: "description", content: "Overview of cases, acts, posts, legal updates and app users." },
      { property: "og:title", content: "Dashboard — Rishikesh Law Hub Admin" },
      { property: "og:description", content: "Overview of content and users in Rishikesh Law Hub." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: Dashboard,
});

const LABELS: Record<string, string> = {
  cases: "Cases",
  acts: "Acts",
  posts: "Posts",
  updates: "Legal updates",
  users: "App users",
  notes: "Notes",
  bookmarks: "Bookmarks",
};

function Dashboard() {
  const ready = useAdminGuard();
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!ready) return;
    api<Stats>("/api/stats")
      .then(setStats)
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }, [ready]);

  return (
    <AdminShell title="Dashboard" subtitle="Everything published in the app at a glance">
      <StateBlock loading={loading} error={error} />
      {stats ? (
        <div className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {Object.entries(stats.counts).map(([key, value]) => (
              <Panel key={key} className="p-5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">{LABELS[key] ?? key}</p>
                <p className="mt-2 font-display text-3xl">{value}</p>
              </Panel>
            ))}
          </div>

          <div className="grid gap-4 lg:grid-cols-2">
            <Panel className="p-5">
              <h2 className="mb-3 font-display text-lg">Recent cases</h2>
              <ul className="space-y-3 text-sm">
                {stats.recentCases.map((c) => (
                  <li key={c._id}>
                    <p className="font-medium">{c.title}</p>
                    <p className="text-muted-foreground">{[c.citation, c.court].filter(Boolean).join(" · ")}</p>
                  </li>
                ))}
                {stats.recentCases.length === 0 ? <li className="text-muted-foreground">No cases yet.</li> : null}
              </ul>
            </Panel>
            <Panel className="p-5">
              <h2 className="mb-3 font-display text-lg">Recent posts</h2>
              <ul className="space-y-3 text-sm">
                {stats.recentPosts.map((p) => (
                  <li key={p._id}>
                    <p className="font-medium">{p.title}</p>
                    <p className="text-muted-foreground">{p.authorName} · {p.status}</p>
                  </li>
                ))}
                {stats.recentPosts.length === 0 ? <li className="text-muted-foreground">No posts yet.</li> : null}
              </ul>
            </Panel>
          </div>
        </div>
      ) : null}
    </AdminShell>
  );
}
