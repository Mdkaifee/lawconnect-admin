import { Router } from "express";
import { PaymentAttempt, User } from "../models/index.js";
import { markPaidIfCaptured, verifyRazorpayWebhookSignature } from "../services/chatPayments.js";

const router = Router();
const durationMonths = Math.max(1, Number.parseInt(process.env.PAID_CHAT_MONTHS || process.env.CHAT_PAID_DURATION_MONTHS || "3", 10) || 3);

async function fetchCapturedPayment(orderId) {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keyId || !keySecret) throw new Error("Razorpay API credentials are not configured");
  const response = await fetch(`https://api.razorpay.com/v1/orders/${encodeURIComponent(orderId)}/payments`, {
    headers: { Authorization: `Basic ${Buffer.from(`${keyId}:${keySecret}`).toString("base64")}` },
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(`Razorpay order payment lookup returned HTTP ${response.status}`);
  return (data.items || []).find((payment) => payment.status === "captured") || null;
}

router.post("/", async (req, res) => {
  const signature = req.get("x-razorpay-signature") || "";
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
  if (!Buffer.isBuffer(req.body) || !secret || !verifyRazorpayWebhookSignature(req.body, signature, secret)) {
    return res.status(400).json({ error: "Invalid webhook signature" });
  }

  let event;
  try {
    event = JSON.parse(req.body.toString("utf8"));
  } catch (_) {
    return res.status(400).json({ error: "Invalid webhook payload" });
  }

  const type = event.event;
  let payment = event.payload?.payment?.entity;
  const orderId = payment?.order_id || event.payload?.order?.entity?.id;
  const paymentId = payment?.id || "(none)";
  try {
    if (type === "payment.captured" || type === "order.paid") {
      if (type === "order.paid" && (!payment || payment.status !== "captured")) {
        payment = orderId ? await fetchCapturedPayment(orderId) : null;
      }
      if (payment?.status === "captured") {
        const result = await markPaidIfCaptured(payment, { PaymentAttempt, User, durationMonths });
        if (!result.paid) console.error("Captured Razorpay webhook did not grant chat access", { orderId, paymentId, error: result.error });
      }
    } else if (type === "payment.failed" && orderId) {
      await PaymentAttempt.updateOne(
        { razorpayOrderId: orderId, status: { $ne: "paid" } },
        { $set: { status: "failed" } },
      );
    }
    console.info("Razorpay webhook processed", { event: type, orderId: orderId || "(none)", paymentId });
    return res.sendStatus(200);
  } catch (error) {
    console.error("Razorpay webhook processing failed", { event: type, orderId: orderId || "(none)", paymentId, error: error.message });
    return res.sendStatus(500);
  }
});

export default router;
