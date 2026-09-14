import mongoose from "mongoose";
import Product from "../models/product.model.js";
import ProductVariant from "../models/productVariant.model.js";
import Ingredient from "../models/ingredient.model.js";
import Additive from "../models/additive.model.js";
import Category from "../models/category.model.js";

const categoryBreadcrumbCache = new Map();

function toObjectId(id) {
  if (!id) return null;
  return mongoose.Types.ObjectId.isValid(id) ? new mongoose.Types.ObjectId(id) : null;
}

async function buildBreadcrumbForCategory(catId) {
  if (!catId) return [];
  const key = String(catId);
  if (categoryBreadcrumbCache.has(key)) return categoryBreadcrumbCache.get(key);

  const breadcrumb = [];
  let cur = await Category.findById(catId).select("_id name slug parent_id").lean();
  const seen = new Set();

  while (cur && !seen.has(String(cur._id))) {
    breadcrumb.unshift({ id: cur._id, name: cur.name, slug: cur.slug || null });
    seen.add(String(cur._id));
    cur = cur.parent_id
      ? await Category.findById(cur.parent_id).select("_id name slug parent_id").lean()
      : null;
  }

  categoryBreadcrumbCache.set(key, breadcrumb);
  return breadcrumb;
}

async function createResolutionContext(variants = []) {
  const ingredientIds = new Set();
  const ingredientNames = new Set();
  const additiveCodes = new Set();

  for (const variant of variants) {
    for (const item of variant.ingredient_summary || []) {
      if (item.ingredient_id) ingredientIds.add(String(item.ingredient_id));
      if (item.name) ingredientNames.add(String(item.name).trim().toLowerCase());
    }
    for (const item of variant.additives || []) {
      if (item.code) additiveCodes.add(String(item.code).trim());
      else if (item._id) additiveCodes.add(String(item._id));
    }
  }

  const [ingredients, additives] = await Promise.all([
    Ingredient.find({
      $or: [
        ...(ingredientIds.size ? [{ _id: { $in: [...ingredientIds] } }] : []),
        ...(ingredientNames.size
          ? [{ canonical_name: { $in: [...ingredientNames] } }]
          : []),
        ...(ingredientNames.size ? [{ aliases: { $in: [...ingredientNames] } }] : []),
      ],
    }).lean(),
    Additive.find({
      $or: [
        ...(additiveCodes.size ? [{ code: { $in: [...additiveCodes] } }] : []),
        ...(additiveCodes.size && [...additiveCodes].every((v) => mongoose.Types.ObjectId.isValid(v))
          ? [{ _id: { $in: [...additiveCodes] } }]
          : []),
      ],
    }).lean(),
  ]);

  const ingredientById = new Map(ingredients.map((x) => [String(x._id), x]));
  const ingredientByName = new Map();
  for (const ingredient of ingredients) {
    if (ingredient.canonical_name) ingredientByName.set(ingredient.canonical_name.trim().toLowerCase(), ingredient);
    for (const alias of ingredient.aliases || []) ingredientByName.set(alias.trim().toLowerCase(), ingredient);
  }
  const additiveByCode = new Map(additives.filter((x) => x.code).map((x) => [String(x.code).trim().toUpperCase(), x]));
  const additiveById = new Map(additives.map((x) => [String(x._id), x]));

  return { ingredientById, ingredientByName, additiveByCode, additiveById };
}

function resolveIngredientSummaryEntry(item, context) {
  if (!item) return null;
  const info =
    (item.ingredient_id && context.ingredientById.get(String(item.ingredient_id))) ||
    (item.name && context.ingredientByName.get(item.name.trim().toLowerCase())) ||
    null;

  return {
    ingredient_id: info?._id || item.ingredient_id || null,
    name_in_text: item.name || null,
    canonical_name: info?.canonical_name || item.name || null,
    percentage: item.percentage ?? null,
    health_rating: info?.health_rating ?? null,
    source_tag: info?.source_tag || null,
    description: info?.description || null,
  };
}

