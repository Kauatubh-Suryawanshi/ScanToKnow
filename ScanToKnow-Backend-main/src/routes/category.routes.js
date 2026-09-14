// src/routes/category.routes.js
import express from "express";
import * as CategoryController from "../controllers/category.controller.js";

const router = express.Router();

// List categories (used for top categories & View All)
router.get("/", CategoryController.listCategories);

// Get single category by slug or id
router.get("/:id", CategoryController.getCategory);

// Get immediate children (subcategories)
router.get("/:id/children", CategoryController.getChildren);

// Get products under category (descendants included)
router.get("/:id/products", CategoryController.getProductsForCategory);

export default router;
