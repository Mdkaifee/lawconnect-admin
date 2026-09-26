import { IndianKanoonService } from "./indianKanoon.js";
import { Case } from "../models/index.js";

let lastSyncHour = null;

/**
 * Initializes the automated 12-hour sync scheduler (at 6:00 AM & 6:00 PM IST)
 */
export function startScheduler() {
  console.log("[Scheduler] Initializing 12-hour Indian Kanoon sync service (6:00 AM & 6:00 PM IST)...");

  // 1. Initial check on startup: if DB has few cases, seed/sync immediately
  setTimeout(async () => {
    try {
      const count = await Case.countDocuments();
      if (count < 10) {
        console.log(`[Scheduler] Initial case count (${count}) is low. Running initial database synchronization...`);
        const res = await IndianKanoonService.syncToDatabase();
        console.log("[Scheduler] Initial database sync finished:", res.message);
      }
    } catch (e) {
      console.error("[Scheduler] Initial sync check failed:", e?.message || e);
    }
  }, 2000);

  // 2. Periodic check every minute for 6:00 AM / 6:00 PM IST
  setInterval(async () => {
    try {
      const now = new Date();
      // Calculate IST time (UTC + 5:30)
      const istTime = new Date(now.getTime() + (5.5 * 60 * 60 * 1000));
      const hours = istTime.getUTCHours(); // IST hour (0-23)
      const minutes = istTime.getUTCMinutes(); // IST minute (0-59)

      // Check if it is 6 AM (06:00) or 6 PM (18:00)
      if ((hours === 6 || hours === 18) && minutes === 0) {
        const syncKey = `${istTime.getUTCFullYear()}-${istTime.getUTCMonth()}-${istTime.getUTCDate()}-${hours}`;
        if (lastSyncHour !== syncKey) {
          lastSyncHour = syncKey;
          console.log(`[Scheduler] Triggering scheduled Indian Kanoon sync at ${hours}:00 IST...`);
          const result = await IndianKanoonService.syncToDatabase();
          console.log("[Scheduler] Scheduled sync completed successfully:", result.message);
        }
      }
    } catch (err) {
      console.error("[Scheduler] Error in sync scheduler interval:", err?.message || err);
    }
  }, 60 * 1000); // Check every minute
}
