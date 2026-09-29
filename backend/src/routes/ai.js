import { Router } from "express";
import { auth, requireUser, asyncHandler } from "../middleware/auth.js";
import { User } from "../models/index.js";

const router = Router();
router.use(auth(), requireUser);

router.post(
  "/chat",
  asyncHandler(async (req, res) => {
    const user = await User.findOne({ _id: req.auth.id, blocked: { $ne: true }, deletionRequested: { $ne: true } }).select("_id");
    if (!user) return res.status(403).json({ error: "Active account required" });
    const messages = req.body?.messages;
    if (!Array.isArray(messages) || messages.length === 0 || messages.length > 24) {
      return res.status(400).json({ error: "Send between 1 and 24 chat messages" });
    }
    const safeMessages = [];
    for (const message of messages) {
      if (!message || !["user", "assistant"].includes(message.role) || typeof message.content !== "string" || !message.content.trim() || message.content.length > 4000) {
        return res.status(400).json({ error: "Each message needs a valid role and text under 4000 characters" });
      }
      safeMessages.push({ role: message.role, content: message.content.trim() });
    }
    if (safeMessages[safeMessages.length - 1].role !== "user") return res.status(400).json({ error: "The latest message must be from the user" });

    const apiKey = process.env.AI_API_KEY;
    if (!apiKey) return res.status(503).json({ error: "AI chat is not configured yet" });
    const provider = (process.env.AI_PROVIDER || "claude").toLowerCase();
    if (provider !== "claude") return res.status(503).json({ error: `AI provider '${provider}' is not supported by this backend` });
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: process.env.AI_MODEL || "claude-sonnet-4-6",
        max_tokens: 1200,
        system: "You are Law Hub AI, an informative legal research assistant. Give clear, general legal information, ask clarifying questions when necessary, distinguish general information from jurisdiction-specific advice, and encourage consulting a qualified lawyer for consequential matters. Never claim to be a lawyer or invent statutes, cases, citations, or facts.",
        messages: safeMessages,
      }),
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      console.error("Claude request failed:", data.error?.type || response.status);
      return res.status(502).json({ error: "AI could not answer right now. Please try again." });
    }
    const answer = (data.content || []).filter((part) => part.type === "text").map((part) => part.text).join("\n").trim();
    if (!answer) return res.status(502).json({ error: "AI returned an empty response. Please try again." });
    res.json({ reply: answer, model: data.model || process.env.AI_MODEL || "claude-sonnet-4-6" });
  }),
);

export default router;
