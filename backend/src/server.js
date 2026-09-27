import "dotenv/config";
import express from "express";
import cors from "cors";
import morgan from "morgan";
import { connectDB } from "./config/db.js";
import { autoSeed } from "./config/autoSeed.js";
import { initScheduler } from "./services/scheduler.js";
import authRoutes from "./routes/auth.js";
import caseRoutes from "./routes/cases.js";
import actRoutes from "./routes/acts.js";
import updateRoutes from "./routes/updates.js";
import postRoutes from "./routes/posts.js";
import { categories, notes, bookmarks, history, users, stats, reports } from "./routes/misc.js";
import { sanitizeLogOutput } from "./utils/security.js";

const app = express();

// Universal CORS configuration to support Admin panel on any domain + localhost + mobile
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization, x-api-key");
  if (req.method === "OPTIONS") {
    return res.sendStatus(204);
  }
  next();
});

app.use(cors({ origin: "*" }));
app.use(express.json({ limit: "5mb" }));
app.use(morgan("tiny"));

app.get("/", (_req, res) => res.json({ name: "Rishikesh Law Hub API", status: "ok" }));
app.get("/health", (_req, res) => res.json({ ok: true, status: "healthy", uptime: process.uptime(), timestamp: new Date().toISOString() }));
app.get("/privacy-policy", (_req, res) => res.redirect("https://rishikesh-law-hub-admin.onrender.com/privacy-policy"));
app.get("/terms-of-service", (_req, res) => res.redirect("https://rishikesh-law-hub-admin.onrender.com/terms-of-service"));
app.get("/delete-account", (_req, res) => res.redirect("https://rishikesh-law-hub-admin.onrender.com/delete-account"));

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
app.use("/api/reports", reports);

app.use((_req, res) => res.status(404).json({ error: "Route not found" }));
app.use((err, _req, res, _next) => {
  console.error(sanitizeLogOutput(err?.stack || err?.message || err));
  res.status(err.status || 500).json({ error: err.message || "Server error" });
});

const port = process.env.PORT || 4000;
connectDB()
  .then(async () => {
    await autoSeed();
    initScheduler();
    app.listen(port, () => console.log(`API listening on :${port}`));
  })
  .catch((e) => {
    console.error("Failed to start:", e.message);
    process.exit(1);
  });
