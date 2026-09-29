import { Router } from "express";
import mongoose from "mongoose";
import { auth, requireUser, asyncHandler } from "../middleware/auth.js";
import { AppNotification, Conversation, Message, User } from "../models/index.js";
import { notifyUsers } from "../services/notifications.js";

const router = Router();
router.use(auth(), requireUser);

const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);
const isOnline = (lastActiveAt) => lastActiveAt && Date.now() - new Date(lastActiveAt).getTime() <= 5 * 60 * 1000;

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
  return {
    id: user._id.toString(),
    name: user.name || "",
    email: user.email || "",
    photoUrl: user.photoUrl || "",
    headline: user.headline || "",
    college: user.college || "",
    lastActiveAt: user.lastActiveAt,
    isOnline: isOnline(user.lastActiveAt),
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
    const users = await User.find({ _id: { $in: otherIds } }).select("-passwordHash").lean();
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
    const otherUser = await User.findById(otherId).select("-passwordHash").lean();
    const messages = await Message.find({ conversationId: conversation._id }).sort({ createdAt: 1 }).lean();
    res.json({
      conversation: serializeConversation(conversation, otherUser, req.auth.id),
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
  "/users/:userId/request",
  asyncHandler(async (req, res) => {
    await touchUser(req.auth.id);
    const targetId = req.params.userId;
    const body = (req.body.body || "").toString().trim();
    if (!isValidId(targetId) || targetId === req.auth.id) return res.status(400).json({ error: "Invalid user" });
    if (!body) return res.status(400).json({ error: "Message is required" });
    if (body.length > 250) return res.status(400).json({ error: "Message request is limited to 250 characters" });

    const [sender, receiver] = await Promise.all([
      User.findById(req.auth.id).select("name"),
      User.findById(targetId).select("name"),
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

    const sender = await User.findById(req.auth.id).select("name");
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
