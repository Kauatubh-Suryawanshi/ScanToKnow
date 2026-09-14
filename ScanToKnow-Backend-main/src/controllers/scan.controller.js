// src/controllers/scan.controller.js
import * as ProductDetailService from "../services/productDetail.service.js";

/**
 * GET /v1/scan/:barcode
 * Scan is VARIANT-based. No assumptions. No refetch.
 */
export const scanByBarcode = async (req, res, next) => {
  try {
    const raw = req.params.barcode;

    // 🔒 STRICT normalization (string-only, no guessing)
    let barcode = String(raw || "");
    if (barcode.normalize) {
      barcode = barcode.normalize("NFKC");
    }
    barcode = barcode.replace(/[\u200B-\u200D\uFEFF]/g, "").trim();

    if (!barcode) {
      return res.status(400).json({ error: "Barcode required" });
    }

    const result =
      await ProductDetailService.getVariantDetailByBarcode(barcode);

    if (!result || !result.dto) {
      return res
        .status(404)
        .json({ error: "Product not found for barcode" });
    }

    // Best-effort scan stats update (never blocks scan)
    try {
      await ProductDetailService.incrementVariantScanStats(
        result.variantDoc._id
      );
    } catch (e) {
      console.error("scan stats update failed:", e.message);
    }

    return res.json({
      status: "ok",
      data: result.dto
    });
  } catch (err) {
    next(err);
  }
};
