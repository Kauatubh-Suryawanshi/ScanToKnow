// src/utils/queryParser.js
import mongoose from "mongoose";

export function parseListQuery(qs = {}) {
  const page = Math.max(1, parseInt(qs.page || 1, 10));
  const limit = Math.min(100, Math.max(1, parseInt(qs.limit || 20, 10)));
  const skip = (page - 1) * limit;

  const filters = {};

  if (qs.min_sugar) filters.min_sugar = parseFloat(qs.min_sugar);
  if (qs.max_sugar) filters.max_sugar = parseFloat(qs.max_sugar);
  if (qs.brand) filters.brand = qs.brand.split(",").map(s => s.trim());
  if (qs.nova_group) filters.nova_group = qs.nova_group.split(",").map(n => parseInt(n,10));
  if (qs.nutri_score) filters.nutri_score = qs.nutri_score.split(",").map(s => s.trim().toLowerCase());
  if (qs.has_additive) filters.has_additive = qs.has_additive.split(",").map(s => s.trim().toUpperCase());
  if (qs.q) filters.q = qs.q.trim();

  // sort: field:direction e.g. sugar:asc or relevance:desc
  const sort = qs.sort || "relevance:desc";

  // categoryId may be an ObjectId string or code; leave as is
  const categoryId = qs.category || null;

  return { page, limit, skip, filters, sort, categoryId };
}

export function toObjectId(id) {
  if (!id) return null;
  try {
    return mongoose.Types.ObjectId(id);
  } catch (e) {
    return null;
  }
}
