import { User } from "../models/index.js";
import { purgeUserData } from "../routes/auth.js";

/**
 * Initializes a background scheduler that runs periodically (every 1 hour)
 * to permanently delete accounts whose 7-day grace period has expired.
 */
export function initScheduler() {
  const CHECK_INTERVAL_MS = 60 * 60 * 1000; // 1 hour

  const runPurgeJob = async () => {
    try {
      const now = new Date();
      // Find all users with deletionRequested = true and deletionDueAt <= now
      const expiredUsers = await User.find({
        deletionRequested: true,
        deletionDueAt: { $lte: now },
      }).select("_id email");

      if (expiredUsers.length > 0) {
        console.log(`[Scheduler] Found ${expiredUsers.length} account(s) due for permanent deletion.`);
        for (const user of expiredUsers) {
          try {
            await purgeUserData(user._id);
            console.log(`[Scheduler] Successfully purged user account: ${user.email} (${user._id})`);
          } catch (err) {
            console.error(`[Scheduler] Failed to purge user ${user._id}:`, err?.message || err);
          }
        }
      }
    } catch (error) {
      console.error("[Scheduler] Error running deletion purge job:", error?.message || error);
    }
  };

  // Run initial check after 30 seconds of server startup
  setTimeout(runPurgeJob, 30 * 1000);

  // Set recurring interval
  const timer = setInterval(runPurgeJob, CHECK_INTERVAL_MS);

  console.log("[Scheduler] Account deletion cleanup service initialized (Hourly check).");
  return timer;
}
