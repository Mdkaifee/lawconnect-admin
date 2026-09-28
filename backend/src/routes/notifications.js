import { Router } from "express";
import { AppNotification, Case, LegalUpdate, Act } from "../models/index.js";
import { auth, requireAdmin, asyncHandler } from "../middleware/auth.js";
import { notifyAllUsers, notifyUsers } from "../services/notifications.js";

const router = Router();

/* ---------------- 1. Get Notifications & Unread Count ---------------- */
router.get(
  "/",
  auth({ optional: true }),
  asyncHandler(async (req, res) => {
    const userId = req.auth?.id;
    const filter = userId
      ? { $or: [{ userId }, { userId: null }] }
      : { userId: null };

    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 30));
    const skip = (page - 1) * limit;

    const [rawItems, total] = await Promise.all([
      AppNotification.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
      AppNotification.countDocuments(filter),
    ]);

    // Format items with dynamic isRead state for the requesting user
    const items = rawItems.map((item) => {
      const isReadForUser = userId
        ? Boolean(item.isRead || (item.readBy && item.readBy.some((id) => id.toString() === userId.toString())))
        : Boolean(item.isRead);

      return {
        id: item._id.toString(),
        title: item.title,
        body: item.body,
        type: item.type || "general",
        refId: item.refId || null,
        refType: item.refType || "general",
        isRead: isReadForUser,
        createdAt: item.createdAt,
      };
    });

    const unreadCount = items.filter((i) => !i.isRead).length;

    res.json({
      items,
      unreadCount,
      total,
      page,
      limit,
    });
  }),
);

/* ---------------- 2. Mark All as Read ---------------- */
router.post(
  "/read-all",
  auth(),
  asyncHandler(async (req, res) => {
    const userId = req.auth.id;

    // Mark personal notifications as isRead: true
    await AppNotification.updateMany({ userId }, { $set: { isRead: true } });

    // Add user to readBy for broadcast notifications
    await AppNotification.updateMany(
      { userId: null, readBy: { $ne: userId } },
      { $addToSet: { readBy: userId } },
    );

    res.json({ success: true, unreadCount: 0 });
  }),
);

/* ---------------- 3. Mark Single Notification as Read ---------------- */
router.put(
  "/:id/read",
  auth({ optional: true }),
  asyncHandler(async (req, res) => {
    const userId = req.auth?.id;
    const { id } = req.params;

    const notif = await AppNotification.findById(id);
    if (!notif) {
      return res.status(404).json({ error: "Notification not found" });
    }

    if (userId) {
      if (notif.userId && notif.userId.toString() === userId.toString()) {
        notif.isRead = true;
      } else {
        if (!notif.readBy) notif.readBy = [];
        if (!notif.readBy.some((uid) => uid.toString() === userId.toString())) {
          notif.readBy.push(userId);
        }
      }
    } else {
      notif.isRead = true;
    }

    await notif.save();
    res.json({ success: true });
  }),
);

/* ---------------- 4. Delete / Dismiss Notification ---------------- */
router.delete(
  "/:id",
  auth(),
  asyncHandler(async (req, res) => {
    const userId = req.auth.id;
    const { id } = req.params;

    const notif = await AppNotification.findById(id);
    if (!notif) {
      return res.status(404).json({ error: "Notification not found" });
    }

    if (notif.userId && notif.userId.toString() === userId.toString()) {
      await AppNotification.findByIdAndDelete(id);
    } else {
      // For broadcast, add to readBy
      await AppNotification.findByIdAndUpdate(id, { $addToSet: { readBy: userId } });
    }

    res.json({ success: true });
  }),
);

/* ---------------- 5. Admin Create Broadcast / Notification ---------------- */
router.post(
  "/",
  auth(),
  requireAdmin,
  asyncHandler(async (req, res) => {
    const { title, body, type, refId, refType, userId } = req.body;
    if (!title || !body) {
      return res.status(400).json({ error: "Title and body are required" });
    }

    const notif = await AppNotification.create({
      userId: userId || null,
      title,
      body,
      type: type || "general",
      refId: refId || null,
      refType: refType || "general",
    });

    // Send push notification via Firebase FCM if configured
    if (userId) {
      await notifyUsers([userId], { title, body, data: { refId: refId || "", refType: refType || "" } });
    } else {
      await notifyAllUsers({ title, body, data: { refId: refId || "", refType: refType || "" } });
    }

    res.status(201).json({ item: notif });
  }),
);

export default router;
