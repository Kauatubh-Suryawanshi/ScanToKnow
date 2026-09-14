import mongoose from "mongoose";
import Product from "../models/product.model.js";
import ProductVariant from "../models/productVariant.model.js";

/* =========================================================
   AUTOCOMPLETE (Typing) - PRODUCTS
   Uses: products_search Atlas index
   ========================================================= */
export async function autocomplete(query, limit = 7) {
  if (!query) return [];

  const pipeline = [
    {
      $search: {
        index: "products_search",
        autocomplete: {
          query,
          path: "product_name",
          fuzzy: { maxEdits: 1 }
        }
      }
    },
    {
      $project: {
        _id: 0,
        id: { $toString: "$_id" },
        label: "$product_name",
        brand: "$brand",
        score: { $meta: "searchScore" }
      }
    },
    { $sort: { score: -1 } },
    { $limit: limit }
  ];

  return Product.aggregate(pipeline);
}


/* =========================================================
   FULL SEARCH (Enter pressed)
   Behavior:
     - If product_id given -> return variants for that product
     - Else -> run variant-level Atlas Search on product_variants
   ========================================================= */
export async function search(q, { page = 1, limit = 24, filters = {}, productId = null }) {
  if (productId) {
    return searchByProductId(productId, { page, limit, filters });
  }

  if (!q) {
    return {
      data: [],
      facets: {},
      meta: { page, limit, total: 0, pages: 0 }
    };
  }

  return searchVariantsByQuery(q, { page, limit, filters });
}

/* ------------------------
   Helper: convert to ObjectId safely
   ------------------------ */
function toObjectIdOrNull(id) {
  if (!id) return null;
  if (mongoose.Types.ObjectId.isValid(id)) {
    return new mongoose.Types.ObjectId(id);
  }
  return null;
}

/* =========================================================
   searchByProductId
   - Returns all variants whose parent_product_id == productId
   - Includes parent product name via lookup
   - Computes health_label from cphs_final (NR if null)
   ========================================================= */
export async function searchByProductId(productId, { page = 1, limit = 24, filters = {} }) {
  const pid = toObjectIdOrNull(productId);
  if (!pid) {
    return {
      data: [],
      facets: {},
      meta: { page, limit, total: 0, pages: 0 }
    };
  }

  const match = { parent_product_id: pid };

  if (filters?.nutri_score?.length) {
    match.nutri_score = { $in: filters.nutri_score };
  }
  if (filters?.nova_group?.length) {
    match.nova_group = { $in: filters.nova_group };
  }
  if (filters?.has_additive?.length) {
    match["additives.code"] = { $in: filters.has_additive };
  }

  const pipeline = [
    { $match: match },
    {
      $lookup: {
        from: "products",
        localField: "parent_product_id",
        foreignField: "_id",
        as: "product"
      }
    },
    { $unwind: "$product" },
    {
      $facet: {
        data: [
          { $sort: { "scan_stats.total_scans": -1 } },
          { $skip: (page - 1) * limit },
          { $limit: limit },
          {
            $project: {
              _id: 0,
              id: { $toString: "$_id" },
              title: "$title",
              image: "$images.front",
              quantity_value: "$quantity_value",
              quantity_unit: "$quantity_unit",
              nutri_score: "$nutri_score",
              nova_group: "$nova_group",
              cphs_final: "$cphs_final",
              health_stars: "$health_stars",
              health_label: {
                $cond: [
                  { $ne: ["$health_label", null] },
                  "$health_label",
                  {
                    $cond: [
                      { $ne: ["$cphs_final", null] },
                      {
                        $switch: {
                          branches: [
                            { case: { $gte: ["$cphs_final", 0.85] }, then: "very_good" },
                            { case: { $gte: ["$cphs_final", 0.60] }, then: "good" },
                            { case: { $gte: ["$cphs_final", 0.40] }, then: "okay" },
                            { case: { $gte: ["$cphs_final", 0.20] }, then: "poor" }
                          ],
                          default: "very_poor"
                        }
                      },
                      "unknown"
                    ]
                  }
                ]
              },
              parent_product: {
                id: { $toString: "$product._id" },
                name: "$product.product_name"
              }
            }
          }
        ],
        totalCount: [{ $count: "count" }],
        nutriCounts: [{ $group: { _id: "$nutri_score", count: { $sum: 1 } } }],
        novaCounts: [{ $group: { _id: "$nova_group", count: { $sum: 1 } } }]
      }
    }
  ];

  const result = await ProductVariant.aggregate(pipeline).allowDiskUse(true);
  const bucket = result[0] || {};
  const total = bucket.totalCount?.[0]?.count || 0;

  return {
    data: bucket.data || [],
    facets: {
      nutri_score: bucket.nutriCounts || [],
      nova_group: bucket.novaCounts || []
    },
    meta: {
      page,
      limit,
      total,
      pages: limit ? Math.ceil(total / limit) : 0
    }
  };
}

