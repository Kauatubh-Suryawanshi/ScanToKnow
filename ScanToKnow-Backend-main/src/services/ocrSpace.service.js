/* =========================================================
   ocrSpace.service.js — v3.0

   FIXES:
   1. Retry on BOTH timeout AND ECONNRESET (not just timeout)
   2. Increased timeout to 45s (OCR.space can be slow)
   3. MAX_RETRIES increased to 3
   4. Exponential back-off: 1s → 2.5s → 5s between retries
   5. Smarter image type detection from buffer magic bytes
   6. Added explicit keep-alive header to avoid mid-stream reset
   ========================================================= */

import axios from "axios";

const OCR_API_URL = "https://api.ocr.space/parse/image";
const TIMEOUT_MS  = 45_000; // 45 s — OCR.space free tier can be sluggish
const MAX_RETRIES = 3;

/* Detect mime type from buffer magic bytes */
function detectMimeType(buffer) {
  if (buffer[0] === 0xff && buffer[1] === 0xd8) return { mime: "image/jpeg", ext: "jpg" };
  if (buffer[0] === 0x89 && buffer[1] === 0x50) return { mime: "image/png",  ext: "png" };
  if (buffer[0] === 0x47 && buffer[1] === 0x49) return { mime: "image/gif",  ext: "gif" };
  if (buffer[0] === 0x52 && buffer[1] === 0x49) return { mime: "image/webp", ext: "webp" };
  // Default to jpeg (most phone camera output)
  return { mime: "image/jpeg", ext: "jpg" };
}

/* Exponential back-off: attempt 1 → 1000ms, 2 → 2500ms, 3 → 5000ms */
function backoffMs(attempt) {
  return [0, 1000, 2500, 5000][Math.min(attempt, 3)];
}

/* Is this error worth retrying? */
function isRetryable(err) {
  if (err.code === "ECONNABORTED") return true;   // axios timeout
  if (err.code === "ECONNRESET")   return true;   // server closed connection
  if (err.code === "ECONNREFUSED") return true;   // transient refusal
  if (err.code === "ETIMEDOUT")    return true;   // network timeout
  if (err.message?.toLowerCase().includes("timeout")) return true;
  if (err.response?.status >= 500) return true;   // OCR.space 5xx
  return false;
}

export async function extractTextFromImage(imageBuffer) {
  const apiKey = process.env.OCR_SPACE_API_KEY;
  if (!apiKey) throw new Error("OCR_SPACE_API_KEY missing in env");

  const { mime, ext } = detectMimeType(imageBuffer);
  const base64  = imageBuffer.toString("base64");
  const dataURI = `data:${mime};base64,${base64}`;

  const payload = new URLSearchParams();
  payload.append("base64Image",       dataURI);
  payload.append("language",          "eng");
  payload.append("OCREngine",         "2");         // Engine 2 = better accuracy
  payload.append("scale",             "true");
  payload.append("isTable",           "false");
  payload.append("isOverlayRequired", "false");
  payload.append("detectOrientation", "true");
  payload.append("filetype",          ext);

  let lastError;

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      const response = await axios.post(OCR_API_URL, payload, {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "apikey":        apiKey,
          "Connection":    "keep-alive",            // helps prevent ECONNRESET
        },
        timeout: TIMEOUT_MS,
        maxContentLength: Infinity,
        maxBodyLength:    Infinity,
      });

      const data = response.data;

      if (data.IsErroredOnProcessing) {
        const msg = Array.isArray(data.ErrorMessage)
          ? data.ErrorMessage.join(", ")
          : (data.ErrorMessage ?? "Unknown OCR error");
        throw new Error(`OCR.Space error: ${msg}`);
      }

      const text = data.ParsedResults?.[0]?.ParsedText?.trim() ?? "";
      return text;

    } catch (err) {
      lastError = err;

      const shouldRetry = isRetryable(err) && attempt < MAX_RETRIES;
      if (!shouldRetry) throw err;

      const delay = backoffMs(attempt);
      console.warn(
        `[OCR] Attempt ${attempt} failed (${err.code ?? err.message}). ` +
        `Retrying in ${delay}ms…`
      );
      await new Promise(r => setTimeout(r, delay));
    }
  }

  throw lastError;
}