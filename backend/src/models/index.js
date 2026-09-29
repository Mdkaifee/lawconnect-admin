import mongoose from "mongoose";

const { Schema, model } = mongoose;

/* ---------------- 1. Admin (owner / editor) ---------------- */
const adminSchema = new Schema(
  {
    username: { type: String, required: true, unique: true, trim: true },
    passwordHash: { type: String, required: true },
    name: { type: String, default: "Rishikesh Yadav" },
    role: { type: String, enum: ["owner", "editor"], default: "owner" },
  },
  { timestamps: true },
);

/* ---------------- 2. App users (Flutter app) ---------------- */
const userSchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    photoUrl: String,
    photoData: String,
    photoMimeType: String,
    headline: { type: String, default: "" },
    college: { type: String, default: "" },
    blocked: { type: Boolean, default: false },
    lastActiveAt: { type: Date, default: Date.now, index: true },
    following: [{ type: Schema.Types.ObjectId, ref: "User" }],
    followRequests: [{ type: Schema.Types.ObjectId, ref: "User" }],
    fcmTokens: [{ type: String }],
    deletionRequested: { type: Boolean, default: false, index: true },
    deletionRequestedAt: { type: Date },
    deletionDueAt: { type: Date, index: true },
    deletionReason: String,
    chatPaidUntil: { type: Date, default: null, index: true },
    chatPaymentOrders: [{
      orderId: { type: String, required: true },
      amountPaise: { type: Number, required: true },
      status: { type: String, enum: ["created", "paid", "cancelled"], default: "created" },
      paymentId: { type: String, default: "" },
    }],
  },
  { timestamps: true },
);

const paymentAttemptSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    razorpayOrderId: { type: String, required: true, unique: true },
    razorpayPaymentId: { type: String, default: undefined },
    amount: { type: Number, required: true },
    currency: { type: String, required: true, default: "INR" },
    status: { type: String, enum: ["created", "paid", "failed", "cancelled"], default: "created", index: true },
    accessGrantedAt: { type: Date, default: null },
    duplicatePaymentIds: [{ type: String }],
  },
  { timestamps: true },
);
paymentAttemptSchema.index({ razorpayPaymentId: 1 }, { unique: true, sparse: true });
paymentAttemptSchema.index({ userId: 1, status: 1, createdAt: -1 });

/* ---------------- 3. Categories (Constitution, Criminal...) -------- */
const categorySchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    slug: { type: String, required: true, unique: true, lowercase: true, trim: true },
    icon: { type: String, default: "scale" },
    color: { type: String, default: "#1e3a5f" },
    order: { type: Number, default: 0 },
  },
  { timestamps: true },
);

/* ---------------- 4. Cases / Judgments (Curated) ---------------- */
const caseSchema = new Schema(
  {
    title: { type: String, required: true, trim: true },
    citation: { type: String, trim: true },
    year: { type: Number, index: true },
    court: { type: String, default: "Supreme Court of India" },
    courtType: { type: String, enum: ["Supreme Court", "High Court", "District Court", "Tribunal", "Other"], default: "Supreme Court", index: true },
    bench: String,
    petitioners: String,
    respondents: String,
    dateOfJudgment: Date,
    tags: [{ type: String, trim: true }],
    categories: [{ type: String, trim: true }],
    summary: String,
    simpleExplanation: String,
    fullText: String,
    judgmentPdfUrl: String,
    providerId: { type: String, index: true }, // Optional link to Indian Kanoon tid
    isFeatured: { type: Boolean, default: false, index: true },
    published: { type: Boolean, default: true, index: true },
  },
  { timestamps: true },
);
caseSchema.index({ title: "text", citation: "text", summary: "text", tags: "text" });

/* ---------------- 5. Acts & Sections (India Code Reference) ---------------- */
const sectionSchema = new Schema(
  {
    number: { type: String, required: true, trim: true },
    title: { type: String, trim: true },
    chapter: { type: String, trim: true },
    text: String,
    explanation: String,
    lastVerifiedDate: Date,
  },
  { _id: true },
);

const actSchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    shortName: { type: String, trim: true, index: true },
    actNumber: { type: String, trim: true },
    year: { type: Number, index: true },
    type: { type: String, enum: ["Central", "State"], default: "Central", index: true },
    jurisdiction: { type: String, default: "India" },
    description: String,
    language: { type: String, default: "English" },
    sourceUrl: String,
    lastVerifiedDate: Date,
    versionInfo: String,
    commencementDate: Date,
    repealStatus: { type: String, enum: ["active", "repealed", "amended"], default: "active" },
    chapters: [{ number: String, title: String }],
    sections: [sectionSchema],
    published: { type: Boolean, default: true, index: true },
  },
  { timestamps: true },
);
actSchema.index({ name: "text", shortName: "text", description: "text" });

/* ---------------- 6. Legal Updates ---------------- */
const updateSchema = new Schema(
  {
    title: { type: String, required: true, trim: true },
    summary: String,
    body: String,
    category: {
      type: String,
      enum: ["Judgments", "Government Notifications", "Amendments", "New Rules", "General"],
      default: "Judgments",
      index: true,
    },
    source: { type: String, default: "Official Gazette / Supreme Court" },
    sourceUrl: String,
    court: { type: String, enum: ["Supreme Court", "High Court", "Other"], default: "Other", index: true },
    badge: String,
    imageUrl: String,
    publishedAt: { type: Date, default: Date.now, index: true },
    verifiedAt: Date,
    verificationStatus: { type: String, enum: ["verified", "pending"], default: "verified" },
    published: { type: Boolean, default: true, index: true },
  },
  { timestamps: true },
);

/* ---------------- 7. Law Posts & Comments ---------------- */
const postSchema = new Schema(
  {
    authorType: { type: String, enum: ["admin", "user"], default: "admin" },
    authorId: { type: Schema.Types.ObjectId, refPath: "authorModel", index: true },
    authorModel: { type: String, enum: ["Admin", "User"], default: "Admin" },
    authorName: { type: String, default: "Rishikesh Yadav" },
    authorPhotoUrl: String,
    category: { type: String, default: "General Law" },
    title: { type: String, default: "", trim: true },
    content: { type: String, default: "" },
    imageData: { type: String, default: "" },
    imageMimeType: { type: String, default: "" },
    tags: [{ type: String, trim: true }],
    likedBy: [{ type: Schema.Types.ObjectId, ref: "User" }],
    likes: { type: Number, default: 0 },
    commentsCount: { type: Number, default: 0 },
    status: { type: String, enum: ["published", "hidden", "pending"], default: "published", index: true },
  },
  { timestamps: true },
);

const commentSchema = new Schema(
  {
    postId: { type: Schema.Types.ObjectId, ref: "Post", required: true, index: true },
    authorType: { type: String, enum: ["admin", "user"], default: "user" },
    authorId: { type: Schema.Types.ObjectId, refPath: "authorModel", required: true },
    authorModel: { type: String, enum: ["Admin", "User"], default: "User" },
    authorName: { type: String, required: true },
    authorPhotoUrl: String,
    content: { type: String, required: true, trim: true },
    status: { type: String, enum: ["published", "hidden"], default: "published" },
  },
  { timestamps: true },
);

/* ---------------- 8. Reports & Moderation ---------------- */
const reportSchema = new Schema(
  {
    targetType: { type: String, enum: ["post", "comment"], required: true },
    targetId: { type: Schema.Types.ObjectId, required: true, index: true },
    reporterId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    reason: { type: String, required: true, trim: true },
    status: { type: String, enum: ["pending", "resolved", "dismissed"], default: "pending", index: true },
  },
  { timestamps: true },
);

/* ---------------- 9. Notes & Bookmarks & History ---------------- */
const noteSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    refType: { type: String, enum: ["case", "section", "post", "general"], default: "general" },
    refId: String,
    refTitle: String,
    title: { type: String, required: true, trim: true },
    content: { type: String, required: true },
  },
  { timestamps: true },
);

const bookmarkSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    refType: { type: String, enum: ["case", "section", "post", "note"], required: true },
    refId: { type: String, required: true },
    title: { type: String, required: true },
    subtitle: String,
  },
  { timestamps: true },
);
bookmarkSchema.index({ userId: 1, refType: 1, refId: 1 }, { unique: true });

const historySchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    refType: { type: String, default: "case" },
    refId: { type: String, required: true },
    title: { type: String, required: true },
    viewedAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

/* ---------------- 10. Deletion Requests (Google Play / User Data) --- */
const deletionRequestSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", index: true },
    email: { type: String, required: true, lowercase: true, trim: true },
    reason: { type: String, trim: true },
    source: { type: String, enum: ["in_app", "web_portal"], default: "in_app" },
    status: { type: String, enum: ["pending", "completed", "cancelled"], default: "pending", index: true },
    requestedAt: { type: Date, default: Date.now },
    scheduledDeletionAt: { type: Date, required: true },
    completedAt: Date,
  },
  { timestamps: true },
);

/* ---------------- 11. In-App Notifications ---------------- */
const notificationSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", index: true },
    title: { type: String, required: true, trim: true },
    body: { type: String, required: true, trim: true },
    type: { type: String, enum: ["judgment", "act", "update", "community", "system", "general"], default: "general" },
    refId: String,
    refType: { type: String, enum: ["case", "act", "update", "post", "user", "message", "general"], default: "general" },
    readBy: [{ type: Schema.Types.ObjectId, ref: "User" }],
    isRead: { type: Boolean, default: false },
  },
  { timestamps: true },
);

/* ---------------- 12. Conversations & Messages ---------------- */
const conversationSchema = new Schema(
  {
    participants: [{ type: Schema.Types.ObjectId, ref: "User", index: true }],
    status: { type: String, enum: ["requested", "active", "ignored"], default: "requested", index: true },
    requestedBy: { type: Schema.Types.ObjectId, ref: "User" },
    lastMessage: { type: String, default: "" },
    lastMessageAt: { type: Date },
    lastSenderId: { type: Schema.Types.ObjectId, ref: "User" },
    readBy: [{ type: Schema.Types.ObjectId, ref: "User" }],
  },
  { timestamps: true },
);
conversationSchema.index({ participants: 1, updatedAt: -1 });

const messageSchema = new Schema(
  {
    conversationId: { type: Schema.Types.ObjectId, ref: "Conversation", required: true, index: true },
    senderId: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    receiverId: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    body: { type: String, required: true, trim: true },
    kind: { type: String, enum: ["message", "request"], default: "message" },
    readAt: Date,
  },
  { timestamps: true },
);

const aiChatMessageSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true, index: true },
    role: { type: String, enum: ["user", "assistant"], required: true },
    content: { type: String, required: true, trim: true, maxlength: 8000 },
  },
  { timestamps: true },
);
aiChatMessageSchema.index({ userId: 1, createdAt: -1 });

export const Admin = model("Admin", adminSchema);
export const User = model("User", userSchema);
export const PaymentAttempt = model("PaymentAttempt", paymentAttemptSchema);
export const Category = model("Category", categorySchema);
export const Case = model("Case", caseSchema);
export const Act = model("Act", actSchema);
export const LegalUpdate = model("LegalUpdate", updateSchema);
export const Post = model("Post", postSchema);
export const Comment = model("Comment", commentSchema);
export const Report = model("Report", reportSchema);
export const Note = model("Note", noteSchema);
export const Bookmark = model("Bookmark", bookmarkSchema);
export const History = model("History", historySchema);
export const DeletionRequest = model("DeletionRequest", deletionRequestSchema);
export const AppNotification = model("AppNotification", notificationSchema);
export const Conversation = model("Conversation", conversationSchema);
export const Message = model("Message", messageSchema);
export const AiChatMessage = model("AiChatMessage", aiChatMessageSchema);
