/**
 * src/services/alternatives/core/engine.js
 * 
 * Category-agnostic core logic for alternative recommendations.
 * Reusable across all top-level categories (Drinks, Chocolates, etc.)
 */

import mongoose from "mongoose";

/**
 * Convert cphs_final (0-1 decimal) to cphs_score (0-100 integer).
 */
export function toCphsScore(cphsFinal) {
  if (cphsFinal == null) return 0;
  const num = typeof cphsFinal === 'number' ? cphsFinal : parseFloat(cphsFinal);
  if (isNaN(num)) return 0;
  return Math.round(num * 100);
}

/**
 * Determine recommendation mode based on current product's health label.
 * Returns { mode, minScore, message, showAlternatives }
 */
export function getRecommendationMode(healthLabel, cphsScore) {
  const label = (healthLabel || 'poor').toLowerCase();

  switch (label) {
    case 'very_poor':
      return {
        mode: 'avoid',
        minScore: 60,
        message: '⚠️ This product scores very poorly. We strongly recommend these healthier options.',
        showAlternatives: true
      };

    case 'poor':
      return {
        mode: 'better_alternatives',
        minScore: 60,
        message: 'This product has significant health concerns. Consider these better options.',
        showAlternatives: true
      };

    case 'okay':
      return {
        mode: 'safe_choices',
        minScore: 60,
        message: 'This product is acceptable, but here are some healthier options if you\'d like to explore.',
        showAlternatives: true
      };

    case 'good':
      return {
        mode: 'premium_options',
        minScore: 85,
        message: 'This is already a good choice. These premium options score even higher.',
        showAlternatives: true,  // Only if Very Good exists
        requiresVeryGood: true
      };

    case 'very_good':
      return {
        mode: 'excellent_choice',
        minScore: null,
        message: 'Excellent choice! This product is among the healthiest options available.',
        showAlternatives: false,  // Or show similar Very Good for variety
        showSimilar: true
      };

    default:
      return {
        mode: 'better_alternatives',
        minScore: 60,
        message: 'Consider these healthier alternatives.',
        showAlternatives: true
      };
  }
}

/**
 * Extract the top-level (level 1) category from a product's category_ids.
 * Traverses up the category tree if needed.
 * 
 * @param {Array} categoryIds - Array of ObjectId refs from product.category_ids
 * @param {Array} allCategories - Full category collection (lean())
 * @returns {ObjectId|null}
 */
export function getTopLevelCategory(categoryIds, allCategories) {
  if (!categoryIds || !categoryIds.length) return null;

  for (const id of categoryIds) {
    const idStr = String(id);
    
    // Check if this category is level 1
    const cat = allCategories.find(c => String(c._id) === idStr);
    if (cat && cat.level === 1) return cat._id;

    // If level 2+, traverse up to find parent
    if (cat && cat.parent_id) {
      const parent = allCategories.find(c => String(c._id) === String(cat.parent_id));
      if (parent && parent.level === 1) return parent._id;
    }
  }

  return null;
}

/**
 * Get the primary level-2 category (subcategory) from category_ids.
 * Used for same-subcategory affinity scoring.
 */
export function getLevel2Category(categoryIds, allCategories) {
  if (!categoryIds || !categoryIds.length) return null;

  for (const id of categoryIds) {
    const idStr = String(id);
    const cat = allCategories.find(c => String(c._id) === idStr);
    if (cat && cat.level === 2) return cat._id;
  }

  return null;
}

/**
 * Calculate category affinity bonus for ranking.
 * Same subcategory > Sibling subcategory > Cousin subcategory
 * 
 * @returns {number} 100-300 bonus points
 */
export function getCategoryAffinityBonus(currentProduct, altProduct, allCategories) {
  const currentCats = new Set(currentProduct.category_ids.map(String));
  const altCats = new Set(altProduct.category_ids.map(String));

  // Perfect match: same category_id (same subcategory)
  const intersection = [...currentCats].filter(id => altCats.has(id));
  if (intersection.length > 0) return 300;

  // Sibling match: different level-2 categories but same level-1 parent
  const currentL2 = getLevel2Category(currentProduct.category_ids, allCategories);
  const altL2 = getLevel2Category(altProduct.category_ids, allCategories);

  if (currentL2 && altL2 && String(currentL2) !== String(altL2)) {
    // Check if they share same parent
    const currentL2Cat = allCategories.find(c => String(c._id) === String(currentL2));
    const altL2Cat = allCategories.find(c => String(c._id) === String(altL2));
    
    if (currentL2Cat && altL2Cat && 
        currentL2Cat.parent_id && 
        String(currentL2Cat.parent_id) === String(altL2Cat.parent_id)) {
      return 200;
    }
  }

  // Cousin match: same level-1 but different branch
  return 100;
}

/**
 * Rank candidates using multi-factor scoring.
 * Formula: (health_score * 10) + category_affinity_bonus + brand_bonus
 * 
 * @param {Array} candidates - Pre-filtered products
 * @param {Object} currentProduct - The product being viewed
 * @param {Array} allCategories - Full category list
 * @returns {Array} Sorted array of { product, rankScore }
 */
export function rankCandidates(candidates, currentProduct, allCategories) {
  return candidates.map(alt => {
    let score = 0;

    // Factor 1: Health score (0-1000 points)
    const altScore = toCphsScore(alt.cphs_final);
    score += altScore * 10;  // 85 → 850, 100 → 1000

    // Factor 2: Category affinity (0-300 points)
    const affinityBonus = getCategoryAffinityBonus(currentProduct, alt, allCategories);
    score += affinityBonus;

    // Factor 3: Brand affinity (0-100 points)
    if (alt.brand?.name && currentProduct.brand?.name &&
        alt.brand.name === currentProduct.brand.name) {
      score += 100;
    }

    return {
      product: alt,
      rankScore: score,
      cphs_score: altScore,
      affinity: affinityBonus
    };
  }).sort((a, b) => b.rankScore - a.rankScore);
}

/**
 * Build a lightweight DTO for alternative product display.
 */
export function buildAlternativeDTO(rankedItem, allCategories) {
  const p = rankedItem.product;
  
  // Determine category match type
  let categoryMatch = 'cousin';
  if (rankedItem.affinity === 300) categoryMatch = 'same';
  else if (rankedItem.affinity === 200) categoryMatch = 'sibling';

  // Get primary level-2 category name
  const l2Cat = getLevel2Category(p.category_ids, allCategories);
  const l2CatDoc = l2Cat ? allCategories.find(c => String(c._id) === String(l2Cat)) : null;

  return {
    id: p._id,
    title: p.title,
    brand: p.brand?.name || null,
    cphs_score: rankedItem.cphs_score,
    cphs_final: p.cphs_final,
    health_label: p.health_label,
    health_stars: p.health_stars,
    category_match: categoryMatch,
    category_name: l2CatDoc ? l2CatDoc.name : null,
    rank_score: rankedItem.rankScore,
    images: p.images || {},
    quantity_value: p.quantity_value,
    quantity_unit: p.quantity_unit
  };
}