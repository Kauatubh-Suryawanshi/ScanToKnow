// src/controllers/search.controller.js
import * as SearchService from "../services/search.service.js";

export const autocomplete = async (req, res, next) => {
  try {
    const q = (req.query.q || "").trim();
    if (!q) {
      return res.json({ status: "ok", data: [] });
    }

    const limit = Math.min(10, Math.max(1, Number(req.query.limit) || 7));
    const data = await SearchService.autocomplete(q, limit);

    res.json({ status: "ok", data });
  } catch (err) {
    next(err);
  }
};

export const search = async (req, res, next) => {
  try {
    // Accept either:
    // - q  (text search across variants/products), or
    // - product_id (when a product suggestion was selected)
    const q = (req.query.q || "").trim();
    const productId = req.query.product_id || null;

    // pagination
    const page = Math.max(Number(req.query.page) || 1, 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 24));

    // filters (basic v1)
    const filters = {
      nutri_score: req.query.nutri_score
        ? req.query.nutri_score.split(",")
        : null,
      nova_group: req.query.nova_group
        ? req.query.nova_group.split(",").map(Number)
        : null,
      has_additive: req.query.additive
        ? req.query.additive.split(",")
        : null
    };

    // Delegate to service. service will branch based on productId vs query.
    const result = await SearchService.search(q, {
      page,
      limit,
      filters,
      productId
    });

    res.json({ status: "ok", ...result });
  } catch (err) {
    next(err);
  }
};
