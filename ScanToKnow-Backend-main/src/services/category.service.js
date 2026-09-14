// src/services/category.service.js
import mongoose from "mongoose";
import Category from "../models/category.model.js";
import ProductVariant from "../models/productVariant.model.js";

/**
 * Normalize slug input (frontend-safe)
 */
function normalizeSlug(value) {
  if (!value) return value;
  return String(value).trim().toLowerCase();
}

/**
 * Accept ObjectId or slug
 */
async function findCategoryByIdOrSlug(idOrSlug) {
  if (!idOrSlug) return null;

  // Try ObjectId first
  if (mongoose.Types.ObjectId.isValid(idOrSlug)) {
    const byId = await Category.findById(idOrSlug).lean();
    if (byId) return byId;
  }

  // Fallback to slug (case-insensitive)
  const slug = normalizeSlug(idOrSlug);
  return await Category.findOne({ slug }).lean();
}

/**
 * List categories
 * Used for:
 *  - Top categories (level=1)
 *  - View All categories
 */
export async function listCategories({ level, limit } = {}) {
  const query = {};
  if (level !== undefined) query.level = Number(level);

  let q = Category.find(query)
    .select("_id code name slug level parent_id display_order icon description path")
    .sort({ display_order: 1, name: 1 });

  if (limit && Number(limit) > 0) {
    q = q.limit(Number(limit));
  }

  return await q.lean();
}

/**
 * Get single category
 */
export async function getCategoryByIdOrSlug(idOrSlug) {
  return findCategoryByIdOrSlug(idOrSlug);
}

/**
 * Get immediate children (level-2)
 */
export async function getImmediateChildren(idOrSlug) {
  const cat = await findCategoryByIdOrSlug(idOrSlug);
  if (!cat) return [];

  return await Category.find({ parent_id: cat._id })
    .select("_id code name slug level parent_id display_order icon description path")
    .sort({ display_order: 1, name: 1 })
    .lean();
}

/**
 * Get all descendant category IDs (including self)
 * Uses path prefix match
 */
async function getDescendantCategoryIds(cat) {
  if (!cat) return [];

  // Ensure path is valid
  const pathPrefix = cat.path && cat.path.length
    ? cat.path
    : `,${cat.slug},`;

  const escaped = pathPrefix.replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&");
  const regex = new RegExp("^" + escaped);

  const cats = await Category.find({ path: regex })
    .select("_id")
    .lean();

  return cats.map(c => c._id);
}

/**
 * Get products for category or subcategory
 */
export async function getProductsForCategory({
  id,
  page = 1,
  limit = 24,
  sort = "popular"
}) {
  const cat = await findCategoryByIdOrSlug(id);
  if (!cat) {
    return { total: 0, page, limit, products: [] };
  }

  const descendantIds = await getDescendantCategoryIds(cat);
  if (!descendantIds.length) {
    return { total: 0, page, limit, products: [] };
  }

  // Sorting strategies
  const sortMap = {
    popular: { "scan_stats.total_scans": -1 },
    new: { createdAt: -1 },
    alpha: { title: 1 }
  };
  const sortSpec = sortMap[sort] || sortMap.popular;

  const filter = { category_ids: { $in: descendantIds } };

  const total = await ProductVariant.countDocuments(filter);

  const products = await ProductVariant.find(filter)
    .select(
      "_id sku title barcodes images quantity_value quantity_unit brand nutri_score nova_group cphs_final"
    )
    .sort(sortSpec)
    .skip((page - 1) * limit)
    .limit(limit)
    .lean();

  return { total, page, limit, products };
}
