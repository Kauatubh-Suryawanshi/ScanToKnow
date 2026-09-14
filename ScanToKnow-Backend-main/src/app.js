import express from "express";
import cors from "cors";
import morgan from "morgan";
import helmet from "helmet";
import mongoose from "mongoose";
import dotenv from "dotenv";

import categoryRoutes from "./routes/category.routes.js";
import productRoutes from "./routes/product.routes.js";
import variantRoutes from "./routes/variant.routes.js";
import scanRoutes from "./routes/scan.routes.js";
import searchRoutes from "./routes/search.routes.js";
import ocrRoutes from "./routes/ocr.routes.js";

dotenv.config();

const app = express();

app.disable("x-powered-by");
// Normalize accidental zero-width/control characters in request URLs.
app.use((req, res, next) => {
  try {
    req.url = decodeURIComponent(req.url).replace(/[\u200B-\u200D\uFEFF\r\n\t]/g, "");
  } catch (_) {
    // Let Express handle malformed URLs normally.
  }
  next();
});

app.use(helmet());
if (process.env.NODE_ENV !== "test") app.use(morgan("combined"));
app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ extended: true, limit: "1mb" }));

const allowedOrigins = (process.env.CORS_ORIGINS || "")
  .split(",")
  .map((o) => o.trim())
  .filter(Boolean);

app.use(
  cors({
    origin(origin, callback) {
      if (!origin) return callback(null, true);
      if (allowedOrigins.length === 0 && process.env.NODE_ENV !== "production") {
        return callback(null, true);
      }
      if (allowedOrigins.includes(origin)) return callback(null, true);
      return callback(new Error("CORS: Origin not allowed"), false);
    },
  }),
);

function createRateLimiter({ windowMs, limit, message }) {
  const buckets = new Map();
  return (req, res, next) => {
    const key = req.ip || req.socket.remoteAddress || "unknown";
    const now = Date.now();
    const bucket = buckets.get(key);
    if (!bucket || now - bucket.startedAt >= windowMs) {
      buckets.set(key, { startedAt: now, count: 1 });
      if (buckets.size > 5000) {
        for (const [storedKey, stored] of buckets) {
          if (now - stored.startedAt >= windowMs) buckets.delete(storedKey);
        }
      }
      return next();
    }
    bucket.count += 1;
    if (bucket.count > limit) {
      res.set("Retry-After", Math.ceil((windowMs - (now - bucket.startedAt)) / 1000));
      return res.status(429).json({ error: message });
    }
    next();
  };
}

const apiLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  limit: 300,
  message: "Too many requests. Please try again later.",
});

const ocrLimiter = createRateLimiter({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  message: "OCR rate limit exceeded. Please try again later.",
});

app.use("/v1", apiLimiter);

app.get("/health", (req, res) => {
  res.json({ status: "ok", service: "scantoknow-backend" });
});

app.get("/ready", (req, res) => {
  const connected = mongoose.connection.readyState === 1;
  res.status(connected ? 200 : 503).json({
    ready: connected,
    dependencies: { mongodb: connected ? "up" : "down" },
  });
});

app.use("/v1/categories", categoryRoutes);
app.use("/v1/products", productRoutes);
app.use("/v1/variants", variantRoutes);
app.use("/v1/scan", scanRoutes);
app.use("/v1/search", searchRoutes);
app.use("/v1/ocr", ocrLimiter, ocrRoutes);

app.use("/v1/*", (req, res) => {
  res.status(404).json({ error: "Not found", path: req.originalUrl });
});

app.use((err, req, res, next) => {
  const status = Number.isInteger(err.status) ? err.status : 500;
  const payload = { error: err.message || "Internal Server Error" };

  if (process.env.NODE_ENV !== "production" && err.stack) {
    payload.stack = err.stack;
  }

  if (status >= 500) console.error("Unhandled error:", err);
  res.status(status).json(payload);
});

export default app;
