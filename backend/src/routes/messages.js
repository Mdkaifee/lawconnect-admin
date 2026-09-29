import { Router } from "express";
import mongoose from "mongoose";
import { auth, requireUser, asyncHandler } from "../middleware/auth.js";
import { AppNotification, Conversation, Message, PaymentAttempt, User } from "../models/index.js";
import { notifyUsers } from "../services/notifications.js";
import { markPaidIfCaptured, verifyRazorpayPaymentSignature } from "../services/chatPayments.js";

const router = Router();
router.use(auth(), requireUser);

const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);
const freeMessageLimit = Math.max(0, Number.parseInt(process.env.CHAT_MESSAGE_FREE_LIMIT || "5", 10) || 5);
const chatUnlockAmount = Number(process.env.CHAT_UNLOCK_AMOUNT || "11");
const chatPaidDurationMonths = Math.max(
  1,
  Number.parseInt(process.env.PAID_CHAT_MONTHS || process.env.CHAT_PAID_DURATION_MONTHS || "3", 10) || 3,
);
const isOnline = (lastActiveAt) => lastActiveAt && Date.now() - new Date(lastActiveAt).getTime() <= 5 * 60 * 1000;

async function getChatAccess(conversation, userId) {
  const [sentCount, user] = await Promise.all([
    Message.countDocuments({ conversationId: conversation._id, senderId: userId, kind: "message" }),
    User.findOne({ _id: userId, blocked: { $ne: true }, deletionRequested: { $ne: true } }).select("chatPaidUntil"),
  ]);
  const paidUntil = user?.chatPaidUntil || null;
  const isPaid = Boolean(paidUntil && new Date(paidUntil).getTime() > Date.now());
  return { sentCount, freeLimit: freeMessageLimit, unlockAmount: chatUnlockAmount, isPaid, paidUntil, canSend: Boolean(user) && (isPaid || sentCount < freeMessageLimit) };
}

const paymentDurationMonths = Math.max(1, Number.parseInt(process.env.PAID_CHAT_MONTHS || process.env.CHAT_PAID_DURATION_MONTHS || "3", 10) || 3);

function razorpayHeaders() {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keyId || !keySecret) return null;
  return { keyId, Authorization: `Basic ${Buffer.from(`${keyId}:${keySecret}`).toString("base64")}` };
}

async function razorpayGet(path) {
  const credentials = razorpayHeaders();
  if (!credentials) throw Object.assign(new Error("Chat payments are not configured"), { status: 503 });
  const response = await fetch(`https://api.razorpay.com/v1${path}`, { headers: { Authorization: credentials.Authorization } });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    console.error("Razorpay API lookup failed", { status: response.status, code: data.error?.code || "unknown", description: data.error?.description || "No provider description" });
    throw Object.assign(new Error("Could not confirm payment with Razorpay yet. Please try again shortly."), { status: 503 });
  }
  return data;
}

async function capturedPaymentForOrder(orderId) {
  const result = await razorpayGet(`/orders/${encodeURIComponent(orderId)}/payments`);
  return (result.items || []).find((payment) => payment.status === "captured" && payment.captured === true) || null;
}

async function migrateLegacyPaymentAttempts(user) {
  const legacy = user.chatPaymentOrders || [];
  if (!legacy.length) return;
  const operations = legacy.filter((item) => item.orderId).map((item) => {
    const paymentId = item.paymentId && !String(item.paymentId).startsWith("recovered:") ? item.paymentId : undefined;
    return {
      updateOne: {
        filter: { razorpayOrderId: item.orderId },
        update: { $setOnInsert: {
          userId: user._id,
          razorpayOrderId: item.orderId,
          ...(paymentId ? { razorpayPaymentId: paymentId } : {}),
          amount: item.amountPaise,
          currency: "INR",
          status: ["paid", "failed", "cancelled"].includes(item.status) ? item.status : "created",
          accessGrantedAt: null,
        } },
        upsert: true,
      },
    };
  });
  if (operations.length) await PaymentAttempt.bulkWrite(operations, { ordered: false });
}

