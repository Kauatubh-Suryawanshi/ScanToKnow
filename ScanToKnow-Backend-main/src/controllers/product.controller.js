// src/controllers/product.controller.js
import * as ProductService from "../services/product.service.js";
import { parseListQuery, toObjectId } from "../utils/queryParser.js";

export const listProducts = async (req, res, next) => {
  try {
    const { page, limit, skip, filters, sort, categoryId } = parseListQuery(req.query);
    // convert categoryId to ObjectId if needed
    const catId = toObjectId(categoryId) || categoryId;
    const withFacets = (req.query.withFacets === "true" || req.query.withFacets === "1");

    const result = await ProductService.getProductsByCategory({
      categoryId: catId,
      filters,
      page,
      limit,
      skip,
      sort,
      withFacets
    });

    res.json({ status: "ok", data: result.items, facets: result.facets, meta: result.meta });
  } catch (err) {
    next(err);
  }
};
