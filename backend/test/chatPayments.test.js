import test from "node:test";
import assert from "node:assert/strict";
import crypto from "node:crypto";
import {
  markPaidIfCaptured,
  findOwnedPaymentAttempt,
  validateCapturedPayment,
  verifyRazorpayPaymentSignature,
  verifyRazorpayWebhookSignature,
} from "../src/services/chatPayments.js";

const secret = "test-secret";

function paymentSignature(orderId, paymentId) {
  return crypto.createHmac("sha256", secret).update(`${orderId}|${paymentId}`).digest("hex");
}

test("validates payment signature and rejects a modified signature", () => {
  const signature = paymentSignature("order_a", "pay_a");
  assert.equal(verifyRazorpayPaymentSignature("order_a", "pay_a", signature, secret), true);
  assert.equal(verifyRazorpayPaymentSignature("order_a", "pay_a", `${signature.slice(0, -2)}00`, secret), false);
});

test("validates webhook HMAC against the exact raw bytes", () => {
  const body = Buffer.from('{"event":"payment.captured"}');
  const signature = crypto.createHmac("sha256", secret).update(body).digest("hex");
  assert.equal(verifyRazorpayWebhookSignature(body, signature, secret), true);
  assert.equal(verifyRazorpayWebhookSignature(Buffer.from(`${body} `), signature, secret), false);
});

test("authorized payments and amount mismatches cannot grant access", () => {
  const attempt = { razorpayOrderId: "order_a", amount: 1100, currency: "INR" };
  const authorized = { id: "pay_a", order_id: "order_a", amount: 1100, currency: "INR", status: "authorized", captured: false };
  const captured = { ...authorized, status: "captured", captured: true };
  assert.equal(validateCapturedPayment(authorized, attempt), "Payment is not captured");
  assert.equal(validateCapturedPayment({ ...captured, amount: 1000 }, attempt), "Payment amount or currency does not match");
  assert.equal(validateCapturedPayment(captured, attempt), null);
});

test("an order cannot be found through another user's account", async () => {
  const findOne = async ({ razorpayOrderId, userId }) =>
    razorpayOrderId === "order_a" && userId === "owner_a" ? { userId: "owner_a" } : null;
  assert.equal(await findOwnedPaymentAttempt({ findOne }, "order_a", "owner_a") !== null, true);
  assert.equal(await findOwnedPaymentAttempt({ findOne }, "order_a", "attacker_b"), null);
});

test("late capture after cancellation and duplicate callbacks extend access exactly once", async () => {
  const attempt = { _id: "attempt_a", userId: "user_a", razorpayOrderId: "order_a", amount: 1100, currency: "INR", status: "cancelled" };
  const user = { _id: "user_a", chatPaidUntil: null, async save() {} };
  let extensions = 0;
  const duplicateIds = [];
  const query = (value) => ({ session: async () => value });
  const PaymentAttempt = {
    findOne: (filter) => {
      if (filter.razorpayPaymentId) return query(null);
      return query(filter.razorpayOrderId === attempt.razorpayOrderId ? attempt : null);
    },
    findOneAndUpdate: async (_filter, update) => {
      if (attempt.status === "paid") return null;
      Object.assign(attempt, update.$set);
      return attempt;
    },
    findById: () => query(attempt),
    updateOne: async (_filter, update) => duplicateIds.push(update.$addToSet.duplicatePaymentIds),
  };
  const User = {
    findById: () => query({
      ...user,
      async save() {
        extensions += 1;
        user.chatPaidUntil = this.chatPaidUntil;
      },
    }),
  };
  const startSession = async () => ({
    withTransaction: async (callback) => callback(),
    endSession: async () => {},
  });
  const captured = { id: "pay_a", order_id: "order_a", amount: 1100, currency: "INR", status: "captured", captured: true };
  const options = { PaymentAttempt, User, durationMonths: 3, startSession, logger: { error() {} } };

  assert.equal((await markPaidIfCaptured(captured, options)).paid, true);
  const expiryAfterFirst = user.chatPaidUntil;
  assert.equal((await markPaidIfCaptured(captured, options)).paid, true);
  const duplicateResult = await markPaidIfCaptured({ ...captured, id: "pay_duplicate" }, options);
  assert.equal(duplicateResult.duplicate, true);
  assert.equal(extensions, 1);
  assert.deepEqual(duplicateIds, ["pay_duplicate"]);
  assert.equal(user.chatPaidUntil, expiryAfterFirst);
  user.chatPaidUntil = new Date(Date.now() - 1000);
  const expiredEntitlement = await markPaidIfCaptured(captured, options);
  assert.equal(expiredEntitlement.paymentCaptured, true);
  assert.equal(expiredEntitlement.paid, false);
  assert.equal(extensions, 1);
});
