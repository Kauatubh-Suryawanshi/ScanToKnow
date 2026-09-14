/**
 * src/controllers/alternatives.controller.js
 * 
 * Controller for alternative product recommendations.
 */

import * as AlternativesService from '../services/alternatives/alternatives.service.js';

/**
 * GET /v1/variants/:id/alternatives
 * 
 * Query params:
 *   - limit (default: 5, max: 10)
 *   - include_fallback (default: true)
 */
export const getVariantAlternatives = async (req, res, next) => {
  try {
    const variantId = req.params.id;
    
    // Parse query params
    let limit = parseInt(req.query.limit) || 5;
    limit = Math.min(Math.max(1, limit), 10); // Clamp to 1-10

    const includeFallback = req.query.include_fallback !== 'false'; // Default true

    const result = await AlternativesService.getAlternatives(variantId, {
      limit,
      includeFallback
    });

    res.json(result);
  } catch (err) {
    if (err.message === 'Invalid variant ID' || err.message === 'Variant not found') {
      return res.status(404).json({ 
        status: 'error',
        error: err.message 
      });
    }
    next(err);
  }
};