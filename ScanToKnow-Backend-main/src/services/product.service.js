// // // src/services/product.service.js

// import mongoose from "mongoose";
// import Category from "../models/category.model.js";
// import ProductVariant from "../models/productVariant.model.js";

// // sugar buckets thresholds (g per 100g or per 100ml as your dataset uses)
// const SUGAR_BUCKETS = [0, 5, 12, 1000];

// /**
//  * Resolve categoryId which might be:
//  * - an ObjectId string
//  * - a category code, slug, or name (case insensitive)
//  * - something like 'cat_drinks' or 'category-drinks' etc.
//  * Returns an ObjectId or null
//  */
// async function resolveCategoryObjectId(categoryId) {
//   if (!categoryId) return null;

//   const raw = String(categoryId).trim();

//   if (mongoose.Types.ObjectId.isValid(raw)) {
//     return new mongoose.Types.ObjectId(raw);
//   }

//   let cat = await Category.findOne({
//     $or: [{ code: raw }, { slug: raw }, { name: raw }]
//   }).select("_id").lean();
//   if (cat && cat._id) return cat._id;

//   const lower = raw.toLowerCase();
//   cat = await Category.findOne({
//     $or: [{ code: lower }, { slug: lower }, { name: lower }]
//   }).select("_id").lean();
//   if (cat && cat._id) return cat._id;

//   const stripped = lower.replace(/^(cat|category)[-_]?/, '');
//   if (stripped !== lower) {
//     cat = await Category.findOne({
//       $or: [{ code: stripped }, { slug: stripped }, { name: stripped }]
//     }).select("_id").lean();
//     if (cat && cat._id) return cat._id;
//   }

//   const re = new RegExp(`^${raw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i');
//   cat = await Category.findOne({
//     $or: [{ code: re }, { slug: re }, { name: re }]
//   }).select("_id").lean();
//   if (cat && cat._id) return cat._id;

//   return null;
// }

// async function getDescendantCategoryIds(categoryId) {
//   if (!categoryId) return [];

//   const catObjectId = await resolveCategoryObjectId(categoryId);
//   if (!catObjectId) return [];

//   const res = await Category.aggregate([
//     { $match: { _id: catObjectId } },
//     {
//       $graphLookup: {
//         from: "categories",
//         startWith: "$_id",
//         connectFromField: "_id",
//         connectToField: "parent_id",
//         as: "descendants",
//         depthField: "depth"
//       }
//     },
//     {
//       $project: {
//         ids: {
//           $concatArrays: [
//             ["$_id"],
//             { $map: { input: "$descendants", as: "d", in: "$$d._id" } }
//           ]
//         }
//       }
//     }
//   ]).allowDiskUse(true);

//   if (!res || res.length === 0) return [];
//   return res[0].ids;
// }

// export async function getProductsByCategory({
//   categoryId,
//   filters = {},
//   page = 1,
//   limit = 20,
//   skip = 0,
//   sort = "relevance:desc",
//   withFacets = true
// }) {
//   const descendantIds = categoryId ? await getDescendantCategoryIds(categoryId) : [];

//   const match = {};
//   if (descendantIds && descendantIds.length) {
//     match["category_ids"] = { $in: descendantIds };
//   } else if (categoryId) {
//     match["category_ids"] = { $in: [categoryId] };
//   }

//   if (filters.min_sugar !== undefined || filters.max_sugar !== undefined) {
//     match["nutriments.sugar_g_100g"] = {};
//     if (filters.min_sugar !== undefined) match["nutriments.sugar_g_100g"].$gte = filters.min_sugar;
//     if (filters.max_sugar !== undefined) match["nutriments.sugar_g_100g"].$lte = filters.max_sugar;
//   }

//   if (filters.brand && filters.brand.length) {
//     match["brand.name"] = { $in: filters.brand };
//   }

//   if (filters.nova_group && filters.nova_group.length) {
//     match["nova_group"] = { $in: filters.nova_group };
//   }

//   if (filters.nutri_score && filters.nutri_score.length) {
//     match["nutri_score"] = { $in: filters.nutri_score.map(s => s.toLowerCase()) };
//   }

//   if (filters.has_additive && filters.has_additive.length) {
//     match["additives.code"] = { $in: filters.has_additive };
//   }