async function applyCapturedPayment(payment) {
  return markPaidIfCaptured(payment, { PaymentAttempt, User, durationMonths: paymentDurationMonths });
}

async function reconcileAttempt(attempt, { checkoutClosed = false, cancelled = false } = {}) {
  const payment = await capturedPaymentForOrder(attempt.razorpayOrderId);
  if (payment) {
    const result = await applyCapturedPayment(payment);
    if (result.error) throw Object.assign(new Error(result.error), { status: 409 });
    return { paid: result.paid, cancelled: false, chatPaidUntil: result.chatPaidUntil || null };
  }
  if (checkoutClosed && attempt.status !== "paid") {
    const status = cancelled ? "cancelled" : "failed";
    await PaymentAttempt.updateOne({ _id: attempt._id, status: { $ne: "paid" } }, { $set: { status } });
  }
  const user = await User.findById(attempt.userId).select("chatPaidUntil").lean();
  return { paid: false, cancelled: checkoutClosed && cancelled, chatPaidUntil: user?.chatPaidUntil || null };
}

async function loadActiveConversation(req, res) {
  if (!isValidId(req.params.id)) {
    res.status(400).json({ error: "Invalid conversation id" });
    return null;
  }
  const conversation = await Conversation.findOne({ _id: req.params.id, participants: req.auth.id });
  if (!conversation) {
    res.status(404).json({ error: "Conversation not found" });
    return null;
  }
  return conversation;
}

async function touchUser(userId) {
  await User.findByIdAndUpdate(userId, { lastActiveAt: new Date() });
}

async function areFriends(userA, userB) {
  const [a, b] = await Promise.all([
    User.findById(userA).select("following").lean(),
    User.findById(userB).select("following").lean(),
  ]);
  const aFollowing = (a?.following || []).map((id) => id.toString());
  const bFollowing = (b?.following || []).map((id) => id.toString());
  return aFollowing.includes(userB.toString()) && bFollowing.includes(userA.toString());
}

async function findConversation(userA, userB) {
  return Conversation.findOne({ participants: { $all: [userA, userB], $size: 2 } });
}

function serializeUser(user) {
  const chatPaidUntil = user.chatPaidUntil || null;
  return {
    id: user._id.toString(),
    name: user.name || "",
    email: user.email || "",
    photoUrl: user.photoUrl || "",
    headline: user.headline || "",
    college: user.college || "",
    lastActiveAt: user.lastActiveAt,
    isOnline: isOnline(user.lastActiveAt),
    chatPaidUntil,
    isChatPaid: Boolean(chatPaidUntil && new Date(chatPaidUntil).getTime() > Date.now()),
  };
}

function serializeConversation(conversation, otherUser, currentUserId, unreadCount = 0) {
  return {
    id: conversation._id.toString(),
    status: conversation.status,
    requestedBy: conversation.requestedBy?.toString() || "",
    isRequester: conversation.requestedBy?.toString() === currentUserId.toString(),
    lastMessage: conversation.lastMessage || "",
    lastMessageAt: conversation.lastMessageAt || conversation.updatedAt,
    unreadCount,
    otherUser: serializeUser(otherUser),
  };
}

router.get(
  "/conversations",
  asyncHandler(async (req, res) => {
    await touchUser(req.auth.id);
    const conversations = await Conversation.find({ participants: req.auth.id, status: { $ne: "ignored" } })
      .sort({ lastMessageAt: -1, updatedAt: -1 })
      .lean();
    const otherIds = conversations
      .map((c) => (c.participants || []).map((id) => id.toString()).find((id) => id !== req.auth.id))
      .filter(Boolean);
    const users = await User.find({ _id: { $in: otherIds }, blocked: { $ne: true }, deletionRequested: { $ne: true } }).select("-passwordHash").lean();
    const userMap = Object.fromEntries(users.map((u) => [u._id.toString(), u]));
    const unreadCounts = await Message.aggregate([
      { $match: { conversationId: { $in: conversations.map((c) => c._id) }, receiverId: new mongoose.Types.ObjectId(req.auth.id), readAt: null } },
      { $group: { _id: "$conversationId", count: { $sum: 1 } } },
    ]);
    const unreadMap = Object.fromEntries(unreadCounts.map((u) => [u._id.toString(), u.count]));
    const items = conversations
      .map((c) => {
        const otherId = (c.participants || []).map((id) => id.toString()).find((id) => id !== req.auth.id);
        const otherUser = userMap[otherId];
        return otherUser ? serializeConversation(c, otherUser, req.auth.id, unreadMap[c._id.toString()] || 0) : null;
      })
      .filter(Boolean);
    res.json({ items });
  }),
);

