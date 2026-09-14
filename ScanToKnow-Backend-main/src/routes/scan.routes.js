// src/routes/scan.routes.js
import express from "express";
import * as ScanController from "../controllers/scan.controller.js";

const router = express.Router();

// GET /v1/scan/:barcode
router.get("/:barcode", ScanController.scanByBarcode);

export default router;
