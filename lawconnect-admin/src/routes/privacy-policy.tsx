import { createFileRoute, Link } from "@tanstack/react-router";
import { Scale, ShieldCheck, Lock, Eye, Database, Trash2, Mail, ExternalLink, CheckCircle2 } from "lucide-react";

export const Route = createFileRoute("/privacy-policy")({
  head: () => ({
    meta: [
      { title: "Privacy Policy — Rishikesh Law Hub" },
      { name: "description", content: "Official Privacy Policy for Rishikesh Law Hub mobile application and web platform." },
      { property: "og:title", content: "Privacy Policy — Rishikesh Law Hub" },
      { property: "og:description", content: "Official Privacy Policy for Rishikesh Law Hub mobile application and web platform." },
      { property: "og:type", content: "website" },
    ],
  }),
  component: PrivacyPolicyPage,
});

function PrivacyPolicyPage() {
  const lastUpdated = "September 28, 2026";

  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 antialiased selection:bg-amber-100 selection:text-amber-900">
      {/* Header Banner */}
      <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/95 backdrop-blur-md">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4 sm:px-6">
          <div className="flex items-center gap-3">
            <span className="flex size-10 items-center justify-center rounded-xl bg-slate-900 text-amber-400 shadow-sm">
              <Scale className="size-5" />
            </span>
            <div>
              <span className="font-display text-lg font-bold tracking-tight text-slate-900 block leading-tight">
                Rishikesh Law Hub
              </span>
              <span className="text-xs font-medium text-slate-500">Legal Platform & Research Hub</span>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:py-14">
        {/* Title Hero */}
        <div className="mb-10 text-center sm:text-left border-b border-slate-200 pb-8">
          <div className="inline-flex items-center gap-2 rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-inset ring-emerald-600/20 mb-3">
            <ShieldCheck className="size-3.5" />
            Google Play Console & App Store Compliant
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 sm:text-4xl">
            Privacy Policy
          </h1>
          <p className="mt-2 text-sm text-slate-600">
            Effective Date & Last Updated: <span className="font-semibold text-slate-900">{lastUpdated}</span>
          </p>
          <p className="mt-3 text-base text-slate-600 max-w-3xl leading-relaxed">
            Welcome to <strong>Rishikesh Law Hub</strong> (&quot;Law Hub&quot;, &quot;we&quot;, &quot;us&quot;, or &quot;our&quot;). 
            We are committed to protecting your personal data and privacy when you use our mobile application, website, 
            and associated legal research services. This Privacy Policy explains what data we collect, why we collect it, 
            how we safeguard it, and your legal rights under applicable laws.
          </p>
        </div>

        <div className="space-y-10 text-sm leading-relaxed text-slate-600">
          {/* Section 1: Information We Collect */}
          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 sm:p-8 shadow-sm">
            <div className="flex items-center gap-3 border-b border-slate-100 pb-4 mb-5">
              <span className="flex size-9 items-center justify-center rounded-lg bg-blue-50 text-blue-700">
                <Database className="size-5" />
              </span>
              <h2 className="text-lg font-bold text-slate-900">1. Information We Collect</h2>
            </div>
            
            <p className="mb-4">
              We only collect information necessary to provide you with seamless legal case studies, bare acts research, 
              community post interactions, and personalized notes.
            </p>

            <div className="grid gap-4 sm:grid-cols-2">
              <div className="rounded-xl border border-slate-100 bg-slate-50/70 p-4">
                <h3 className="font-semibold text-slate-900 mb-1 flex items-center gap-1.5">
                  <CheckCircle2 className="size-4 text-emerald-600" /> Account Information
                </h3>
                <p className="text-xs text-slate-600 leading-normal">
                  When you register or log in, we collect your <strong>Name</strong>, <strong>Email Address</strong>, 
                  <strong>Phone Number</strong>, professional title (e.g. Advocate, Law Student), and optional College/Bar Council affiliation.
                </p>
              </div>

              <div className="rounded-xl border border-slate-100 bg-slate-50/70 p-4">
                <h3 className="font-semibold text-slate-900 mb-1 flex items-center gap-1.5">
                  <CheckCircle2 className="size-4 text-emerald-600" /> User-Generated Content
                </h3>
                <p className="text-xs text-slate-600 leading-normal">
                  Articles, community legal posts, comments, likes, follower associations, private case study notes, 
                  and saved judgment bookmarks that you create inside the app.
                </p>
              </div>

              <div className="rounded-xl border border-slate-100 bg-slate-50/70 p-4">
                <h3 className="font-semibold text-slate-900 mb-1 flex items-center gap-1.5">
                  <CheckCircle2 className="size-4 text-emerald-600" /> Device & Diagnostic Data
                </h3>
                <p className="text-xs text-slate-600 leading-normal">
                  Non-sensitive technical identifiers including device model, operating system version (Android/iOS), 
                  IP address, and crash logs to maintain app stability.
                </p>
              </div>

              <div className="rounded-xl border border-slate-100 bg-slate-50/70 p-4">
                <h3 className="font-semibold text-slate-900 mb-1 flex items-center gap-1.5">
                  <CheckCircle2 className="size-4 text-emerald-600" /> Reading History
                </h3>
                <p className="text-xs text-slate-600 leading-normal">
                  Your recently viewed bare acts, section references, and landmark judgments to provide quick resume 
                  and offline caching capabilities.
                </p>
              </div>
            </div>
          </section>

          {/* Section 2: How We Use Your Information */}
          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 sm:p-8 shadow-sm">
            <div className="flex items-center gap-3 border-b border-slate-100 pb-4 mb-5">
              <span className="flex size-9 items-center justify-center rounded-lg bg-indigo-50 text-indigo-700">
                <Eye className="size-5" />
              </span>
              <h2 className="text-lg font-bold text-slate-900">2. How We Use Your Information</h2>
            </div>
            
            <ul className="space-y-2.5 list-disc pl-5 text-slate-600">
              <li>
                <strong className="text-slate-800">Account Authentication:</strong> To create and manage your secure account, verify identities, and prevent duplicate or unauthorized accounts.
              </li>
              <li>
                <strong className="text-slate-800">Legal Community Feed:</strong> To publish and showcase community questions, case analysis, and legal updates shared by verified advocates and students.
              </li>
              <li>
                <strong className="text-slate-800">Personalized Synchronization:</strong> To securely back up and sync your private case notes, bookmarks, and reading history across your devices.
              </li>
              <li>
                <strong className="text-slate-800">App Performance & Safety:</strong> To diagnose app crashes, defend against malicious activities, and deliver real-time push updates for important court judgments.
              </li>
              <li>
                <strong className="text-slate-800">Zero Selling of Personal Data:</strong> We <u>never</u> sell, rent, or trade your personal information or research history to any third-party advertisers or data brokers.
              </li>
            </ul>
          </section>

          {/* Section 3: Data Protection & Security */}
          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 sm:p-8 shadow-sm">
            <div className="flex items-center gap-3 border-b border-slate-100 pb-4 mb-5">
              <span className="flex size-9 items-center justify-center rounded-lg bg-amber-50 text-amber-700">
                <Lock className="size-5" />
              </span>
              <h2 className="text-lg font-bold text-slate-900">3. Data Security & Storage</h2>
            </div>
            
            <p className="mb-3">
              We implement industry-standard administrative, technical, and physical security measures to safeguard your information:
            </p>
            <div className="grid gap-3 sm:grid-cols-3">
              <div className="rounded-lg bg-slate-50 p-3.5 border border-slate-100">
                <h4 className="font-semibold text-slate-900 text-xs uppercase tracking-wider mb-1">HTTPS / TLS 1.3</h4>
                <p className="text-xs text-slate-600">All data in transit between the app and our servers is fully encrypted using TLS/SSL protocols.</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3.5 border border-slate-100">
                <h4 className="font-semibold text-slate-900 text-xs uppercase tracking-wider mb-1">Encrypted Passwords</h4>
                <p className="text-xs text-slate-600">User passwords are cryptographically hashed with strong one-way salt algorithms (bcrypt).</p>
              </div>
              <div className="rounded-lg bg-slate-50 p-3.5 border border-slate-100">
                <h4 className="font-semibold text-slate-900 text-xs uppercase tracking-wider mb-1">Isolated Cloud DB</h4>
                <p className="text-xs text-slate-600">Stored on secure cloud infrastructure with strict access control and 24/7 automated monitoring.</p>
              </div>
            </div>
          </section>

          {/* Section 4: User Rights & Account Deletion */}
          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 sm:p-8 shadow-sm">
            <div className="flex items-center gap-3 border-b border-slate-100 pb-4 mb-5">
              <span className="flex size-9 items-center justify-center rounded-lg bg-rose-50 text-rose-700">
                <Trash2 className="size-5" />
              </span>
              <h2 className="text-lg font-bold text-slate-900">4. Data Retention & Account Deletion Policy</h2>
            </div>
            
            <p className="mb-3">
              In strict accordance with <strong>Google Play User Data & Account Deletion Policies</strong>:
            </p>
            <div className="rounded-xl border border-rose-100 bg-rose-50/50 p-4 mb-4">
              <h3 className="font-semibold text-slate-900 mb-1 text-sm">How to Request Full Account & Data Deletion</h3>
              <p className="text-xs text-slate-700 leading-normal mb-2">
                You have the full right to delete your account, posts, personal notes, bookmarks, and all associated personal data at any time.
              </p>
              <ul className="text-xs text-slate-700 list-disc pl-4 space-y-1">
                <li><strong>Within the App:</strong> Go to <em>Profile &gt; Settings &gt; Delete Account</em> while signed in.</li>
                <li><strong>Web Requests Disabled:</strong> For account safety, deletion requests are not accepted from the website or by public email form.</li>
              </ul>
              <p className="text-xs text-slate-600 mt-2">
                After confirmation, your account enters a 7-day grace period. If you do not log back in within 7 days, all personal identifiers, posts, and saved records will be permanently purged from our active databases.
              </p>
            </div>
          </section>

          {/* Section 5: Third Party Services & Legal Disclaimer */}
          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 sm:p-8 shadow-sm">
            <div className="flex items-center gap-3 border-b border-slate-100 pb-4 mb-5">
              <span className="flex size-9 items-center justify-center rounded-lg bg-teal-50 text-teal-700">
                <ExternalLink className="size-5" />
              </span>
              <h2 className="text-lg font-bold text-slate-900">5. Third-Party Links & Educational Disclaimer</h2>
            </div>
            
            <p className="mb-3">
              Our app provides informational access to Indian Bare Acts, Constitutional Articles, and Judgment citations for educational and research purposes.
            </p>
            <ul className="space-y-2 list-disc pl-5 text-slate-600 text-xs">
              <li>
                <strong>Official Government Sources:</strong> Legal texts and Bare Acts are compiled from public government gazettes (e.g. legislative.gov.in, Supreme Court of India portal).
              </li>
              <li>
                <strong>Not Legal Advice:</strong> Rishikesh Law Hub provides educational legal information and does not constitute formal advocate-client representation.
              </li>
              <li>
                <strong>External Links:</strong> We may link to official court websites or news sources. We do not control and are not responsible for the privacy practices of external third-party sites.
              </li>
            </ul>
          </section>

          {/* Section 6: Children's Privacy */}
          <section className="rounded-2xl border border-slate-200/80 bg-white p-6 sm:p-8 shadow-sm">
            <h2 className="text-base font-bold text-slate-900 mb-2">6. Children&apos;s Privacy</h2>
            <p className="text-xs text-slate-600">
              Rishikesh Law Hub is designed for law students, advocates, judicial aspirants, and adults (aged 13 and above). We do not knowingly collect personal identifiable information from children under the age of 13. If you become aware that a child has provided us with personal data, please contact us immediately so we can remove it.
            </p>
          </section>

          {/* Section 7: Contact Us */}
          <section className="rounded-2xl border border-slate-200/80 bg-slate-900 text-white p-6 sm:p-8 shadow-md">
            <div className="flex items-center gap-3 pb-4 mb-4 border-b border-slate-800">
              <span className="flex size-9 items-center justify-center rounded-lg bg-amber-400 text-slate-900">
                <Mail className="size-5" />
              </span>
              <div>
                <h2 className="text-lg font-bold text-white">7. Contact Us & Grievance Redressal</h2>
                <p className="text-xs text-slate-400">Have questions about your privacy or data?</p>
              </div>
            </div>

            <div className="grid gap-4 sm:grid-cols-2 text-xs">
              <div>
                <p className="text-slate-400 mb-1 font-medium">Platform Owner & Publisher:</p>
                <p className="font-semibold text-white text-sm">Rishikesh Yadav</p>
                <p className="text-slate-300 mt-1">Rishikesh Law Hub</p>
              </div>

              <div>
                <p className="text-slate-400 mb-1 font-medium">Official Contact Email:</p>
                <a
                  href="mailto:rishikesh4287@gmail.com"
                  className="font-semibold text-amber-400 hover:text-amber-300 underline text-sm block"
                >
                  rishikesh4287@gmail.com
                </a>
                <p className="text-slate-400 mt-1">Response time: within 24–48 business hours</p>
              </div>
            </div>
          </section>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-200 bg-white py-8 text-center text-xs text-slate-500">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p>© {new Date().getFullYear()} Rishikesh Law Hub. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <Link to="/privacy-policy" className="hover:text-slate-900 font-semibold text-slate-800">Privacy Policy</Link>
            <Link to="/terms-of-service" className="hover:text-slate-900 font-medium">Terms of Service</Link>
            <Link to="/delete-account" className="hover:text-slate-900 font-medium">Delete Account</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
