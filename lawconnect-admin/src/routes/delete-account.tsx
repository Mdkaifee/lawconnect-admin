import { createFileRoute, Link } from "@tanstack/react-router";
import { CheckCircle2, Clock, Database, Info, Mail, Scale, ShieldCheck, Smartphone, Trash2 } from "lucide-react";

export const Route = createFileRoute("/delete-account")({
  head: () => ({
    meta: [
      { title: "Delete Account & User Data - Rishikesh Law Hub" },
      {
        name: "description",
        content:
          "Official account deletion instructions for Rishikesh Law Hub. Account deletion can only be requested from inside the mobile app.",
      },
      { property: "og:title", content: "Delete Account & User Data - Rishikesh Law Hub" },
      {
        property: "og:description",
        content:
          "Learn how to delete your Rishikesh Law Hub account and personal data from inside the mobile application.",
      },
      { property: "og:type", content: "website" },
    ],
  }),
  component: DeleteAccountPage,
});

function DeleteAccountPage() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 antialiased selection:bg-rose-100 selection:text-rose-900">
      <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/95 backdrop-blur-md">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4 sm:px-6">
          <div className="flex items-center gap-3">
            <span className="flex size-10 items-center justify-center rounded-xl bg-slate-900 text-amber-400 shadow-sm">
              <Scale className="size-5" />
            </span>
            <div>
              <span className="block font-display text-lg font-bold leading-tight tracking-tight text-slate-900">
                Rishikesh Law Hub
              </span>
              <span className="text-xs font-medium text-slate-500">Account & Data Management</span>
            </div>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:py-14">
        <div className="mb-10 border-b border-slate-200 pb-8 text-center sm:text-left">
          <div className="mb-3 inline-flex items-center gap-2 rounded-full bg-rose-50 px-3 py-1 text-xs font-semibold text-rose-700 ring-1 ring-inset ring-rose-600/20">
            <ShieldCheck className="size-3.5" />
            Google Play Console User Data Safety Compliant
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 sm:text-4xl">
            Delete Account & Personal Data
          </h1>
          <p className="mt-2 text-sm text-slate-600">
            Account deletion requests are accepted only from inside the Rishikesh Law Hub mobile app.
          </p>
          <p className="mt-3 max-w-3xl text-base leading-relaxed text-slate-600">
            This page explains the official process. For your security, the web page does not accept deletion requests,
            email submissions, or password verification. Sign in to the app and use the in-app Delete Account option.
          </p>
        </div>

        <div className="grid gap-8 lg:grid-cols-12">
          <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8 lg:col-span-7">
            <div className="mb-6 flex items-center gap-3 border-b border-slate-100 pb-4">
              <span className="flex size-9 items-center justify-center rounded-lg bg-rose-50 text-rose-600">
                <Smartphone className="size-5" />
              </span>
              <div>
                <h2 className="text-lg font-bold text-slate-900">How to Delete Your Account</h2>
                <p className="text-xs text-slate-500">Complete this from the mobile app while signed in.</p>
              </div>
            </div>

            <ol className="space-y-4 text-sm text-slate-700">
              {[
                "Open the Rishikesh Law Hub mobile app.",
                "Go to Profile from the bottom navigation.",
                "Open Settings.",
                "Scroll to Account Management.",
                "Tap Delete Account and confirm the request.",
              ].map((step, index) => (
                <li key={step} className="flex gap-3">
                  <span className="flex size-7 shrink-0 items-center justify-center rounded-full bg-slate-900 text-xs font-bold text-white">
                    {index + 1}
                  </span>
                  <span className="pt-1">{step}</span>
                </li>
              ))}
            </ol>

            <div className="mt-6 rounded-xl border border-amber-200 bg-amber-50/80 p-4 text-xs text-amber-900">
              <div className="mb-1.5 flex items-center gap-2 font-bold text-amber-950">
                <Clock className="size-4 text-amber-700" />
                <span>7-Day Grace Period & Auto-Restore Policy</span>
              </div>
              <p className="leading-relaxed text-amber-800">
                After confirmation, your account is scheduled for deletion. If you do not log in within 7 days, your
                account and associated data are permanently deleted. If you log back in before the 7 days expire, the
                deletion request is automatically cancelled.
              </p>
            </div>
          </section>

          <aside className="space-y-6 lg:col-span-5">
            <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="mb-3 flex items-center gap-2.5 font-bold text-slate-900">
                <Database className="size-4 text-indigo-600" />
                <h3 className="text-sm uppercase tracking-wider">What Data Is Deleted?</h3>
              </div>
              <ul className="space-y-2 text-xs text-slate-700">
                <li className="flex items-start gap-2">
                  <CheckCircle2 className="mt-0.5 size-4 shrink-0 text-rose-600" />
                  <span>Profile identity including name, email, password hash, headline, college, and photo URL.</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle2 className="mt-0.5 size-4 shrink-0 text-rose-600" />
                  <span>Community posts, comments, likes, and follow relationships tied to your account.</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle2 className="mt-0.5 size-4 shrink-0 text-rose-600" />
                  <span>Private notes, bookmarks, reading history, and reports submitted by you.</span>
                </li>
              </ul>
            </div>

            <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="mb-3 flex items-center gap-2.5 font-bold text-slate-900">
                <Info className="size-4 text-blue-600" />
                <h3 className="text-sm uppercase tracking-wider">Why App Only?</h3>
              </div>
              <p className="text-xs leading-relaxed text-slate-600">
                In-app deletion confirms that the signed-in account owner is making the request with an active
                authenticated session. This protects accounts from accidental or unauthorized web requests.
              </p>
            </div>

            <div className="rounded-2xl border border-slate-200 bg-slate-900 p-6 text-white shadow-sm">
              <div className="mb-2 flex items-center gap-2.5 font-bold text-white">
                <Mail className="size-4 text-amber-400" />
                <h3 className="text-sm uppercase tracking-wider">Need Help?</h3>
              </div>
              <p className="text-xs leading-relaxed text-slate-300">
                If you cannot access your account, contact support from your registered email address.
              </p>
              <a
                href="mailto:rishikesh4287@gmail.com"
                className="mt-3 block text-xs font-semibold text-amber-400 underline hover:text-amber-300"
              >
                rishikesh4287@gmail.com
              </a>
            </div>
          </aside>
        </div>
      </main>

      <footer className="border-t border-slate-200 bg-white py-8 text-center text-xs text-slate-500">
        <div className="mx-auto flex max-w-5xl flex-col items-center justify-between gap-4 px-4 sm:flex-row sm:px-6">
          <p>© {new Date().getFullYear()} Rishikesh Law Hub. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <Link to="/privacy-policy" className="font-medium hover:text-slate-900">
              Privacy Policy
            </Link>
            <Link to="/terms-of-service" className="font-medium hover:text-slate-900">
              Terms of Service
            </Link>
            <Link to="/delete-account" className="font-semibold text-slate-800 hover:text-slate-900">
              Delete Account
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
