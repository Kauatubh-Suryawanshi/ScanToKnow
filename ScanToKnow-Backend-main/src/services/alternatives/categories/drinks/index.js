/**
 * src/services/alternatives/categories/drinks/index.js
 * 
 * Drinks alternatives module - entry point.
 * Implements the full alternative recommendation flow for beverages.
 */

import ProductVariant from '../../../../models/productVariant.model.js';
import {
  getRecommendationMode,
  getTopLevelCategory,
  toCphsScore,
  rankCandidates,
  buildAlternativeDTO
} from '../../core/engine.js';
import {
  shouldExcludeWater,
  shouldExcludeByMatrix,
  applyCategoryPriority
} from './filters.js';
import { DRINKS_CATEGORY_ID, FALLBACK_CONFIG } from './config.js';

/**
 * Get alternative recommendations for a drinks product.
 * 
 * @param {Object} currentProduct - Variant document (lean)
 * @param {Array} allCategories - Full category collection (lean)
 * @param {Object} options - { limit: 5, includeFallback: true }
 * @returns {Object} { mode, message, alternatives, fallbackUsed, totalCandidates }
 */
export async function getDrinksAlternatives(currentProduct, allCategories, options = {}) {
  const { limit = 5, includeFallback = true } = options;

  // Validate that current product is in Drinks category
  const topCat = getTopLevelCategory(currentProduct.category_ids, allCategories);
  if (String(topCat) !== DRINKS_CATEGORY_ID) {
    throw new Error('Product is not in Drinks category');
  }

  const currentScore = toCphsScore(currentProduct.cphs_final);
  const healthLabel = currentProduct.health_label;

  // Determine recommendation mode
  const recMode = getRecommendationMode(healthLabel, currentScore);

  // Special case: Very Good products show nothing or similar products
  if (recMode.mode === 'excellent_choice') {
    return {
      mode: recMode.mode,
      message: recMode.message,
      alternatives: [],
      fallbackUsed: false,
      totalCandidates: 0
    };
  }

  // Phase 1: Filter candidates
  let candidates = await filterCandidates(
    currentProduct,
    allCategories,
    recMode.minScore,
    currentScore
  );

  let fallbackUsed = false;

  // Fallback: Relax to Okay tier if zero candidates and fallback allowed
  if (candidates.length === 0 && 
      (healthLabel === 'very_poor' || healthLabel === 'poor') &&
      includeFallback &&
      FALLBACK_CONFIG.allowOkayFallback) {
    
    candidates = await filterCandidates(
      currentProduct,
      allCategories,
      40, // Okay tier minimum
      currentScore
    );

    if (candidates.length > 0) {
      fallbackUsed = true;
    }
  }

  // Phase 2: Rank candidates (multi-factor scoring)
  const ranked = rankCandidates(candidates, currentProduct, allCategories);

  // Phase 3: Apply category priority matrix
  const sorted = applyCategoryPriority(ranked, currentProduct, allCategories);

  // Phase 4: Take top N
  const topAlternatives = sorted.slice(0, limit);

  // Phase 5: Build DTOs
  const alternativeDTOs = topAlternatives.map(item => 
    buildAlternativeDTO(item, allCategories)
  );

  return {
    mode: recMode.mode,
    message: fallbackUsed ? FALLBACK_CONFIG.fallbackMessage : recMode.message,
    alternatives: alternativeDTOs,
    fallbackUsed,
    totalCandidates: sorted.length
  };
}

/**
 * Filter candidates from database.
 * Applies all constraints: score threshold, top-level category, water exclusion, matrix exclusion.
 */
async function filterCandidates(currentProduct, allCategories, minScore, currentScore) {
  const topCat = getTopLevelCategory(currentProduct.category_ids, allCategories);
  
  // Query: Get all products in same top-level category
  const query = {
    category_ids: { $in: allCategories.filter(c => String(c.parent_id) === String(topCat)).map(c => c._id) },
    cphs_final: { $exists: true, $ne: null }
  };

  const allProducts = await ProductVariant.find(query)
    .select('_id title brand category_ids cphs_final health_label health_stars images quantity_value quantity_unit')
    .lean();

  const candidates = [];

  for (const product of allProducts) {
    // Skip self
    if (String(product._id) === String(currentProduct._id)) continue;

    const altScore = toCphsScore(product.cphs_final);

    // Must have higher score than current
    if (altScore <= currentScore) continue;

    // Must meet minimum threshold
    if (altScore < minScore) continue;

    // Must be in same top-level category (already filtered by query, but double-check)
    const altTopCat = getTopLevelCategory(product.category_ids, allCategories);
    if (String(altTopCat) !== String(topCat)) continue;

    // Water exclusion
    if (shouldExcludeWater(currentProduct, product)) continue;

    // Cross-category exclusion matrix
    if (shouldExcludeByMatrix(currentProduct, product, allCategories)) continue;

    candidates.push(product);
  }

  return candidates;
}