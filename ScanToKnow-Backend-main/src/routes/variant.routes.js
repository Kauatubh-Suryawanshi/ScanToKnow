// // src/routes/variant.routes.js
// import express from "express";
// import * as ProductDetailController from "../controllers/productDetail.controller.js";

// const router = express.Router();

// // GET /v1/variants/:id -> variant-level detail
// router.get("/:id", ProductDetailController.getVariantDetail);

// export default router;

/**
 * src/routes/variant.routes.js
 * 
 * Routes for product variant operations.
 */

import express from "express";
import * as ProductDetailController from "../controllers/productDetail.controller.js";
import * as AlternativesController from "../controllers/alternatives.controller.js";

const router = express.Router();

/**
 * GET /v1/variants/:id
 * Get variant detail by ID
 */
router.get("/:id", ProductDetailController.getVariantDetail);

/**
 * GET /v1/variants/:id/alternatives
 * Get alternative recommendations for a variant
 */
router.get("/:id/alternatives", AlternativesController.getVariantAlternatives);

export default router;