router.get(
  "/conversations/:id",
  asyncHandler(async (req, res) => {
    await touchUser(req.auth.id);
    if (!isValidId(req.params.id)) return res.status(400).json({ error: "Invalid conversation id" });
    const conversation = await Conversation.findOne({ _id: req.params.id, participants: req.auth.id });
    if (!conversation) return res.status(404).json({ error: "Conversation not found" });
    const otherId = conversation.participants.map((id) => id.toString()).find((id) => id !== req.auth.id);
    const otherUser = await User.findOne({ _id: otherId, blocked: { $ne: true }, deletionRequested: { $ne: true } }).select("-passwordHash").lean();
    if (!otherUser) return res.status(404).json({ error: "Conversation participant is inactive" });
    const messages = await Message.find({ conversationId: conversation._id }).sort({ createdAt: 1 }).lean();
    res.json({
      conversation: serializeConversation(conversation, otherUser, req.auth.id),
      chatAccess: await getChatAccess(conversation, req.auth.id),
      messages: messages.map((m) => ({
        id: m._id.toString(),
        conversationId: m.conversationId.toString(),
        senderId: m.senderId.toString(),
        receiverId: m.receiverId.toString(),
        body: m.body,
        kind: m.kind,
        readAt: m.readAt,
        createdAt: m.createdAt,
      })),
    });
  }),
);

