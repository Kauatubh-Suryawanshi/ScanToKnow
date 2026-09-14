import express from "express";
import multer from "multer";
import { scanOCR } from "../controllers/ocr.controller.js";

const router = express.Router();

const ALLOWED_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
]);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 8 * 1024 * 1024,
    files: 1,
  },
  fileFilter: (req, file, cb) => {
    if (!ALLOWED_MIME_TYPES.has(file.mimetype)) {
      return cb(new multer.MulterError("LIMIT_UNEXPECTED_FILE", "image"));
    }
    cb(null, true);
  },
});

router.post("/scan", (req, res, next) => {
  upload.single("image")(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === "LIMIT_FILE_SIZE") {
        return res.status(413).json({ error: "Image must be 8 MB or smaller" });
      }
      return res.status(400).json({ error: "Unsupported or invalid image upload" });
    }
    if (err) return next(err);
    return scanOCR(req, res, next);
  });
});

export default router;
