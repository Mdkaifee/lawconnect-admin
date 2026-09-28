import admin from "firebase-admin";
import { User } from "../models/index.js";

let initialized = false;

function initFirebase() {
  if (initialized || admin.apps.length) {
    initialized = true;
    return true;
  }

  const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!rawServiceAccount) return false;

  try {
    const credentials = JSON.parse(rawServiceAccount);
    admin.initializeApp({
      credential: admin.credential.cert(credentials),
    });
    initialized = true;
    return true;
  } catch (error) {
    console.error("[Notifications] Firebase init failed:", error?.message || error);
    return false;
  }
}

export async function notifyUsers(userIds, { title, body, data = {} }) {
  if (!initFirebase()) return;
  const ids = [...new Set((userIds || []).map((id) => id?.toString()).filter(Boolean))];
  if (ids.length === 0) return;

  const users = await User.find({ _id: { $in: ids } }).select("fcmTokens");
  const tokens = users.flatMap((user) => user.fcmTokens || []).filter(Boolean);
  if (tokens.length === 0) return;

  try {
    await admin.messaging().sendEachForMulticast({
      tokens: [...new Set(tokens)],
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
    });
  } catch (error) {
    console.error("[Notifications] Send failed:", error?.message || error);
  }
}

export async function notifyAllUsers({ title, body, data = {} }) {
  if (!initFirebase()) return;
  const users = await User.find({ blocked: { $ne: true } }).select("fcmTokens");
  const tokens = users.flatMap((user) => user.fcmTokens || []).filter(Boolean);
  if (tokens.length === 0) return;

  try {
    await admin.messaging().sendEachForMulticast({
      tokens: [...new Set(tokens)],
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
    });
  } catch (error) {
    console.error("[Notifications] Broadcast failed:", error?.message || error);
  }
}
