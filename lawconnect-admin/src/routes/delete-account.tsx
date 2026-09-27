import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import {
  Scale,
  Trash2,
  AlertTriangle,
  Clock,
  ShieldCheck,
  CheckCircle2,
  Mail,
  Send,
  Loader2,
  Info,
  UserX,
  Database,
  Calendar,
} from "lucide-react";
import { api } from "@/lib/api";

export const Route = createFileRoute("/delete-account")({
  head: () => ({
    meta: [
      { title: "Delete Account & User Data — Rishikesh Law Hub" },
      {
        name: "description",
        content:
          "Official user account and data deletion request portal for Rishikesh Law Hub mobile application and web platform in accordance with Google Play Console policies.",
      },
      { property: "og:title", content: "Delete Account & User Data — Rishikesh Law Hub" },
      {
        property: "og:description",
        content:
          "Request permanent deletion of your Rishikesh Law Hub account and personal data with a 7-day restore window.",
      },
      { property: "og:type", content: "website" },
    ],
  }),
  component: DeleteAccountPage,
});

function DeleteAccountPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [reason, setReason] = useState("I no longer need this account");
  const [customReason, setCustomReason] = useState("");
  const [loading, setLoading] = useState(false);
  const [successData, setSuccessData] = useState<{
    message: string;
    scheduledDeletionAt?: string;
  } | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !email.includes("@")) {
      setErrorMessage("Please provide a valid email address.");
      return;
    }

    setLoading(true);
    setErrorMessage(null);

    const finalReason = reason === "Other" ? customReason : reason;

    try {
      const res = await api<{ ok: boolean; message: string; scheduledDeletionAt?: string }>(
        "/api/auth/request-web-deletion",
        {
          method: "POST",
          body: {
            email: email.trim(),
            password: password || undefined,
            reason: finalReason || "User submitted deletion request via web portal",
          },
          auth: false,
        }
      );

      setSuccessData({
        message: res.message || "Account deletion request submitted successfully.",
        scheduledDeletionAt: res.scheduledDeletionAt,
      });
    } catch (err: any) {
      setErrorMessage(
        err?.message || "Failed to submit deletion request. Please verify your details or contact support."
      );
    } finally {
      setLoading(false);
    }
  };

  const getSevenDaysLaterFormatted = () => {
    const d = new Date();
    d.setDate(d.getDate() + 7);
    return d.toLocaleDateString("en-US", {
      month: "long",
      day: "numeric",
      year: "numeric",
    });
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-800 antialiased selection:bg-rose-100 selection:text-rose-900">
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
              <span className="text-xs font-medium text-slate-500">
                Account & Data Management Portal
              </span>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:py-14">
        {/* Title Header */}
        <div className="mb-10 text-center sm:text-left border-b border-slate-200 pb-8">
          <div className="inline-flex items-center gap-2 rounded-full bg-rose-50 px-3 py-1 text-xs font-semibold text-rose-700 ring-1 ring-inset ring-rose-600/20 mb-3">
            <ShieldCheck className="size-3.5" />
            Google Play Console User Data Safety Compliant
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 sm:text-4xl">
            Delete Account & Personal Data
          </h1>
          <p className="mt-2 text-sm text-slate-600">
            Official Data Retention & Account Deletion Request Portal
          </p>
          <p className="mt-3 text-base text-slate-600 max-w-3xl leading-relaxed">
            At <strong>Rishikesh Law Hub</strong>, we respect your privacy and ownership of your
            personal data. You can request the complete deletion of your account, published
            community posts, private case notes, bookmarks, and activity history directly through
            this portal or within the mobile application.
          </p>
        </div>

        <div className="grid gap-10 lg:grid-cols-12">
          {/* Left Column: Form (7 cols) */}
          <div className="lg:col-span-7 space-y-6">
            <div className="rounded-2xl border border-slate-200 bg-white p-6 sm:p-8 shadow-sm">
              <div className="flex items-center gap-3 border-b border-slate-100 pb-4 mb-6">
                <span className="flex size-9 items-center justify-center rounded-lg bg-rose-50 text-rose-600">
                  <UserX className="size-5" />
                </span>
                <div>
                  <h2 className="text-lg font-bold text-slate-900">Request Account Deletion</h2>
                  <p className="text-xs text-slate-500">
                    Submit your registered email to schedule deletion
                  </p>
                </div>
              </div>

              {successData ? (
                <div className="space-y-4 rounded-xl border border-emerald-200 bg-emerald-50/70 p-6 text-emerald-900">
                  <div className="flex items-center gap-3">
                    <CheckCircle2 className="size-7 text-emerald-600 shrink-0" />
                    <div>
                      <h3 className="font-bold text-emerald-950 text-base">
                        Deletion Request Scheduled
                      </h3>
                      <p className="text-xs text-emerald-800 mt-0.5">{successData.message}</p>
                    </div>
                  </div>

                  <div className="rounded-lg bg-white/80 p-4 border border-emerald-200 text-xs text-slate-700 space-y-2 mt-3">
                    <div className="flex items-center gap-2 font-semibold text-slate-900">
                      <Calendar className="size-4 text-emerald-600" />
                      <span>7-Day Grace Period Window:</span>
                    </div>
                    <p>
                      Your account will remain in a scheduled deletion state for <strong>7 days</strong>.
                      Permanent data purge will occur on:{" "}
                      <span className="font-bold text-rose-700">
                        {successData.scheduledDeletionAt
                          ? new Date(successData.scheduledDeletionAt).toLocaleDateString("en-US", {
                              month: "long",
                              day: "numeric",
                              year: "numeric",
                            })
                          : getSevenDaysLaterFormatted()}
                      </span>
                      .
                    </p>
                    <div className="pt-2 border-t border-emerald-100">
                      <p className="text-emerald-900 font-medium">
                        💡 <strong>Changed your mind?</strong> Simply log back into the Rishikesh Law
                        Hub mobile app at any time before the 7 days are up. Logging in will
                        automatically cancel this deletion request and restore your account in full.
                      </p>
                    </div>
                  </div>

                  <button
                    onClick={() => {
                      setSuccessData(null);
                      setEmail("");
                      setPassword("");
                    }}
                    className="mt-4 text-xs font-semibold text-emerald-800 hover:text-emerald-950 underline"
                  >
                    Submit another request
                  </button>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-4">
                  {errorMessage && (
                    <div className="rounded-lg border border-rose-200 bg-rose-50 p-3.5 text-xs text-rose-700 flex items-start gap-2">
                      <AlertTriangle className="size-4 shrink-0 mt-0.5" />
                      <span>{errorMessage}</span>
                    </div>
                  )}

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                      Registered Email Address <span className="text-rose-600">*</span>
                    </label>
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="e.g. advocate.name@gmail.com"
                      className="w-full rounded-xl border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-rose-500 focus:outline-none focus:ring-2 focus:ring-rose-500/20 transition"
                    />
                    <p className="mt-1 text-[11px] text-slate-500">
                      The exact email address you used to sign up in the Rishikesh Law Hub app.
                    </p>
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                      Account Password <span className="text-slate-400 font-normal">(Optional for verification)</span>
                    </label>
                    <input
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Enter password if known"
                      className="w-full rounded-xl border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 placeholder:text-slate-400 focus:border-rose-500 focus:outline-none focus:ring-2 focus:ring-rose-500/20 transition"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                      Reason for Deletion <span className="text-slate-400 font-normal">(Optional)</span>
                    </label>
                    <select
                      value={reason}
                      onChange={(e) => setReason(e.target.value)}
                      className="w-full rounded-xl border border-slate-300 bg-white px-3.5 py-2.5 text-sm text-slate-900 focus:border-rose-500 focus:outline-none focus:ring-2 focus:ring-rose-500/20 transition"
                    >
                      <option value="I no longer need this account">I no longer need this account</option>
                      <option value="Completed my studies/cases">Completed my legal research/cases</option>
                      <option value="Creating a new account">Creating a fresh account</option>
                      <option value="Privacy or data concerns">Privacy or data concerns</option>
                      <option value="Other">Other reason</option>
                    </select>
                  </div>

                  {reason === "Other" && (
                    <div>
                      <textarea
                        rows={2}
                        value={customReason}
                        onChange={(e) => setCustomReason(e.target.value)}
                        placeholder="Please tell us how we can improve..."
                        className="w-full rounded-xl border border-slate-300 bg-white px-3.5 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-rose-500 focus:outline-none focus:ring-2 focus:ring-rose-500/20 transition"
                      />
                    </div>
                  )}

                  {/* 7-Day Warning Card */}
                  <div className="rounded-xl border border-amber-200 bg-amber-50/80 p-4 text-xs text-amber-900 space-y-1.5">
                    <div className="flex items-center gap-2 font-bold text-amber-950">
                      <Clock className="size-4 text-amber-700" />
                      <span>7-Day Grace Period & Auto-Restore Policy</span>
                    </div>
                    <p className="leading-relaxed text-amber-800">
                      When you submit this request, your account will enter a <strong>7-day grace period</strong>. 
                      If you <strong>do not log in within 7 days</strong>, your account and all associated data 
                      will be permanently deleted. If you log back into the app before the 7 days are up, 
                      your deletion request is automatically cancelled and your account remains intact.
                    </p>
                  </div>

                  <button
                    type="submit"
                    disabled={loading}
                    className="w-full inline-flex items-center justify-center gap-2 rounded-xl bg-rose-600 px-5 py-3 text-sm font-bold text-white shadow-sm hover:bg-rose-700 focus:outline-none focus:ring-2 focus:ring-rose-500/40 disabled:opacity-50 transition"
                  >
                    {loading ? (
                      <>
                        <Loader2 className="size-4 animate-spin" />
                        Submitting Deletion Request...
                      </>
                    ) : (
                      <>
                        <Trash2 className="size-4" />
                        Schedule Account Deletion (7-Day Period)
                      </>
                    )}
                  </button>
                </form>
              )}
            </div>
          </div>

          {/* Right Column: Information & Policy (5 cols) */}
          <div className="lg:col-span-5 space-y-6 text-sm text-slate-600">
            {/* What Data is Deleted */}
            <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="flex items-center gap-2.5 font-bold text-slate-900 mb-3">
                <Database className="size-4 text-indigo-600" />
                <h3 className="text-sm uppercase tracking-wider">What Data Will Be Purged?</h3>
              </div>
              <p className="text-xs text-slate-600 mb-3">
                After the 7-day grace period expires, the following data is permanently wiped from our databases:
              </p>
              <ul className="text-xs space-y-2 text-slate-700">
                <li className="flex items-start gap-2">
                  <CheckCircle2 className="size-4 text-rose-600 shrink-0 mt-0.5" />
                  <span><strong>Profile Identity:</strong> Name, Email, Password Hash, Bio, College affiliation, Avatar.</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle2 className="size-4 text-rose-600 shrink-0 mt-0.5" />
                  <span><strong>Community Contributions:</strong> Law forum posts, questions, answers, and comments.</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle2 className="size-4 text-rose-600 shrink-0 mt-0.5" />
                  <span><strong>Personal Notes:</strong> All private case brief notes and section annotations.</span>
                </li>
                <li className="flex items-start gap-2">
                  <CheckCircle2 className="size-4 text-rose-600 shrink-0 mt-0.5" />
                  <span><strong>Saved Items & History:</strong> Bookmarked judgments, bare acts, and reading history logs.</span>
                </li>
              </ul>
            </div>

            {/* In-App Instructions */}
            <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="flex items-center gap-2.5 font-bold text-slate-900 mb-3">
                <Info className="size-4 text-blue-600" />
                <h3 className="text-sm uppercase tracking-wider">How to Delete In-App</h3>
              </div>
              <p className="text-xs text-slate-600 mb-2">
                If you have the Rishikesh Law Hub mobile app installed on your Android device:
              </p>
              <ol className="text-xs space-y-1.5 text-slate-700 list-decimal pl-4">
                <li>Open <strong>Rishikesh Law Hub</strong> app.</li>
                <li>Tap the <strong>Profile</strong> tab in the bottom bar.</li>
                <li>Tap <strong>Settings</strong>.</li>
                <li>Scroll down to <strong>Account Management</strong>.</li>
                <li>Tap <strong>Delete Account</strong> and confirm.</li>
              </ol>
            </div>

            {/* Direct Contact Support */}
            <div className="rounded-2xl border border-slate-200 bg-slate-900 text-white p-6 shadow-sm">
              <div className="flex items-center gap-2.5 font-bold text-white mb-2">
                <Mail className="size-4 text-amber-400" />
                <h3 className="text-sm uppercase tracking-wider">Need Immediate Help?</h3>
              </div>
              <p className="text-xs text-slate-300 leading-relaxed">
                If you encounter any difficulty submitting this form or have questions regarding your data:
              </p>
              <div className="mt-3 pt-3 border-t border-slate-800 text-xs">
                <p className="text-slate-400">Platform Publisher:</p>
                <p className="font-semibold text-white">Rishikesh Yadav</p>
                <a
                  href="mailto:rishikesh4287@gmail.com"
                  className="font-semibold text-amber-400 hover:text-amber-300 underline block mt-1"
                >
                  rishikesh4287@gmail.com
                </a>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-200 bg-white py-8 text-center text-xs text-slate-500">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p>© {new Date().getFullYear()} Rishikesh Law Hub. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <a href="/privacy-policy" className="hover:text-slate-900 font-medium">
              Privacy Policy
            </a>
            <a href="/delete-account" className="hover:text-slate-900 font-semibold text-slate-800">
              Delete Account
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}
