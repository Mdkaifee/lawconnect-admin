import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { Scale } from "lucide-react";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Field } from "@/components/admin/DataPanel";
import { api, getToken, setToken } from "@/lib/api";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Rishikesh Law Hub" },
      { name: "description", content: "Owner login for the Rishikesh Law Hub admin panel: manage cases, acts, legal updates and posts." },
      { property: "og:title", content: "Admin Login — Rishikesh Law Hub" },
      { property: "og:description", content: "Owner login for the Rishikesh Law Hub admin panel." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: Login,
});

function Login() {
  const navigate = useNavigate();
  const [username, setUsername] = useState("Rishikesh");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (getToken()) navigate({ to: "/admin", replace: true });
  }, [navigate]);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const res = await api<{ token: string }>("/api/auth/admin/login", {
        method: "POST",
        body: { username, password },
        auth: false,
      });
      setToken(res.token);
      navigate({ to: "/admin", replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-primary px-4 py-12">
      <div className="w-full max-w-md rounded-xl bg-card p-8 shadow-panel">
        <div className="mb-8 text-center">
          <span className="mx-auto mb-4 flex size-14 items-center justify-center rounded-full bg-accent text-accent-foreground">
            <Scale className="size-7" />
          </span>
          <h1 className="font-display text-3xl">Law Hub</h1>
          <p className="mt-1 text-sm text-muted-foreground">Admin panel — owner access only</p>
        </div>

        <form onSubmit={submit} className="space-y-4">
          <Field label="Username">
            <Input
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              autoComplete="username"
              placeholder="Username"
            />
          </Field>
          <Field label="Password">
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
              placeholder="••••••••"
            />
          </Field>
          {error ? <p className="text-sm text-destructive">{error}</p> : null}
          <Button type="submit" className="w-full" disabled={busy}>
            {busy ? "Signing in…" : "Sign in"}
          </Button>
        </form>
      </div>
    </div>
  );
}
