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
    // Allow all origins (web browsers, mobile apps, localhost, Render)
    callback(null, true);
  },
  credentials: true,
  methods: ["GET", "HEAD", "PUT", "PATCH", "POST", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With", "Accept"],
  optionsSuccessStatus: 204,
};

app.use(cors(corsOptions));
app.options("*", cors(corsOptions));

// Explicit header safety middleware for all incoming requests
app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (origin) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Access-Control-Allow-Credentials", "true");
  } else {
    res.setHeader("Access-Control-Allow-Origin", "*");
  }
  res.setHeader("Access-Control-Allow-Methods", "GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type,Authorization,X-Requested-With,Accept");

  if (req.method === "OPTIONS") {
    return res.sendStatus(204);
  }
  next();
});

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
app.use((err, req, res, _next) => {
  const origin = req.headers.origin;
  if (origin) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Access-Control-Allow-Credentials", "true");
  }
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