router.post(
  "/conversations/:id/payment/order",
  asyncHandler(async (req, res) => {
    const conversation = await loadActiveConversation(req, res);
    if (!conversation) return;
    const user = await User.findOne({ _id: req.auth.id, blocked: { $ne: true }, deletionRequested: { $ne: true } });
    if (!user) return res.status(403).json({ error: "Active account required" });
    const access = await getChatAccess(conversation, req.auth.id);
    if (access.isPaid) return res.json({ paid: true, chatPaidUntil: access.paidUntil });
    if (access.sentCount < freeMessageLimit) return res.status(400).json({ error: "Free messages remain", chatAccess: access });

    const keyId = process.env.RAZORPAY_KEY_ID;
    const keySecret = process.env.RAZORPAY_KEY_SECRET;
    if (!keyId || !keySecret) return res.status(503).json({ error: "Chat payments are not configured yet" });
    if (!Number.isFinite(chatUnlockAmount) || chatUnlockAmount <= 0) return res.status(503).json({ error: "Chat unlock amount is not configured" });
    await migrateLegacyPaymentAttempts(user);

    // Reconcile recent attempts before creating anything. A successful capture can arrive
    // after checkout closed or after the app lost its callback.
    const recentAttempts = await PaymentAttempt.find({ userId: user._id, status: { $ne: "paid" } }).sort({ createdAt: -1 }).limit(10);
    for (const prior of recentAttempts) {
      const status = await reconcileAttempt(prior);
      if (status.paid) return res.json({ paid: true, chatPaidUntil: status.chatPaidUntil });
    }
    const reusable = recentAttempts.find((item) => item.status === "created");
    if (reusable) return res.json({ orderId: reusable.razorpayOrderId, amount: reusable.amount, currency: reusable.currency, keyId });

    const amountPaise = Math.round(chatUnlockAmount * 100);
    const razorpayResponse = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        Authorization: `Basic ${Buffer.from(`${keyId}:${keySecret}`).toString("base64")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: amountPaise,
        currency: "INR",
        receipt: `chat_${Date.now()}_${crypto.randomBytes(3).toString("hex")}`,
        notes: { conversationId: conversation._id.toString(), userId: req.auth.id, purpose: "chat_unlock" },
      }),
    });
    const order = await razorpayResponse.json().catch(() => ({}));
    if (!razorpayResponse.ok || !order.id) {
      console.error("Razorpay order creation failed:", {
        status: razorpayResponse.status,
        code: order.error?.code || "unknown",
        description: order.error?.description || "No provider description",
        field: order.error?.field || null,
      });
      return res.status(502).json({ error: "Payment provider rejected the order. Please check the Razorpay server credentials and payment setup." });
    }
    await PaymentAttempt.create({ userId: user._id, razorpayOrderId: order.id, amount: amountPaise, currency: "INR", status: "created" });
    res.status(201).json({ orderId: order.id, amount: amountPaise, currency: "INR", keyId });
  }),
);

router.post(
  ["/conversations/:id/payment/reconcile", "/conversations/:id/payment/cancel"],
  asyncHandler(async (req, res) => {
    const conversation = await loadActiveConversation(req, res);
    if (!conversation) return;
    const orderId = (req.body?.orderId || req.body?.razorpayOrderId || "").toString();
    if (!orderId) return res.status(400).json({ error: "Payment order is required" });
    const user = await User.findOne({ _id: req.auth.id, blocked: { $ne: true }, deletionRequested: { $ne: true } });
    if (!user) return res.status(403).json({ error: "Active account required" });
    await migrateLegacyPaymentAttempts(user);
    const attempt = await PaymentAttempt.findOne({ razorpayOrderId: orderId, userId: user._id });
    if (!attempt) return res.status(404).json({ error: "Payment order not found" });
    const result = await reconcileAttempt(attempt, {
      checkoutClosed: req.body?.checkoutClosed === true || req.body?.cancelled === true,
      cancelled: req.body?.cancelled === true,
    });
    res.json({ ok: true, ...result });
  }),
);

router.post(
  "/conversations/:id/payment/verify",
  asyncHandler(async (req, res) => {
    const conversation = await loadActiveConversation(req, res);
    if (!conversation) return;
    const razorpayOrderId = req.body?.razorpay_order_id || req.body?.razorpayOrderId;
    const razorpayPaymentId = req.body?.razorpay_payment_id || req.body?.razorpayPaymentId;
    const razorpaySignature = req.body?.razorpay_signature || req.body?.razorpaySignature;
    if (![razorpayOrderId, razorpayPaymentId, razorpaySignature].every((value) => typeof value === "string" && value.length > 0)) {
      return res.status(400).json({ error: "Payment details are incomplete" });
    }
    const user = await User.findOne({ _id: req.auth.id, blocked: { $ne: true }, deletionRequested: { $ne: true } });
    if (!user) return res.status(403).json({ error: "Active account required" });
    await migrateLegacyPaymentAttempts(user);
    const attempt = await PaymentAttempt.findOne({ razorpayOrderId, userId: user._id });
    if (!attempt) return res.status(400).json({ error: "Payment order does not belong to this account or chat" });
    const keySecret = process.env.RAZORPAY_KEY_SECRET;
    if (!process.env.RAZORPAY_KEY_ID || !keySecret) return res.status(503).json({ error: "Chat payments are not configured yet" });
    if (!verifyRazorpayPaymentSignature(razorpayOrderId, razorpayPaymentId, razorpaySignature, keySecret)) {
      return res.status(400).json({ error: "Payment verification failed" });
    }
    const payment = await razorpayGet(`/payments/${encodeURIComponent(razorpayPaymentId)}`);
    if (payment.order_id !== razorpayOrderId) return res.status(400).json({ error: "Payment does not belong to this order" });
    if (payment.status !== "captured" || payment.captured !== true) {
      return res.status(409).json({ error: "Payment has not been captured yet. Chat access unlocks after capture confirmation." });
    }
    const result = await applyCapturedPayment(payment);
    if (!result.paid) return res.status(409).json({ error: result.error || "Captured payment could not be confirmed" });
    res.json({ ok: true, paid: true, chatPaidUntil: result.chatPaidUntil, chatAccess: await getChatAccess(conversation, req.auth.id) });
  }),
);

router.post(
  "/users/:userId/request",
  asyncHandler(async (req, res) => {
    await touchUser(req.auth.id);
    const targetId = req.params.userId;
    const body = (req.body.body || "").toString().trim();
    if (!isValidId(targetId) || targetId === req.auth.id) return res.status(400).json({ error: "Invalid user" });
    if (!body) return res.status(400).json({ error: "Message is required" });
    if (body.length > 250) return res.status(400).json({ error: "Message request is limited to 250 characters" });

    const [sender, receiver] = await Promise.all([
      User.findOne({ _id: req.auth.id, blocked: { $ne: true }, deletionRequested: { $ne: true } }).select("name"),
      User.findOne({ _id: targetId, blocked: { $ne: true }, deletionRequested: { $ne: true } }).select("name"),
    ]);
    if (!sender || !receiver) return res.status(404).json({ error: "User not found" });

    const existing = await findConversation(req.auth.id, targetId);
    if (existing?.status === "active") return res.status(400).json({ error: "Chat is already active" });
    if (existing?.status === "requested" && existing.requestedBy?.toString() === req.auth.id) {
      return res.status(400).json({ error: "Message request already sent" });
    }

    const conversation =
      existing ||
      (await Conversation.create({
        participants: [req.auth.id, targetId],
        status: "requested",
        requestedBy: req.auth.id,
      }));
    conversation.status = "requested";
    conversation.requestedBy = req.auth.id;
    conversation.lastMessage = body;
    conversation.lastMessageAt = new Date();
    conversation.lastSenderId = req.auth.id;
    conversation.readBy = [req.auth.id];
    await conversation.save();

    const message = await Message.create({ conversationId: conversation._id, senderId: req.auth.id, receiverId: targetId, body, kind: "request" });
    await notifyUsers([targetId], { title: "New message request", body: `${sender.name}: ${body.slice(0, 80)}`, data: { type: "message_request", conversationId: conversation._id.toString() } });
    await AppNotification.create({ userId: targetId, title: "New message request", body: `${sender.name}: ${body.slice(0, 80)}`, type: "community", refType: "message", refId: conversation._id.toString() });

    res.status(201).json({ conversationId: conversation._id.toString(), messageId: message._id.toString(), status: conversation.status });
  }),
);

router.post(
  "/conversations/:id/messages",
  asyncHandler(async (req, res) => {
    await touchUser(req.auth.id);
    const body = (req.body.body || "").toString().trim();
    if (!body) return res.status(400).json({ error: "Message is required" });
    if (body.length > 2000) return res.status(400).json({ error: "Message is too long" });

    const conversation = await Conversation.findOne({ _id: req.params.id, participants: req.auth.id });
    if (!conversation) return res.status(404).json({ error: "Conversation not found" });
    const otherId = conversation.participants.map((id) => id.toString()).find((id) => id !== req.auth.id);
    const friends = await areFriends(req.auth.id, otherId);
    if (conversation.status !== "active" && !friends) {
      return res.status(403).json({ error: "Message request must be accepted first" });
    }
    if (friends && conversation.status !== "active") conversation.status = "active";

    const sender = await User.findOne({ _id: req.auth.id, blocked: { $ne: true }, deletionRequested: { $ne: true } }).select("name");
    const receiver = await User.findOne({ _id: otherId, blocked: { $ne: true }, deletionRequested: { $ne: true } }).select("_id");
    if (!sender || !receiver) return res.status(403).json({ error: "Inactive account cannot send messages" });
    const chatAccess = await getChatAccess(conversation, req.auth.id);
    if (!chatAccess.canSend) {
      return res.status(402).json({ error: "Free messages used. Unlock this chat to continue.", paymentRequired: true, chatAccess });
    }
    const message = await Message.create({ conversationId: conversation._id, senderId: req.auth.id, receiverId: otherId, body });
    conversation.lastMessage = body;
    conversation.lastMessageAt = new Date();
    conversation.lastSenderId = req.auth.id;
    conversation.readBy = [req.auth.id];
    await conversation.save();

    await notifyUsers([otherId], { title: "New message", body: `${sender?.name || "Someone"}: ${body.slice(0, 80)}`, data: { type: "message", conversationId: conversation._id.toString() } });
    await AppNotification.create({ userId: otherId, title: "New message", body: `${sender?.name || "Someone"}: ${body.slice(0, 80)}`, type: "community", refType: "message", refId: conversation._id.toString() });
    res.status(201).json({ message: { id: message._id.toString(), body: message.body, senderId: message.senderId.toString(), receiverId: message.receiverId.toString(), createdAt: message.createdAt } });
  }),
);

router.post(
  "/conversations/:id/accept",
  asyncHandler(async (req, res) => {
    await touchUser(req.auth.id);
    const conversation = await Conversation.findOne({ _id: req.params.id, participants: req.auth.id });
    if (!conversation) return res.status(404).json({ error: "Conversation not found" });
    if (conversation.requestedBy?.toString() === req.auth.id) return res.status(400).json({ error: "Requester cannot accept their own request" });
    conversation.status = "active";
    await conversation.save();
    const requesterId = conversation.requestedBy.toString();
    const accepter = await User.findById(req.auth.id).select("name");
    await notifyUsers([requesterId], { title: "Message request accepted", body: `${accepter?.name || "User"} accepted your message request.`, data: { type: "message_request_accepted", conversationId: conversation._id.toString() } });
    await AppNotification.create({ userId: requesterId, title: "Message request accepted", body: `${accepter?.name || "User"} accepted your message request.`, type: "community", refType: "message", refId: conversation._id.toString() });
    res.json({ ok: true, status: "active" });
  }),
);

router.post(
  "/conversations/:id/ignore",
  asyncHandler(async (req, res) => {
    await touchUser(req.auth.id);
    const conversation = await Conversation.findOne({ _id: req.params.id, participants: req.auth.id });
    if (!conversation) return res.status(404).json({ error: "Conversation not found" });
    if (conversation.requestedBy?.toString() === req.auth.id) return res.status(400).json({ error: "Requester cannot ignore their own request" });
    conversation.status = "ignored";
    await conversation.save();
    res.json({ ok: true, status: "ignored" });
  }),
);

router.post(
  "/conversations/:id/read",
  asyncHandler(async (req, res) => {
    await touchUser(req.auth.id);
    const conversation = await Conversation.findOne({ _id: req.params.id, participants: req.auth.id });
    if (!conversation) return res.status(404).json({ error: "Conversation not found" });
    await Message.updateMany({ conversationId: conversation._id, receiverId: req.auth.id, readAt: null }, { $set: { readAt: new Date() } });
    await Conversation.findByIdAndUpdate(conversation._id, { $addToSet: { readBy: req.auth.id } });
    res.json({ ok: true });
  }),
);

router.get(
  "/users/:userId",
  asyncHandler(async (req, res) => {
    await touchUser(req.auth.id);
    const targetId = req.params.userId;
    if (!isValidId(targetId) || targetId === req.auth.id) return res.status(400).json({ error: "Invalid user" });
    let conversation = await findConversation(req.auth.id, targetId);
    const friends = await areFriends(req.auth.id, targetId);
    if (!conversation && friends) {
      conversation = await Conversation.create({ participants: [req.auth.id, targetId], status: "active", readBy: [req.auth.id, targetId] });
    }
    if (conversation && friends && conversation.status !== "active") {
      conversation.status = "active";
      await conversation.save();
    }
    res.json({ conversationId: conversation?._id?.toString() || "", status: conversation?.status || (friends ? "active" : "none"), isFriend: friends, isRequester: conversation?.requestedBy?.toString() === req.auth.id });
  }),
);

export default router;
