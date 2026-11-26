const express = require("express");

const mongoose = require("mongoose");
const helmet = require("helmet");
const { rateLimit } = require("express-rate-limit");
const todoRoutes = require("./modules/todos/todo.routes");

const app = express();
// Trust Render's single proxy hop so IP-based limits use the forwarded client IP.
app.set("trust proxy", 1);
app.use(helmet());
app.get("/health", async (_req, res) => {
  try {
    if (mongoose.connection.readyState !== 1 || !mongoose.connection.db) {
      return res.status(503).json({ status: "unavailable" });
    }

    await mongoose.connection.db.admin().ping();
    return res.status(200).json({ status: "ok" });
  } catch {
    return res.status(503).json({ status: "unavailable" });
  }
});

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests. Please try again later." },
});

app.use("/api", apiLimiter);

app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.header("Access-Control-Allow-Headers", "Content-Type, x-device-id");
  if (req.method === "OPTIONS") {
    return res.sendStatus(204);
  }
  next();
});

app.use(express.json());
app.use("/api/todos", todoRoutes);

module.exports = app;
