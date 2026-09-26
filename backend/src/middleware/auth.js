import jwt from "jsonwebtoken";

export function signToken(payload, expiresIn = "30d") {
  return jwt.sign(payload, process.env.JWT_SECRET || "dev-secret", { expiresIn });
}

function readToken(req) {
  const header = req.headers.authorization || "";
  return header.startsWith("Bearer ") ? header.slice(7) : null;
}

export function auth(required = true) {
  return (req, res, next) => {
    const token = readToken(req);
    if (!token) {
      if (!required) return next();
      return res.status(401).json({ error: "Unauthorized" });
    }
    try {
      req.auth = jwt.verify(token, process.env.JWT_SECRET || "dev-secret");
      next();
    } catch {
      res.status(401).json({ error: "Invalid or expired token" });
    }
  };
}

export function requireAdmin(req, res, next) {
  if (!req.auth || req.auth.type !== "admin") {
    return res.status(403).json({ error: "Admin access required" });
  }
  next();
}

export function requireUser(req, res, next) {
  if (!req.auth || req.auth.type !== "user") {
    return res.status(403).json({ error: "User access required" });
  }
  next();
}

export const asyncHandler = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
