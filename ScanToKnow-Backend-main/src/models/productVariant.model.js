import mongoose from "mongoose";

/**
 * Ingredient summary
 * risk_tag REMOVED (now derived from canonical ingredient/additive data)
 */
const IngredientSummarySchema = new mongoose.Schema(
  {
    ingredient_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Ingredient",
      required: true
    },
    name: String,
    percentage: Number
  },
  { _id: false }
);

/**
 * Additives now carry code directly (denormalized)
 */
const AdditiveRefSchema = new mongoose.Schema(
  {
    _id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Additive"
    },
    code: String,
    percentage: Number,
    confidence: Number
  },
  { _id: false }
);

const ProductVariantSchema = new mongoose.Schema(
  {
    parent_product_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      required: true
    },

    barcodes: {
      type: [String],
      index: true
    },

    sku: String,
    title: String,
    description: String,

    brand: {
      id: { type: mongoose.Schema.Types.ObjectId, default: null },
      name: String
    },

    quantity_value: Number,
    quantity_unit: String,

    packaging: [String],

    images: {
      front: String,
      ingredients: String,
      nutrition: String
    },

    ingredient_summary: [IngredientSummarySchema],

    additives: [AdditiveRefSchema],

    // 🔹 Updated Nutriments
    nutriments: {
      energy_kcal_100g: Number,
      sugar_g_100g: Number,
      protein_g_100g: Number,
      fat_g_100g: Number,
      salt_g_100g: Number,

      // ✅ NEW FIELDS
      saturated_fat_g_100g: Number,
      sodium_g_100g: Number,

      fiber_g_100g: Number,
      fruit_veg_pct: Number
    },

    nova_group: Number,
    nutri_score: String,

    // ✅ NEW RAW FIELDS
    nutriscore_score_raw: Number,
    ingredients_text: String,

    // Computed later — can be null
    cphs_final: { type: Number, default: null },
    health_label: { type: String, default: null },
    health_stars: { type: Number, default: null },

    category_ids: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Category"
      }
    ],

    scan_stats: {
      total_scans: { type: Number, default: 0 },
      last_scanned: { type: Date, default: null }
    },

    ocr_raw_text: { type: String, default: null },
    unresolved_terms: { type: [String], default: [] }
  },
  { timestamps: true }
);

ProductVariantSchema.index({ parent_product_id: 1 });
ProductVariantSchema.index({ "additives.code": 1 });
ProductVariantSchema.index({ nutri_score: 1 });
ProductVariantSchema.index({ nova_group: 1 });
ProductVariantSchema.index({ "scan_stats.total_scans": -1 });

// Explicit collection binding.
export default mongoose.model(
  "ProductVariant",
  ProductVariantSchema,
  "product_variants"
);
