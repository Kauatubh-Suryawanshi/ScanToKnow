// src/models/category.model.js

import mongoose from "mongoose";

const categorySchema = new mongoose.Schema(
  {
    code: {
      type: String,
      required: true,
      unique: true,
      trim: true
    },

    name: {
      type: String,
      required: true,
      trim: true
    },

    slug: {
      type: String,
      required: true,
      lowercase: true,
      trim: true,
      index: true
    },

    description: {
      type: String,
      default: null
    },

    parent_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Category",
      default: null,
      index: true
    },

    level: {
      type: Number,
      required: true,
      default: 1,
      index: true
    },

    /**
     * Materialized path
     * Example: ",drinks,carbonated-soft-drinks,"
     */
    path: {
      type: String,
      required: true,
      index: true
    },

    display_order: {
      type: Number,
      default: 0,
      index: true
    },

    icon: {
      type: String,
      default: null
    }
  },
  {
    timestamps: true
  }
);

// Helpful compound indexes
categorySchema.index({ parent_id: 1, display_order: 1 });
categorySchema.index({ path: 1 });
categorySchema.index({ slug: 1 });
categorySchema.index({ code: 1 });

const Category = mongoose.model("Category", categorySchema);
export default Category;
