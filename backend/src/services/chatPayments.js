import crypto from "node:crypto";
import mongoose from "mongoose";

export function verifyRazorpayPaymentSignature(orderId, paymentId, signature, secret) {
  if (![orderId, paymentId, signature, secret].every((value) => typeof value === "string" && value.length > 0)) return false;
  const expected = crypto.createHmac("sha256", secret).update(`${orderId}|${paymentId}`).digest();
  let supplied;
  try {
    supplied = Buffer.from(signature, "hex");
  } catch {
    return false;
  }
  return supplied.length === expected.length && crypto.timingSafeEqual(supplied, expected);
}

export function verifyRazorpayWebhookSignature(rawBody, signature, secret) {
  if (!Buffer.isBuffer(rawBody) || typeof signature !== "string" || !signature || !secret) return false;
  const expected = crypto.createHmac("sha256", secret).update(rawBody).digest();
  let supplied;
  try {
    supplied = Buffer.from(signature, "hex");
  } catch {
    return false;
  }
  return supplied.length === expected.length && crypto.timingSafeEqual(supplied, expected);
}

export function validateCapturedPayment(payment, attempt) {
  if (!payment || payment.status !== "captured") return "Payment is not captured";
  if (payment.order_id !== attempt.razorpayOrderId) return "Payment order does not match";
  if (Number(payment.amount) !== attempt.amount || payment.currency !== attempt.currency) return "Payment amount or currency does not match";
  if (!payment.id) return "Payment ID is missing";
  return null;
}

export function findOwnedPaymentAttempt(PaymentAttempt, orderId, userId) {
  return PaymentAttempt.findOne({ razorpayOrderId: orderId, userId });
}

export function addCalendarMonths(date, months) {
  const result = new Date(date);
  const originalDay = result.getUTCDate();
  result.setUTCDate(1);
  result.setUTCMonth(result.getUTCMonth() + months);
  const lastDay = new Date(Date.UTC(result.getUTCFullYear(), result.getUTCMonth() + 1, 0)).getUTCDate();
  result.setUTCDate(Math.min(originalDay, lastDay));
  return result;
}

export async function markPaidIfCaptured(payment, {
  PaymentAttempt,
  User,
  durationMonths,
  startSession = () => mongoose.startSession(),
  logger = console,
}) {
  const session = await startSession();
  let result = { paid: false, error: "Payment attempt not found" };
  try {
    await session.withTransaction(async () => {
      const attempt = await PaymentAttempt.findOne({ razorpayOrderId: payment?.order_id }).session(session);
      if (!attempt) {
        result = { paid: false, error: "Payment attempt not found" };
        return;
      }
      const mismatch = validateCapturedPayment(payment, attempt);
      if (mismatch) {
        result = { paid: false, error: mismatch };
        return;
      }

      if (attempt.status === "paid") {
        if (attempt.razorpayPaymentId !== payment.id) {
          await PaymentAttempt.updateOne(
            { _id: attempt._id },
            { $addToSet: { duplicatePaymentIds: payment.id } },
            { session },
          );
          logger.error("Duplicate captured Razorpay payment flagged for refund review", {
            orderId: attempt.razorpayOrderId,
            paymentId: payment.id,
          });
        }
        const currentUser = await User.findById(attempt.userId).session(session);
        const accessActive = Boolean(currentUser?.chatPaidUntil && currentUser.chatPaidUntil > new Date());
        result = {
          paid: accessActive,
          paymentCaptured: true,
          chatPaidUntil: currentUser?.chatPaidUntil || null,
          duplicate: attempt.razorpayPaymentId !== payment.id,
        };
        return;
      }

      const paymentOwner = await PaymentAttempt.findOne({ razorpayPaymentId: payment.id }).session(session);
      if (paymentOwner && paymentOwner.razorpayOrderId !== attempt.razorpayOrderId) {
        result = { paid: false, error: "Payment ID is already linked to a different order" };
        return;
      }

      const now = new Date();
      const updated = await PaymentAttempt.findOneAndUpdate(
        { _id: attempt._id, status: { $ne: "paid" } },
        { $set: { status: "paid", razorpayPaymentId: payment.id, accessGrantedAt: now } },
        { new: true, session },
      );
      if (!updated) {
        const latest = await PaymentAttempt.findById(attempt._id).session(session);
        const currentUser = await User.findById(attempt.userId).session(session);
        const accessActive = Boolean(currentUser?.chatPaidUntil && currentUser.chatPaidUntil > new Date());
        result = {
          paid: latest?.status === "paid" && accessActive,
          paymentCaptured: latest?.status === "paid",
          chatPaidUntil: currentUser?.chatPaidUntil || null,
        };
        return;
      }

      const user = await User.findById(attempt.userId).session(session);
      if (!user) throw new Error("Payment owner account not found");
      const startsAt = user.chatPaidUntil && user.chatPaidUntil > now ? user.chatPaidUntil : now;
      user.chatPaidUntil = addCalendarMonths(startsAt, durationMonths);
      await user.save({ session });
      result = { paid: true, paymentCaptured: true, chatPaidUntil: user.chatPaidUntil, duplicate: false };
    });
    return result;
  } finally {
    await session.endSession();
  }
}
