import mongoose from "mongoose";

const { Schema, model } = mongoose;

/* ---------------- Admin (owner / lawyer) ---------------- */
const adminSchema = new Schema(
  {
    username: { type: String, required: true, unique: true, trim: true },
    passwordHash: { type: String, required: true },
    name: { type: String, default: "Admin" },
    role: { type: String, enum: ["owner", "editor"], default: "owner" },
  },
  { timestamps: true },
);

/* ---------------- App users (Flutter app) ---------------- */
const userSchema = new Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    photoUrl: String,
    headline: String,
    college: String,
    blocked: { type: Boolean, default: false },
  },
  { timestamps: true },
);

/* ---------------- Categories (Constitution, Criminal...) -------- */
const categorySchema = new Schema(
  {
    name: { type: String, required: true },
    slug: { type: String, required: true, unique: true, lowercase: true },
    icon: { type: String, default: "scale" },
    color: { type: String, default: "#1e3a5f" },
    order: { type: Number, default: 0 },
  },
  { timestamps: true },
);

/* ---------------- Cases / Judgments ---------------- */
const caseSchema = new Schema(
  {
    title: { type: String, required: true },
    citation: String,
    year: Number,
    court: { type: String, default: "Supreme Court of India" },
    courtType: { type: String, enum: ["Supreme Court", "High Court", "Other"], default: "Supreme Court" },
    bench: String,
    petitioners: String,
    respondents: String,
    dateOfJudgment: Date,
    tags: [String],
    categories: [String],
    summary: String,
    simpleExplanation: String,
    fullText: String,
    judgmentPdfUrl: String,
    published: { type: Boolean, default: true },
  },
  { timestamps: true },
);
caseSchema.index({ title: "text", citation: "text", summary: "text", tags: "text" });

/* ---------------- Acts & Sections ---------------- */
const sectionSchema = new Schema(
  {
    number: { type: String, required: true },
    title: String,
    text: String,
    explanation: String,
  },
  { _id: true },
);

const actSchema = new Schema(
  {
    name: { type: String, required: true },
    shortName: String,
    year: Number,
    type: { type: String, enum: ["Central", "State"], default: "Central" },
    description: String,
    icon: { type: String, default: "book" },
    color: { type: String, default: "#1e3a5f" },
    sections: [sectionSchema],
    published: { type: Boolean, default: true },
  },
  { timestamps: true },
);
actSchema.index({ name: "text", shortName: "text", description: "text" });

/* ---------------- Legal updates ---------------- */
const updateSchema = new Schema(
  {
    title: { type: String, required: true },
    body: String,
    source: String,
    court: { type: String, enum: ["Supreme Court", "High Court", "Other"], default: "Other" },
    badge: String,
    url: String,
    imageUrl: String,
    publishedAt: { type: Date, default: Date.now },
    published: { type: Boolean, default: true },
  },
  { timestamps: true },
);

/* ---------------- Law posts ---------------- */
const postSchema = new Schema(
  {
    authorType: { type: String, enum: ["admin", "user"], default: "admin" },
    authorId: { type: Schema.Types.ObjectId, refPath: "authorModel" },
    authorModel: { type: String, enum: ["Admin", "User"], default: "Admin" },
    authorName: { type: String, default: "Rishikesh Yadav" },
    authorPhotoUrl: String,
    category: String,
    title: { type: String, required: true },
    content: { type: String, required: true },
    tags: [String],
    likes: { type: Number, default: 0 },
    commentsCount: { type: Number, default: 0 },
    status: { type: String, enum: ["published", "hidden", "pending"], default: "published" },
  },
  { timestamps: true },
);

/* ---------------- Notes & bookmarks (per app user) -------- */
const noteSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    refType: { type: String, enum: ["case", "section", "post", "free"], default: "free" },
    refId: String,
    refTitle: String,
    title: String,
    body: String,
  },
  { timestamps: true },
);

const bookmarkSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    refType: { type: String, enum: ["case", "section", "post", "note"], required: true },
    refId: { type: String, required: true },
    refTitle: String,
    meta: String,
  },
  { timestamps: true },
);
bookmarkSchema.index({ userId: 1, refType: 1, refId: 1 }, { unique: true });

const historySchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
    refType: String,
    refId: String,
    refTitle: String,
    viewedAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

export const Admin = model("Admin", adminSchema);
export const User = model("User", userSchema);
export const Category = model("Category", categorySchema);
export const Case = model("Case", caseSchema);
export const Act = model("Act", actSchema);
export const LegalUpdate = model("LegalUpdate", updateSchema);
export const Post = model("Post", postSchema);
export const Note = model("Note", noteSchema);
export const Bookmark = model("Bookmark", bookmarkSchema);
export const History = model("History", historySchema);
