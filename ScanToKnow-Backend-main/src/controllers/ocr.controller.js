// src/controllers/ocr.controller.js

import { extractTextFromImage } from "../services/ocrSpace.service.js";
import { runOCRPipeline } from "../services/ocrPipeline.service.js";

export const scanOCR = async (req, res, next) => {
  try {
    if (!req.file || !req.file.buffer) {
      return res.status(400).json({ error: "Image file required" });
    }

    const text = await extractTextFromImage(req.file.buffer);
    const result = await runOCRPipeline(text);

    return res.json({
      status: "ok",
      data: result
    });
  } catch (err) {
    next(err);
  }
};

