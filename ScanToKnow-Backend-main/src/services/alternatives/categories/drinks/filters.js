/**
 * src/services/alternatives/categories/drinks/filters.js
 * 
 * Drinks-specific filter functions for alternative recommendations.
 */

import { PACKAGED_WATER_ID, EXCLUSION_MATRIX, PRIORITY_MATRIX } from './config.js';
import { getLevel2Category } from '../../core/engine.js';

/**
 * Check if alternative should be excluded due to water rule.
 * 
 * RULE: If current product is NOT water, exclude ALL water from alternatives.
 * EXCEPTION: If current IS water, other waters ARE valid alternatives.
 * 
 * @param {Object} currentProduct - Variant document
 * @param {Object} altProduct - Candidate variant document
 * @returns {boolean} true if should exclude
 */
export function shouldExcludeWater(currentProduct, altProduct) {
  const currentCats = (currentProduct.category_ids || []).map(String);
  const altCats = (altProduct.category_ids || []).map(String);

  const currentIsWater = currentCats.includes(PACKAGED_WATER_ID);
  const altIsWater = altCats.includes(PACKAGED_WATER_ID);

  // If current is NOT water, exclude water from alternatives
  if (!currentIsWater && altIsWater) {
    return true;
  }

  return false;
}

/**
 * Check if alternative should be excluded due to cross-category exclusion matrix.
 * 
 * @param {Object} currentProduct - Variant document
 * @param {Object} altProduct - Candidate variant document
 * @param {Array} allCategories - Full category collection
 * @returns {boolean} true if should exclude
 */
export function shouldExcludeByMatrix(currentProduct, altProduct, allCategories) {
  const currentL2 = getLevel2Category(currentProduct.category_ids, allCategories);
  const altL2 = getLevel2Category(altProduct.category_ids, allCategories);

  if (!currentL2 || !altL2) return false;

  const currentL2Str = String(currentL2);
  const altL2Str = String(altL2);

  // Check if current category has exclusion rules
  const excludedCategories = EXCLUSION_MATRIX[currentL2Str];
  if (!excludedCategories) return false;

  // Check if alternative's category is in the exclusion list
  return excludedCategories.some(excl => String(excl) === altL2Str);
}

/**
 * Apply category priority matrix to sort candidates.
 * Higher priority categories appear first, with health score as tie-breaker.
 * 
 * @param {Array} candidates - Already-ranked candidates
 * @param {Object} currentProduct - Variant document
 * @param {Array} allCategories - Full category collection
 * @returns {Array} Re-sorted candidates
 */
export function applyCategoryPriority(candidates, currentProduct, allCategories) {
  const currentL2 = getLevel2Category(currentProduct.category_ids, allCategories);
  if (!currentL2) return candidates;

  const currentL2Str = String(currentL2);
  const priorityOrder = PRIORITY_MATRIX[currentL2Str] || [];

  return candidates.sort((a, b) => {
    const aCat = getLevel2Category(a.product.category_ids, allCategories);
    const bCat = getLevel2Category(b.product.category_ids, allCategories);

    const aIndex = priorityOrder.indexOf(String(aCat));
    const bIndex = priorityOrder.indexOf(String(bCat));

    // Both in priority list: sort by priority index
    if (aIndex !== -1 && bIndex !== -1) {
      if (aIndex !== bIndex) return aIndex - bIndex;
    }

    // One in priority list, one not: prioritized one wins
    if (aIndex !== -1 && bIndex === -1) return -1;
    if (aIndex === -1 && bIndex !== -1) return 1;

    // Tie-break by rank score (already computed)
    return b.rankScore - a.rankScore;
  });
}