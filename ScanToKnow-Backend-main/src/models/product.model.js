//src/models/product.model.js

import mongoose from "mongoose";

const ProductSchema = new mongoose.Schema(
  {
    code: { type: String, unique: true },
    product_name: String,
    brand: String,

    variant_ids: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "ProductVariant"
      }
    ],

    flavor_tags: [String],
    curated: Boolean
  },
  { timestamps: true }
);

export default mongoose.model(
  "Product",
  ProductSchema,
  "products"
);
