//src/models/ingredient.model.js

import mongoose from "mongoose";

const IngredientSchema = new mongoose.Schema({
  canonical_name: { type: String, required: true },
  aliases: [String],
  description: String,
  health_rating: Number,
  source_tag: String,
  category: String
});

IngredientSchema.index({ canonical_name: 1 });
IngredientSchema.index({ aliases: 1 });

export default mongoose.model(
  "Ingredient",
  IngredientSchema,
  "ingredients"
);
