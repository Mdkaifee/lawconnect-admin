import { createFileRoute, Link } from "@tanstack/react-router";
import { AlertTriangle, BookOpen, CheckCircle2, FileText, Gavel, Mail, Scale, ShieldCheck, UserCheck } from "lucide-react";

export const Route = createFileRoute("/terms-of-service")({
  head: () => ({
    meta: [
      { title: "Terms of Service - Rishikesh Law Hub" },
      { name: "description", content: "Official Terms of Service for Rishikesh Law Hub mobile application and web platform." },
      { property: "og:title", content: "Terms of Service - Rishikesh Law Hub" },
      { property: "og:description", content: "Official Terms of Service for Rishikesh Law Hub mobile application and web platform." },
      { property: "og:type", content: "website" },
    ],
  }),
  component: TermsOfServicePage,
});

function TermsOfServicePage() {
  const lastUpdated = "September 28, 2026";

  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 antialiased selection:bg-amber-100 selection:text-amber-900">
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
              <span className="text-xs font-medium text-slate-500">Legal Platform & Research Hub</span>
            </div>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:py-14">
        <div className="mb-10 border-b border-slate-200 pb-8 text-center sm:text-left">
          <div className="mb-3 inline-flex items-center gap-2 rounded-full bg-indigo-50 px-3 py-1 text-xs font-semibold text-indigo-700 ring-1 ring-inset ring-indigo-600/20">
            <ShieldCheck className="size-3.5" />
            Official App Terms
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 sm:text-4xl">
            Terms of Service
          </h1>
          <p className="mt-2 text-sm text-slate-600">
            Effective Date & Last Updated: <span className="font-semibold text-slate-900">{lastUpdated}</span>
          </p>
          <p className="mt-3 max-w-3xl text-base leading-relaxed text-slate-600">
            These Terms of Service govern your access to and use of <strong>Rishikesh Law Hub</strong>, including the
            mobile application, admin website, legal research materials, community features, and related services.
          </p>
        </div>

        <div className="space-y-10 text-sm leading-relaxed text-slate-600">
          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm sm:p-8">
            <div className="mb-5 flex items-center gap-3 border-b border-slate-100 pb-4">
              <span className="flex size-9 items-center justify-center rounded-lg bg-blue-50 text-blue-700">
                <UserCheck className="size-5" />
              </span>
              <h2 className="text-lg font-bold text-slate-900">1. Acceptance of Terms</h2>
            </div>
            <p>
              By creating an account, signing in, browsing content, or using any feature of Rishikesh Law Hub, you agree
              to follow these Terms and our Privacy Policy. If you do not agree, please stop using the service.
            </p>
          </section>

          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm sm:p-8">
            <div className="mb-5 flex items-center gap-3 border-b border-slate-100 pb-4">
              <span className="flex size-9 items-center justify-center rounded-lg bg-emerald-50 text-emerald-700">
                <BookOpen className="size-5" />
              </span>
              <h2 className="text-lg font-bold text-slate-900">2. Educational Legal Information</h2>
            </div>
            <div className="rounded-xl border border-amber-200 bg-amber-50/80 p-4 text-xs text-amber-900">
              <div className="mb-1.5 flex items-center gap-2 font-bold text-amber-950">
                <AlertTriangle className="size-4 text-amber-700" />
                <span>Not Legal Advice</span>
              </div>
              <p>
                Content in the app is provided for educational and research purposes only. Rishikesh Law Hub does not
                create an advocate-client relationship, does not provide personalized legal advice, and should not be
                used as a substitute for consulting a qualified lawyer.
              </p>
            </div>
          </section>

          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm sm:p-8">
            <div className="mb-5 flex items-center gap-3 border-b border-slate-100 pb-4">
              <span className="flex size-9 items-center justify-center rounded-lg bg-indigo-50 text-indigo-700">
                <FileText className="size-5" />
              </span>
              <h2 className="text-lg font-bold text-slate-900">3. User Accounts & Responsibilities</h2>
            </div>
            <ul className="space-y-2.5 pl-5 text-slate-600 list-disc">
              <li>You are responsible for keeping your login credentials confidential.</li>
              <li>You agree to provide accurate account information and keep it updated where possible.</li>
              <li>You must not impersonate another person, misuse another account, or attempt unauthorized access.</li>
              <li>You are responsible for activity performed through your account.</li>
            </ul>
          </section>

          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm sm:p-8">
            <div className="mb-5 flex items-center gap-3 border-b border-slate-100 pb-4">
              <span className="flex size-9 items-center justify-center rounded-lg bg-rose-50 text-rose-700">
                <Gavel className="size-5" />
              </span>
              <h2 className="text-lg font-bold text-slate-900">4. Community Content Rules</h2>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              {[
                "Do not post unlawful, abusive, defamatory, threatening, hateful, or misleading content.",
                "Do not upload private, confidential, or court-restricted information without permission.",
                "Do not spam, manipulate likes, harass users, or disrupt app services.",
                "We may remove content, restrict access, or block accounts that violate these Terms.",
              ].map((rule) => (
                <div key={rule} className="rounded-xl border border-slate-100 bg-slate-50/70 p-4">
                  <p className="flex gap-2 text-xs leading-normal text-slate-700">
                    <CheckCircle2 className="mt-0.5 size-4 shrink-0 text-emerald-600" />
                    <span>{rule}</span>
                  </p>
                </div>
              ))}
            </div>
          </section>

          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm sm:p-8">
            <h2 className="mb-2 text-base font-bold text-slate-900">5. Intellectual Property</h2>
            <p className="text-xs text-slate-600">
              The Rishikesh Law Hub name, interface, curated summaries, explanations, and platform design belong to the
              platform owner or licensors. Public legal texts, judgments, and government materials may be sourced from
              public official references and remain subject to their original public/legal status.
            </p>
          </section>

          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm sm:p-8">
            <h2 className="mb-2 text-base font-bold text-slate-900">6. Account Deletion & Termination</h2>
            <p className="text-xs text-slate-600">
              You may request account deletion only from inside the signed-in mobile app under Profile &gt; Settings &gt;
              Delete Account. After confirmation, a 7-day grace period applies. Logging in during that period cancels
              deletion; otherwise your account and associated personal data are permanently removed.
            </p>
          </section>

          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-sm sm:p-8">
            <h2 className="mb-2 text-base font-bold text-slate-900">7. Changes to These Terms</h2>
            <p className="text-xs text-slate-600">
              We may update these Terms to reflect service, legal, or policy changes. The latest version will be posted
              on this page with an updated effective date.
            </p>
          </section>

          <section className="rounded-2xl border border-slate-200/80 bg-slate-900 p-6 text-white shadow-md sm:p-8">
            <div className="mb-4 flex items-center gap-3 border-b border-slate-800 pb-4">
              <span className="flex size-9 items-center justify-center rounded-lg bg-amber-400 text-slate-900">
                <Mail className="size-5" />
              </span>
              <div>
                <h2 className="text-lg font-bold text-white">8. Contact</h2>
                <p className="text-xs text-slate-400">Questions about these Terms?</p>
              </div>
            </div>
            <p className="text-xs text-slate-300">Platform Owner & Publisher: Rishikesh Yadav</p>
            <a
              href="mailto:rishikesh4287@gmail.com"
              className="mt-2 block text-sm font-semibold text-amber-400 underline hover:text-amber-300"
            >
              rishikesh4287@gmail.com
            </a>
          </section>
        </div>
      </main>

      <footer className="border-t border-slate-200 bg-white py-8 text-center text-xs text-slate-500">
        <div className="mx-auto flex max-w-5xl flex-col items-center justify-between gap-4 px-4 sm:flex-row sm:px-6">
          <p>© {new Date().getFullYear()} Rishikesh Law Hub. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <Link to="/privacy-policy" className="font-medium hover:text-slate-900">
              Privacy Policy
            </Link>
            <Link to="/terms-of-service" className="font-semibold text-slate-800 hover:text-slate-900">
              Terms of Service
            </Link>
            <Link to="/delete-account" className="font-medium hover:text-slate-900">
              Delete Account
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