//   const pipeline = [];

//   if (filters.q) {
//     pipeline.push({ $match: { $text: { $search: filters.q } } });
//   } else if (Object.keys(match).length) {
//     pipeline.push({ $match: match });
//   }

//   pipeline.push(
//     {
//       $lookup: {
//         from: "products",
//         localField: "parent_product_id",
//         foreignField: "_id",
//         as: "product"
//       }
//     },
//     { $unwind: { path: "$product", preserveNullAndEmptyArrays: true } }
//   );

//   pipeline.push({
//     $project: {
//       title: "$title",
//       sku: "$sku",
//       barcodes: "$barcodes",
//       brand: "$brand",
//       quantity_value: "$quantity_value",
//       quantity_unit: "$quantity_unit",
//       image: "$images.front",
//       sugar_per_100g: "$nutriments.sugar_g_100g",
//       nova_group: "$nova_group",
//       nutri_score: "$nutri_score",
//       has_additives: { $gt: [{ $size: { $ifNull: ["$additives", []] } }, 0] },
//       additives: "$additives.code",
//       parent_product: { id: "$product._id", name: "$product.product_name" }
//     }
//   });

//   let sortStage = {};
//   const [sortField, sortDir] = (sort || "relevance:desc").split(":");
//   if (sortField === "sugar") sortStage["sugar_per_100g"] = sortDir === "asc" ? 1 : -1;
//   else if (sortField === "nova") sortStage["nova_group"] = sortDir === "asc" ? 1 : -1;
//   else sortStage["_id"] = -1;

//   const facetPipeline = {
//     $facet: {
//       data: [
//         { $sort: sortStage },
//         { $skip: skip },
//         { $limit: limit }
//       ],
//       totalCount: [{ $count: "count" }],
//       brandCounts: [
//         { $group: { _id: "$brand.name", count: { $sum: 1 } } },
//         { $sort: { count: -1 } }
//       ],
//       novaCounts: [
//         { $group: { _id: "$nova_group", count: { $sum: 1 } } },
//         { $sort: { _id: 1 } }
//       ],
//       nutriCounts: [
//         { $group: { _id: "$nutri_score", count: { $sum: 1 } } },
//         { $sort: { _id: 1 } }
//       ],
//       sugarBuckets: [
//         {
//           $bucket: {
//             groupBy: "$sugar_per_100g",
//             boundaries: SUGAR_BUCKETS,
//             default: "Unknown",
//             output: { count: { $sum: 1 } }
//           }
//         }
//       ],
//       additiveCounts: [
//         { $unwind: { path: "$additives", preserveNullAndEmptyArrays: true } },
//         { $group: { _id: "$additives", count: { $sum: 1 } } },
//         { $sort: { count: -1 } },
//         { $limit: 50 }
//       ]
//     }
//   };

//   pipeline.push(facetPipeline);

//   const agg = ProductVariant.aggregate(pipeline).allowDiskUse(true);
//   const res = await agg.exec();
//   const buckets = (res && res[0]) ? res[0] : {};

//   const total = (buckets.totalCount && buckets.totalCount[0]) ? buckets.totalCount[0].count : 0;
//   const items = (buckets.data || []).map(v => ({
//     id: v._id,
//     title: v.title,
//     sku: v.sku,
//     barcodes: v.barcodes,
//     image: v.image,
//     brand: v.brand && v.brand.name,
//     quantity_value: v.quantity_value,
//     quantity_unit: v.quantity_unit,
//     sugar_per_100g: v.sugar_per_100g,
//     nova_group: v.nova_group,
//     nutri_score: v.nutri_score,
//     has_additives: v.has_additives,
//     parent_product: v.parent_product
//   }));

//   const facets = {
//     brands: (buckets.brandCounts || []).map(b => ({ brand: b._id || "Unknown", count: b.count })),
//     nova_groups: (buckets.novaCounts || []).map(n => ({ group: n._id, count: n.count })),
//     nutri_scores: (buckets.nutriCounts || []).map(n => ({ score: n._id, count: n.count })),
//     sugar_buckets: (buckets.sugarBuckets || []).map(b => ({ range: b._id, count: b.count })),
//     additives: (buckets.additiveCounts || []).map(a => ({ code: a._id, count: a.count }))
//   };

