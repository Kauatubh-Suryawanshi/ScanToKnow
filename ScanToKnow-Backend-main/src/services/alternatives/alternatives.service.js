/**
 * src/services/alternatives/alternatives.service.js
 * 
 * Main alternatives service - routes to category-specific modules.
 * This is the public API used by controllers.
 */

import ProductVariant from '../../models/productVariant.model.js';
import Category from '../../models/category.model.js';
import mongoose from 'mongoose';
import { getTopLevelCategory, toCphsScore } from './core/engine.js';
import { getDrinksAlternatives } from './categories/drinks/index.js';
import { DRINKS_CATEGORY_ID } from './categories/drinks/config.js';

/**
 * Get alternative recommendations for a product variant.
 * 
 * @param {string} variantId - Product variant _id
 * @param {Object} options - { limit: 5, includeFallback: true }
 * @returns {Promise<Object>} Alternatives response object
 */
export async function getAlternatives(variantId, options = {}) {
  const { limit = 5, includeFallback = true } = options;

  // Validate and fetch current product
  if (!mongoose.Types.ObjectId.isValid(variantId)) {
    throw new Error('Invalid variant ID');
  }

  const currentProduct = await ProductVariant.findById(variantId)
    .select('_id title brand category_ids cphs_final health_label health_stars images quantity_value quantity_unit')
    .lean();

  if (!currentProduct) {
    throw new Error('Variant not found');
  }

  // Load all categories (cached in production)
  const allCategories = await Category.find({}).lean();

  // Determine top-level category
  const topCat = getTopLevelCategory(currentProduct.category_ids, allCategories);
  
  if (!topCat) {
    return buildEmptyResponse(currentProduct, 'Product has no valid category');
  }

  const topCatStr = String(topCat);

  // Route to category-specific module
  let result;

  if (topCatStr === DRINKS_CATEGORY_ID) {
    result = await getDrinksAlternatives(currentProduct, allCategories, { limit, includeFallback });
  } else {
    // Future: Add chocolates, snacks, etc.
    return buildEmptyResponse(currentProduct, 'Alternatives not yet available for this category');
  }

  // Build final response
  return {
    status: 'ok',
    data: {
      current_product: {
        id: currentProduct._id,
        title: currentProduct.title,
        brand: currentProduct.brand?.name || null,
        cphs_score: toCphsScore(currentProduct.cphs_final),
        cphs_final: currentProduct.cphs_final,
        health_label: currentProduct.health_label,
        health_stars: currentProduct.health_stars,
        images: currentProduct.images
      },
      recommendation_mode: result.mode,
      message: result.message,
      alternatives: result.alternatives,
      fallback_used: result.fallbackUsed,
      total_candidates: result.totalCandidates,
      shown: result.alternatives.length
    }
  };
}

/**
 * Build empty response when no alternatives can be computed.
 */
function buildEmptyResponse(currentProduct, reason) {
  return {
    status: 'ok',
    data: {
      current_product: {
        id: currentProduct._id,
        title: currentProduct.title,
        brand: currentProduct.brand?.name || null,
        cphs_score: toCphsScore(currentProduct.cphs_final),
        cphs_final: currentProduct.cphs_final,
        health_label: currentProduct.health_label,
        health_stars: currentProduct.health_stars,
        images: currentProduct.images
      },
      recommendation_mode: 'unavailable',
      message: reason || 'No alternatives available for this product.',
      alternatives: [],
      fallback_used: false,
      total_candidates: 0,
      shown: 0
    }
  };
}