/* =========================================================
   searchVariantsByQuery
   - Uses Atlas Search index "variants_search" on product_variants
   - Searches title (autocomplete), brand.name (autocomplete),
     sku (text), health_label (text)
   - Applies filters after search
   - Returns paged variant cards + facets
   ========================================================= */
export async function searchVariantsByQuery(query, { page = 1, limit = 24, filters = {} }) {

  const searchStage = {
    $search: {
      index: "variants_search",
      compound: {
        should: [
          // ✅ autocomplete type for title (mapped as autocomplete in index)
          {
            autocomplete: {
              query,
              path: "title",
              fuzzy: { maxEdits: 1 },
              score: { boost: { value: 5 } }
            }
          },
          // ✅ autocomplete type for brand.name (mapped as autocomplete in index)
          {
            autocomplete: {
              query,
              path: "brand.name",
              fuzzy: { maxEdits: 1 },
              score: { boost: { value: 3 } }
            }
          },
          // ✅ text for sku (mapped as string in index)
          {
            text: {
              query,
              path: "sku",
              score: { boost: { value: 2 } }
            }
          },
          // ✅ text for health_label (mapped as string in index)
          {
            text: {
              query,
              path: "health_label",
              score: { boost: { value: 1 } }
            }
          }
          // ❌ REMOVED: description — caused 0 results (type mismatch with compound)
        ],
        minimumShouldMatch: 1
      }
    }
  };

  const projectAfterSearch = {
    $project: {
      score: { $meta: "searchScore" },
      title: 1,
      images: 1,
      quantity_value: 1,
      quantity_unit: 1,
      nutri_score: 1,
      nova_group: 1,
      cphs_final: 1,
      health_label: 1,
      health_stars: 1,
      parent_product_id: 1,
      "scan_stats.total_scans": 1,
      additives: 1,
      sku: 1
    }
  };

  const postSearchMatch = { $match: {} };
  if (filters?.nutri_score?.length) {
    postSearchMatch.$match.nutri_score = { $in: filters.nutri_score };
  }
  if (filters?.nova_group?.length) {
    postSearchMatch.$match.nova_group = { $in: filters.nova_group };
  }
  if (filters?.has_additive?.length) {
    postSearchMatch.$match["additives.code"] = { $in: filters.has_additive };
  }

  const lookupProduct = {
    $lookup: {
      from: "products",
      localField: "parent_product_id",
      foreignField: "_id",
      as: "product"
    }
  };

  // preserveNullAndEmptyArrays prevents variants without a parent from being dropped
  const unwindProduct = {
    $unwind: {
      path: "$product",
      preserveNullAndEmptyArrays: true
    }
  };

  const facetStage = {
    $facet: {
      data: [
        { $sort: { score: -1, "scan_stats.total_scans": -1 } },
        { $skip: (page - 1) * limit },
        { $limit: limit },
        {
          $project: {
            _id: 0,
            id: { $toString: "$_id" },
            title: "$title",
            image: "$images.front",
            quantity_value: "$quantity_value",
            quantity_unit: "$quantity_unit",
            nutri_score: "$nutri_score",
            nova_group: "$nova_group",
            cphs_final: "$cphs_final",
            health_stars: "$health_stars",
            health_label: {
              $cond: [
                { $ne: ["$health_label", null] },
                "$health_label",
                {
                  $cond: [
                    { $ne: ["$cphs_final", null] },
                    {
                      $switch: {
                        branches: [
                          { case: { $gte: ["$cphs_final", 0.85] }, then: "very_good" },
                          { case: { $gte: ["$cphs_final", 0.60] }, then: "good" },
                          { case: { $gte: ["$cphs_final", 0.40] }, then: "okay" },
                          { case: { $gte: ["$cphs_final", 0.20] }, then: "poor" }
                        ],
                        default: "very_poor"
                      }
                    },
                    "unknown"
                  ]
                }
              ]
            },
            parent_product: {
              id: { $toString: "$product._id" },
              name: "$product.product_name"
            }
          }
        }
      ],
      totalCount: [{ $count: "count" }],
      nutriCounts: [{ $group: { _id: "$nutri_score", count: { $sum: 1 } } }],
      novaCounts: [{ $group: { _id: "$nova_group", count: { $sum: 1 } } }]
    }
  };

  const pipeline = [
    searchStage,
    projectAfterSearch,
    ...(Object.keys(postSearchMatch.$match).length ? [postSearchMatch] : []),
    lookupProduct,
    unwindProduct,
    facetStage
  ];

  const result = await ProductVariant.aggregate(pipeline).allowDiskUse(true);
  const bucket = result[0] || {};
  const total = bucket.totalCount?.[0]?.count || 0;

  return {
    data: bucket.data || [],
    facets: {
      nutri_score: bucket.nutriCounts || [],
      nova_group: bucket.novaCounts || []
    },
    meta: {
      page,
      limit,
      total,
      pages: limit ? Math.ceil(total / limit) : 0
    }
  };
}