//   const meta = { total, page, limit, pages: limit ? Math.ceil(total / limit) : 0 };

//   return { items, facets, meta };
// }

import mongoose from "mongoose";
import Category from "../models/category.model.js";
import ProductVariant from "../models/productVariant.model.js";

// sugar buckets thresholds (g per 100g or per 100ml as your dataset uses)
const SUGAR_BUCKETS = [0, 5, 12, 1000];

/**
 * Resolve categoryId which might be:
 * - an ObjectId string
 * - a category code, slug, or name (case insensitive)
 * - something like 'cat_drinks' or 'category-drinks' etc.
 * Returns an ObjectId or null
 */
async function resolveCategoryObjectId(categoryId) {
  if (!categoryId) return null;

  const raw = String(categoryId).trim();

  if (mongoose.Types.ObjectId.isValid(raw)) {
    return new mongoose.Types.ObjectId(raw);
  }

  let cat = await Category.findOne({
    $or: [{ code: raw }, { slug: raw }, { name: raw }]
  }).select("_id").lean();
  if (cat && cat._id) return cat._id;

  const lower = raw.toLowerCase();
  cat = await Category.findOne({
    $or: [{ code: lower }, { slug: lower }, { name: lower }]
  }).select("_id").lean();
  if (cat && cat._id) return cat._id;

  const stripped = lower.replace(/^(cat|category)[-_]?/, '');
  if (stripped !== lower) {
    cat = await Category.findOne({
      $or: [{ code: stripped }, { slug: stripped }, { name: stripped }]
    }).select("_id").lean();
    if (cat && cat._id) return cat._id;
  }

  const re = new RegExp(`^${raw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i');
  cat = await Category.findOne({
    $or: [{ code: re }, { slug: re }, { name: re }]
  }).select("_id").lean();
  if (cat && cat._id) return cat._id;

  return null;
}

async function getDescendantCategoryIds(categoryId) {
  if (!categoryId) return [];

  const catObjectId = await resolveCategoryObjectId(categoryId);
  if (!catObjectId) return [];

  const res = await Category.aggregate([
    { $match: { _id: catObjectId } },
    {
      $graphLookup: {
        from: "categories",
        startWith: "$_id",
        connectFromField: "_id",
        connectToField: "parent_id",
        as: "descendants",
        depthField: "depth"
      }
    },
    {
      $project: {
        ids: {
          $concatArrays: [
            ["$_id"],
            { $map: { input: "$descendants", as: "d", in: "$$d._id" } }
          ]
        }
      }
    }
  ]).allowDiskUse(true);

  if (!res || res.length === 0) return [];
  return res[0].ids;
}

export async function getProductsByCategory({
  categoryId,
  filters = {},
  page = 1,
  limit = 20,
  skip = 0,
  sort = "relevance:desc",
  withFacets = true
}) {
  const descendantIds = categoryId ? await getDescendantCategoryIds(categoryId) : [];

  const match = {};
  if (descendantIds && descendantIds.length) {
    match["category_ids"] = { $in: descendantIds };
  } else if (categoryId) {
    match["category_ids"] = { $in: [categoryId] };
  }

  if (filters.min_sugar !== undefined || filters.max_sugar !== undefined) {
    match["nutriments.sugar_g_100g"] = {};
    if (filters.min_sugar !== undefined) match["nutriments.sugar_g_100g"].$gte = filters.min_sugar;
    if (filters.max_sugar !== undefined) match["nutriments.sugar_g_100g"].$lte = filters.max_sugar;
  }

  if (filters.brand && filters.brand.length) {
    match["brand.name"] = { $in: filters.brand };
  }

  if (filters.nova_group && filters.nova_group.length) {
    match["nova_group"] = { $in: filters.nova_group };
  }

  if (filters.nutri_score && filters.nutri_score.length) {
    match["nutri_score"] = { $in: filters.nutri_score.map(s => s.toLowerCase()) };
  }

  if (filters.has_additive && filters.has_additive.length) {
    match["additives.code"] = { $in: filters.has_additive };
  }

  const pipeline = [];

  if (filters.q) {
    pipeline.push({ $match: { $text: { $search: filters.q } } });
  } else if (Object.keys(match).length) {
    pipeline.push({ $match: match });
  }

  pipeline.push(
    {
      $lookup: {
        from: "products",
        localField: "parent_product_id",
        foreignField: "_id",
        as: "product"
      }
    },
    { $unwind: { path: "$product", preserveNullAndEmptyArrays: true } }
  );

  pipeline.push({
    $project: {
      title: "$title",
      sku: "$sku",
      barcodes: "$barcodes",
      brand: "$brand",
      quantity_value: "$quantity_value",
      quantity_unit: "$quantity_unit",
      image: "$images.front",
      sugar_per_100g: "$nutriments.sugar_g_100g",

      // ✅ ONLY ADDED (nothing else changed)
      saturated_fat_g_100g: "$nutriments.saturated_fat_g_100g",
      sodium_g_100g: "$nutriments.sodium_g_100g",

      nova_group: "$nova_group",
      nutri_score: "$nutri_score",
      has_additives: { $gt: [{ $size: { $ifNull: ["$additives", []] } }, 0] },
      additives: "$additives.code",
      parent_product: { id: "$product._id", name: "$product.product_name" }
    }
  });

  let sortStage = {};
  const [sortField, sortDir] = (sort || "relevance:desc").split(":");
  if (sortField === "sugar") sortStage["sugar_per_100g"] = sortDir === "asc" ? 1 : -1;
  else if (sortField === "nova") sortStage["nova_group"] = sortDir === "asc" ? 1 : -1;
  else sortStage["_id"] = -1;

  const facetPipeline = {
    $facet: {
      data: [
        { $sort: sortStage },
        { $skip: skip },
        { $limit: limit }
      ],
      totalCount: [{ $count: "count" }],
      brandCounts: [
        { $group: { _id: "$brand.name", count: { $sum: 1 } } },
        { $sort: { count: -1 } }
      ],
      novaCounts: [
        { $group: { _id: "$nova_group", count: { $sum: 1 } } },
        { $sort: { _id: 1 } }
      ],
      nutriCounts: [
        { $group: { _id: "$nutri_score", count: { $sum: 1 } } },
        { $sort: { _id: 1 } }
      ],
      sugarBuckets: [
        {
          $bucket: {
            groupBy: "$sugar_per_100g",
            boundaries: SUGAR_BUCKETS,
            default: "Unknown",
            output: { count: { $sum: 1 } }
          }
        }
      ],
      additiveCounts: [
        { $unwind: { path: "$additives", preserveNullAndEmptyArrays: true } },
        { $group: { _id: "$additives", count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 50 }
      ]
    }
  };

  pipeline.push(facetPipeline);

  const agg = ProductVariant.aggregate(pipeline).allowDiskUse(true);
  const res = await agg.exec();
  const buckets = (res && res[0]) ? res[0] : {};

  const total = (buckets.totalCount && buckets.totalCount[0]) ? buckets.totalCount[0].count : 0;

  const items = (buckets.data || []).map(v => ({
    id: v._id,
    title: v.title,
    sku: v.sku,
    barcodes: v.barcodes,
    image: v.image,
    brand: v.brand && v.brand.name,
    quantity_value: v.quantity_value,
    quantity_unit: v.quantity_unit,
    sugar_per_100g: v.sugar_per_100g,

    // ✅ ONLY ADDED
    saturated_fat_g_100g: v.saturated_fat_g_100g,
    sodium_g_100g: v.sodium_g_100g,

    nova_group: v.nova_group,
    nutri_score: v.nutri_score,
    has_additives: v.has_additives,
    parent_product: v.parent_product
  }));

  const facets = {
    brands: (buckets.brandCounts || []).map(b => ({ brand: b._id || "Unknown", count: b.count })),
    nova_groups: (buckets.novaCounts || []).map(n => ({ group: n._id, count: n.count })),
    nutri_scores: (buckets.nutriCounts || []).map(n => ({ score: n._id, count: n.count })),
    sugar_buckets: (buckets.sugarBuckets || []).map(b => ({ range: b._id, count: b.count })),
    additives: (buckets.additiveCounts || []).map(a => ({ code: a._id, count: a.count }))
  };

  const meta = { total, page, limit, pages: limit ? Math.ceil(total / limit) : 0 };

  return { items, facets, meta };
}