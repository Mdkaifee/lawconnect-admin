import admin from "firebase-admin";
import { User } from "../models/index.js";

let initialized = false;
let missingConfigLogged = false;

function initFirebase() {
  if (initialized || admin.apps.length) {
    initialized = true;
    return true;
  }

  const rawServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!rawServiceAccount) {
    if (!missingConfigLogged) {
      console.warn("[Notifications] FIREBASE_SERVICE_ACCOUNT_JSON is not set. Push notifications will not be sent.");
      missingConfigLogged = true;
    }
    return false;
  }

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
    const uniqueTokens = [...new Set(tokens)];
    const response = await admin.messaging().sendEachForMulticast({
      tokens: uniqueTokens,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
    });
    await removeInvalidTokens(uniqueTokens, response);
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
    const uniqueTokens = [...new Set(tokens)];
    const response = await admin.messaging().sendEachForMulticast({
      tokens: uniqueTokens,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
    });
    await removeInvalidTokens(uniqueTokens, response);
  } catch (error) {
    console.error("[Notifications] Broadcast failed:", error?.message || error);
  }
}

async function removeInvalidTokens(tokens, response) {
  const invalidTokens = [];

  response.responses.forEach((result, index) => {
    const code = result.error?.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length > 0) {
    await User.updateMany({ fcmTokens: { $in: invalidTokens } }, { $pull: { fcmTokens: { $in: invalidTokens } } });
  }
}
