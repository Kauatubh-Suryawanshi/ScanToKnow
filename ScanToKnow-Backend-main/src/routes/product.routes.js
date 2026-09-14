// src/routes/product.routes.js
import express from "express";
import * as ProductController from "../controllers/product.controller.js"; // your listing controller
import * as ProductDetailController from "../controllers/productDetail.controller.js";

const router = express.Router();

// GET /v1/products?category=...
router.get("/", ProductController.listProducts);

// GET /v1/products/:id  -> product detail (parent product + variants)
router.get("/:id", ProductDetailController.getProductDetail);

export default router;
