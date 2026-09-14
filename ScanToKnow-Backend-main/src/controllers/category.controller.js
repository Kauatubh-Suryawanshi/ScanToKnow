// src/controllers/category.controller.js
import * as CategoryService from "../services/category.service.js";

/**
 * Utility: normalize incoming params
 * - removes BOM / zero-width chars
 * - trims whitespace
 */
function normalizeParam(raw) {
  let val = String(raw || "");
  if (val.normalize) {
    val = val.normalize("NFKC");
  }
  return val.replace(/[\u200B-\u200D\uFEFF]/g, "").trim();
}

/**
 * GET /v1/categories
 * Optional query:
 *   ?level=1
 *   ?limit=6
 */
export const listCategories = async (req, res, next) => {
  try {
    const level =
      req.query.level !== undefined ? Number(req.query.level) : undefined;

    const rawLimit = req.query.limit !== undefined ? Number(req.query.limit) : undefined;
    const limit = Number.isFinite(rawLimit) ? Math.min(100, Math.max(1, rawLimit)) : undefined;

    const data = await CategoryService.listCategories({
      level,
      limit
    });

    return res.json({ status: "ok", data });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /v1/categories/:id
 * id = slug OR ObjectId
 */
export const getCategory = async (req, res, next) => {
  try {
    const id = normalizeParam(req.params.id);
    if (!id) {
      return res.status(400).json({ error: "Category id required" });
    }

    const data = await CategoryService.getCategoryByIdOrSlug(id);
    if (!data) {
      return res.status(404).json({ error: "Category not found" });
    }

    return res.json({ status: "ok", data });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /v1/categories/:id/children
 * Returns immediate subcategories (level+1)
 */
export const getChildren = async (req, res, next) => {
  try {
    const id = normalizeParam(req.params.id);
    if (!id) {
      return res.status(400).json({ error: "Category id required" });
    }

    const data = await CategoryService.getImmediateChildren(id);
    return res.json({ status: "ok", data });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /v1/categories/:id/products
 * Query params:
 *   ?page=1
 *   ?limit=24
 *   ?sort=popular|new|alpha
 */
export const getProductsForCategory = async (req, res, next) => {
  try {
    const id = normalizeParam(req.params.id);
    if (!id) {
      return res.status(400).json({ error: "Category id required" });
    }

    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 24));
    const sort = req.query.sort || "popular";

    const result = await CategoryService.getProductsForCategory({
      id,
      page,
      limit,
      sort
    });

    return res.json({
      status: "ok",
      ...result
    });
  } catch (err) {
    next(err);
  }
};
