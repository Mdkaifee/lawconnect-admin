import { createFileRoute, Link } from "@tanstack/react-router";
import { BookOpen, Gavel, Landmark, Newspaper, Scale, ShieldCheck, Smartphone, Users } from "lucide-react";

export const Route = createFileRoute("/website")({
  head: () => ({
    meta: [
      { title: "Rishikesh Law Hub - Legal Research App" },
      {
        name: "description",
        content:
          "Rishikesh Law Hub is a legal research and community app for law students, advocates, and judicial aspirants.",
      },
      { property: "og:title", content: "Rishikesh Law Hub - Legal Research App" },
      {
        property: "og:description",
        content:
          "Explore bare acts, landmark judgments, legal updates, notes, bookmarks, and community posts in one app.",
      },
      { property: "og:type", content: "website" },
    ],
  }),
  component: WebsitePage,
});

const features = [
  {
    icon: Gavel,
    title: "Landmark Cases",
    text: "Search important judgments with simple explanations, citations, court details, and summaries.",
  },
  {
    icon: BookOpen,
    title: "Bare Acts",
    text: "Browse acts and sections with clean reading views built for quick legal reference.",
  },
  {
    icon: Newspaper,
    title: "Legal Updates",
    text: "Follow curated judgment updates, notifications, amendments, and legal news highlights.",
  },
  {
    icon: Users,
    title: "Law Community",
    text: "Share posts, questions, comments, and discussions with other law learners and professionals.",
  },
] as const;

function WebsitePage() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 antialiased selection:bg-amber-100 selection:text-amber-900">
      <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/95 backdrop-blur-md">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4 sm:px-6">
          <Link to="/website" className="flex items-center gap-3">
            <span className="flex size-10 items-center justify-center rounded-xl bg-slate-900 text-amber-400 shadow-sm">
              <Scale className="size-5" />
            </span>
            <div>
              <span className="block font-display text-lg font-bold leading-tight tracking-tight">
                Rishikesh Law Hub
              </span>
              <span className="text-xs font-medium text-slate-500">Legal Research App</span>
            </div>
          </Link>
          <nav className="hidden items-center gap-5 text-xs font-semibold text-slate-600 sm:flex">
            <a href="#features" className="hover:text-slate-950">Features</a>
            <a href="#about" className="hover:text-slate-950">About</a>
            <Link to="/privacy-policy" className="hover:text-slate-950">Privacy</Link>
          </nav>
        </div>
      </header>

      <main>
        <section className="border-b border-slate-200 bg-white">
          <div className="mx-auto grid max-w-6xl gap-10 px-4 py-12 sm:px-6 lg:grid-cols-[1.05fr_0.95fr] lg:items-center lg:py-16">
            <div>
              <div className="mb-4 inline-flex items-center gap-2 rounded-full bg-amber-50 px-3 py-1 text-xs font-bold text-amber-800 ring-1 ring-amber-200">
                <Landmark className="size-3.5" />
                Indian law learning and research
              </div>
              <h1 className="max-w-3xl text-4xl font-extrabold tracking-tight text-slate-950 sm:text-5xl">
                Study cases, acts, and legal updates in one clean app.
              </h1>
              <p className="mt-4 max-w-2xl text-base leading-7 text-slate-600">
                Rishikesh Law Hub helps law students, advocates, and judicial aspirants read bare acts, explore landmark
                judgments, save notes, bookmark references, and join useful legal discussions.
              </p>
              <div className="mt-7 flex flex-wrap gap-3">
                <a
                  href="#features"
                  className="inline-flex items-center gap-2 rounded-lg bg-slate-900 px-5 py-3 text-sm font-bold text-white shadow-sm hover:bg-slate-800"
                >
                  <Smartphone className="size-4" />
                  View Features
                </a>
                <Link
                  to="/delete-account"
                  className="inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-5 py-3 text-sm font-bold text-slate-800 hover:bg-slate-50"
                >
                  Account Deletion
                </Link>
              </div>
            </div>

            <div className="overflow-hidden rounded-2xl border border-slate-200 bg-slate-950 shadow-xl">
              <div className="aspect-[4/3] bg-[url('/lawicon.png')] bg-cover bg-center" />
              <div className="grid grid-cols-3 gap-px bg-slate-800 text-center text-xs font-semibold text-white">
                <div className="bg-slate-900 px-3 py-4">
                  <p className="text-lg font-extrabold text-amber-300">Cases</p>
                  <p className="mt-1 text-slate-300">Judgments</p>
                </div>
                <div className="bg-slate-900 px-3 py-4">
                  <p className="text-lg font-extrabold text-amber-300">Acts</p>
                  <p className="mt-1 text-slate-300">Sections</p>
                </div>
                <div className="bg-slate-900 px-3 py-4">
                  <p className="text-lg font-extrabold text-amber-300">Notes</p>
                  <p className="mt-1 text-slate-300">Saved</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section id="features" className="mx-auto max-w-6xl px-4 py-12 sm:px-6 lg:py-16">
          <div className="mb-8 max-w-2xl">
            <h2 className="text-2xl font-extrabold tracking-tight text-slate-950">What You Can Do</h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Built as a focused study companion rather than a noisy feed.
            </p>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {features.map(({ icon: Icon, title, text }) => (
              <article key={title} className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <span className="mb-4 flex size-10 items-center justify-center rounded-lg bg-slate-900 text-amber-300">
                  <Icon className="size-5" />
                </span>
                <h3 className="font-bold text-slate-950">{title}</h3>
                <p className="mt-2 text-xs leading-5 text-slate-600">{text}</p>
              </article>
            ))}
          </div>
        </section>

        <section id="about" className="border-y border-slate-200 bg-white">
          <div className="mx-auto grid max-w-6xl gap-8 px-4 py-12 sm:px-6 lg:grid-cols-2 lg:py-14">
            <div>
              <h2 className="text-2xl font-extrabold tracking-tight text-slate-950">Made for Indian legal study</h2>
              <p className="mt-3 text-sm leading-7 text-slate-600">
                The app is designed around practical law workflows: reading, saving, revising, discussing, and tracking
                updates. It keeps legal material organized so users can return to important references quickly.
              </p>
            </div>
            <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6">
              <div className="mb-3 flex items-center gap-2 font-bold text-emerald-950">
                <ShieldCheck className="size-5 text-emerald-700" />
                Privacy and account control
              </div>
              <p className="text-xs leading-6 text-emerald-900">
                Users can manage saved data and request account deletion from inside the signed-in mobile app. The app
                uses a 7-day restore window before permanent deletion.
              </p>
            </div>
          </div>
        </section>
      </main>

      <footer className="bg-slate-950 py-8 text-xs text-slate-300">
        <div className="mx-auto flex max-w-6xl flex-col gap-4 px-4 sm:flex-row sm:items-center sm:justify-between sm:px-6">
          <p>© {new Date().getFullYear()} Rishikesh Law Hub. All rights reserved.</p>
          <div className="flex flex-wrap gap-4">
            <Link to="/privacy-policy" className="hover:text-white">Privacy Policy</Link>
            <Link to="/terms-of-service" className="hover:text-white">Terms of Service</Link>
            <Link to="/delete-account" className="hover:text-white">Delete Account</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
