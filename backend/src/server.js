import "dotenv/config";
import express from "express";
import cors from "cors";
import morgan from "morgan";
import { connectDB } from "./config/db.js";
import authRoutes from "./routes/auth.js";
import caseRoutes from "./routes/cases.js";
import actRoutes from "./routes/acts.js";
import updateRoutes from "./routes/updates.js";
import postRoutes from "./routes/posts.js";
import { categories, notes, bookmarks, history, users, stats } from "./routes/misc.js";

const app = express();

const corsOptions = {
  origin: (origin, callback) => {
    // Allow all origins (browsers, mobile apps, dev environments)
    if (!origin) return callback(null, true);
    const raw = process.env.CORS_ORIGIN;
    if (!raw || raw.trim() === "*" || raw.trim() === "") {
      return callback(null, true);
    }
    const allowed = raw.split(",").map((s) => s.trim());
    if (allowed.includes("*") || allowed.includes(origin)) {
      return callback(null, true);
    }
    return callback(null, true);
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With", "Accept"],
};

app.use(cors(corsOptions));
app.options("*", cors(corsOptions));

app.use(express.json({ limit: "2mb" }));
app.use(morgan("tiny"));

app.get("/", (_req, res) => res.json({ name: "Rishikesh Law Hub API", status: "ok" }));
app.get("/health", (_req, res) => res.json({ ok: true, uptime: process.uptime() }));

app.use("/api/auth", authRoutes);
app.use("/api/cases", caseRoutes);
app.use("/api/acts", actRoutes);
app.use("/api/updates", updateRoutes);
app.use("/api/posts", postRoutes);
app.use("/api/categories", categories);
app.use("/api/notes", notes);
app.use("/api/bookmarks", bookmarks);
app.use("/api/history", history);
app.use("/api/users", users);
app.use("/api/stats", stats);

app.use((_req, res) => res.status(404).json({ error: "Route not found" }));
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || "Server error" });
});

const port = process.env.PORT || 4000;
connectDB()
  .then(() => app.listen(port, () => console.log(`API listening on :${port}`)))
  .catch((e) => {
    console.error("Failed to start:", e.message);
    process.exit(1);
  });
