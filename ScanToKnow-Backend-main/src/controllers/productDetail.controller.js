// src/controllers/productDetail.controller.js
import * as ProductDetailService from "../services/productDetail.service.js";

export const getProductDetail = async (req, res, next) => {
  try {
    const productId = req.params.id;
    const data = await ProductDetailService.getProductDetailById(productId);
    if (!data) return res.status(404).json({ error: "Product not found" });
    res.json({ status: "ok", data });
  } catch (err) {
    next(err);
  }
};

export const getVariantDetail = async (req, res, next) => {
  try {
    const variantId = req.params.id;
    const data = await ProductDetailService.getVariantDetailById(variantId);
    if (!data) return res.status(404).json({ error: "Variant not found" });
    res.json({ status: "ok", data });
  } catch (err) {
    next(err);
  }
};
