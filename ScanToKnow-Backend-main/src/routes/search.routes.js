//src/routes/search.routes.js

import express from "express";
import * as SearchController from "../controllers/search.controller.js";

const router = express.Router();

// Autocomplete (typing)
router.get("/autocomplete", SearchController.autocomplete);

// Full search (Enter pressed)
router.get("/", SearchController.search);

export default router;