function resolveAdditiveEntry(addRef, context) {
  if (!addRef) return null;
  const code = addRef.code || (addRef._id ? String(addRef._id) : null);
  const info =
    (code && context.additiveByCode.get(String(code).trim().toUpperCase())) ||
    (addRef._id && context.additiveById.get(String(addRef._id))) ||
    null;

  return {
    code: info?.code || code || null,
    name: info?.name || null,
    description: info?.description || null,
    source_tag: info?.source_tag || null,
    percentage: addRef.percentage ?? null,
    confidence: addRef.confidence ?? null,
    health_rating: info?.health_rating ?? null,
    notes: info?.notes || null,
    synonyms: info?.synonyms || [],
  };
}

async function assembleVariantDTO(variantDoc, context) {
  if (!variantDoc) return null;

  const parent = variantDoc.parent_product_id
    ? await Product.findById(variantDoc.parent_product_id)
        .select("_id product_name variant_ids")
        .lean()
    : null;

  let siblings = [];
  if (parent?.variant_ids?.length) {
    const raw = await ProductVariant.find({ parent_product_id: parent._id })
      .select("_id title sku barcodes quantity_value quantity_unit images.front")
      .lean();
    siblings = raw.map((v) => ({
      id: v._id,
      title: v.title,
      sku: v.sku,
      barcode: v.barcodes?.[0] || null,
      quantity_value: v.quantity_value || null,
      quantity_unit: v.quantity_unit || null,
      image: v.images?.front || null,
    }));
  }

  const categories = variantDoc.category_ids?.length
    ? await buildBreadcrumbForCategory(variantDoc.category_ids[0])
    : [];

  return {
    id: variantDoc._id,
    sku: variantDoc.sku || null,
    title: variantDoc.title || null,
    barcodes: variantDoc.barcodes || [],
    images: variantDoc.images || {},
    brand: variantDoc.brand?.name || null,
    parent_product: parent
      ? { id: parent._id, name: parent.product_name, variants: siblings }
      : null,
    quantity_value: variantDoc.quantity_value || null,
    quantity_unit: variantDoc.quantity_unit || null,
    categories,
    nutriments: variantDoc.nutriments || {},
    nutri_score: variantDoc.nutri_score || null,
    nova_group: variantDoc.nova_group || null,
    cphs_final: variantDoc.cphs_final ?? null,
    health_label: variantDoc.health_label ?? null,
    health_stars: variantDoc.health_stars ?? null,
    ingredient_summary: (variantDoc.ingredient_summary || [])
      .map((item) => resolveIngredientSummaryEntry(item, context))
      .filter(Boolean),
    additives: (variantDoc.additives || [])
      .map((item) => resolveAdditiveEntry(item, context))
      .filter(Boolean),
    tags: [],
    scan_stats: variantDoc.scan_stats || { total_scans: 0, last_scanned: null },
  };
}

export async function getVariantDetailByBarcode(barcode) {
  if (!barcode) return null;
  const normalized = String(barcode).normalize("NFKC").replace(/[\u200B-\u200D\uFEFF]/g, "").trim();
  const variant = await ProductVariant.findOne({ barcodes: normalized }).lean();
  if (!variant) return null;
  const context = await createResolutionContext([variant]);
  return { dto: await assembleVariantDTO(variant, context), variantDoc: variant };
}

export async function getVariantDetailById(variantId) {
  const _id = toObjectId(variantId);
  if (!_id) return null;
  const variant = await ProductVariant.findById(_id).lean();
  if (!variant) return null;
  const context = await createResolutionContext([variant]);
  return assembleVariantDTO(variant, context);
}

export async function getProductDetailById(productId) {
  const _id = toObjectId(productId);
  if (!_id) return null;
  const product = await Product.findById(_id).lean();
  if (!product) return null;

  const variants = await ProductVariant.find({ parent_product_id: product._id }).lean();
  const context = await createResolutionContext(variants);
  const dtoVariants = [];
  for (const variant of variants) {
    const dto = await assembleVariantDTO(variant, context);
    if (dto) dtoVariants.push(dto);
  }

  return {
    id: product._id,
    product_name: product.product_name,
    code: product.code || null,
    brand: product.brand || null,
    flavor_tags: product.flavor_tags || [],
    curated: product.curated || false,
    variants: dtoVariants,
  };
}

export async function incrementVariantScanStats(variantId) {
  const _id = toObjectId(variantId);
  if (!_id) return;
  await ProductVariant.findByIdAndUpdate(_id, {
    $inc: { "scan_stats.total_scans": 1 },
    $set: { "scan_stats.last_scanned": new Date() },
  });
}
