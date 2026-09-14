/**
 * src/services/alternatives/categories/drinks/config.js
 * 
 * Drinks-specific business rules for alternative recommendations.
 * This config defines exclusions, priorities, and constraints unique to beverages.
 */

/**
 * PACKAGED WATER CATEGORY ID
 * This is the only category explicitly excluded from alternatives when current product is NOT water.
 */
export const PACKAGED_WATER_ID = '693da2f9f529466d1dfed8ec';

/**
 * CROSS-CATEGORY EXCLUSION MATRIX
 * Key: Current product's level-2 category ID
 * Value: Array of level-2 category IDs to EXCLUDE from alternatives
 * 
 * Rationale: Certain beverage categories serve fundamentally different use cases
 * and should not be suggested as alternatives for each other.
 */
export const EXCLUSION_MATRIX = {
  // Dairy-Based Beverages → exclude Carbonated, Energy, Mixers
  '693da2f9f529466d1dfed8eb': [
    '693da2f9f529466d1dfed8e3', // Carbonated Soft Drinks
    '693da2f9f529466d1dfed8e6', // Energy & Sports Drinks
    '693da2f9f529466d1dfed8e8',  // Cocktail Mixers & Tonics
    '693da2f9f529466d1dfed8ea', // Functional & Wellness Juices
    '693da2f9f529466d1dfed8e1'  // 100% Fruit Juices
    
  ],

  // Carbonated Soft Drinks → exclude Dairy, Water
  '693da2f9f529466d1dfed8e3': [
    '693da2f9f529466d1dfed8eb', // Dairy-Based Beverages
    '693da2f9f529466d1dfed8ec'  // Packaged Waters
  ],

  // Energy & Sports Drinks → exclude Dairy, Ethnic Still
  '693da2f9f529466d1dfed8e6': [
    '693da2f9f529466d1dfed8eb', // Dairy-Based Beverages
    '693da2f9f529466d1dfed8e5'  // Ethnic Still Beverages
  ],

  // Cocktail Mixers & Tonics → exclude Dairy, 100% Juices
  '693da2f9f529466d1dfed8e8': [
    '693da2f9f529466d1dfed8eb', // Dairy-Based Beverages
    '693da2f9f529466d1dfed8e1'  // 100% Fruit Juices
  ],

  // Ethnic Still Beverages (lassi, chaas) → exclude Carbonated, Energy, Mixers
  '693da2f9f529466d1dfed8e5': [
    '693da2f9f529466d1dfed8e3', // Carbonated Soft Drinks
    '693da2f9f529466d1dfed8e6', // Energy & Sports Drinks
    '693da2f9f529466d1dfed8e8'  // Cocktail Mixers & Tonics
    ],
  // Packaged Waters → exclude Carbonated, Energy, Mixers, Ethnic Still, Dairy, 100% Juices, Functional Juices, Fruit Drinks, but allow other waters
  '693da2f9f529466d1dfed8ec': [
    '693da2f9f529466d1dfed8e3', // Carbonated Soft Drinks
    '693da2f9f529466d1dfed8e6', // Energy & Sports Drinks
    '693da2f9f529466d1dfed8e8', // Cocktail Mixers & Tonics
      '693da2f9f529466d1dfed8e4', // Indian Sparkling & Masala Sodas
    '693da2f9f529466d1dfed8e9', //Concentrates & Instant Mixes 
    '693da2f9f529466d1dfed8e7',// Non-Alcoholic Malts & Beers
    '693da2f9f529466d1dfed8e5', // Ethnic Still Beverages
    '693da2f9f529466d1dfed8eb', // Dairy-Based Beverages
    '693da2f9f529466d1dfed8e1', // 100% Fruit Juices
    '693da2f9f529466d1dfed8ea', // Functional & Wellness Juices
    '693da2f9f529466d1dfed8e2'  // Fruit Drinks & Nectars
  ]
};

/**
 * CATEGORY PRIORITY MATRIX
 * When alternatives exist in multiple subcategories, use this order to rank them.
 * 
 * Key: Current product's level-2 category ID
 * Value: Ordered array of level-2 category IDs (highest priority first)
 * 
 * Note: Same-category match (position 0) is ALWAYS highest priority.
 * This matrix only applies when showing cross-category alternatives.
 */
export const PRIORITY_MATRIX = {
  // Carbonated Soft Drinks
  '693da2f9f529466d1dfed8e3': [
    '693da2f9f529466d1dfed8e3', // Same (Carbonated)
    '693da2f9f529466d1dfed8ea', // Functional & Wellness Juices
    '693da2f9f529466d1dfed8e1', // 100% Fruit Juices
    '693da2f9f529466d1dfed8e2'  // Fruit Drinks & Nectars
  ],

  // Fruit Drinks & Nectars
  '693da2f9f529466d1dfed8e2': [
    '693da2f9f529466d1dfed8e2', // Same (Fruit Drinks)
    '693da2f9f529466d1dfed8e1', // 100% Fruit Juices
    '693da2f9f529466d1dfed8ea', // Functional & Wellness Juices
    '693da2f9f529466d1dfed8e5'  // Ethnic Still Beverages
  ],

  // Dairy-Based Beverages
  '693da2f9f529466d1dfed8eb': [
    '693da2f9f529466d1dfed8eb' // Same (Dairy)
    // '693da2f9f529466d1dfed8ea', // Functional & Wellness Juices
    // '693da2f9f529466d1dfed8e1'  // 100% Fruit Juices
  ],

  // Energy & Sports Drinks
  '693da2f9f529466d1dfed8e6': [
    '693da2f9f529466d1dfed8e6', // Same (Energy)
    '693da2f9f529466d1dfed8ea', // Functional & Wellness Juices
    '693da2f9f529466d1dfed8e1'  // 100% Fruit Juices
  ],

  // 100% Fruit Juices
  '693da2f9f529466d1dfed8e1': [
    '693da2f9f529466d1dfed8e1', // Same (100% Juice)
    '693da2f9f529466d1dfed8ea'  // Functional & Wellness Juices
  ],

  // Ethnic Still Beverages
  '693da2f9f529466d1dfed8e5': [
    '693da2f9f529466d1dfed8e5', // Same (Ethnic Still)
    '693da2f9f529466d1dfed8ea', // Functional & Wellness Juices
    '693da2f9f529466d1dfed8e1'  // 100% Fruit Juices
  ],

  // Functional & Wellness Juices (already premium category)
  '693da2f9f529466d1dfed8ea': [
    '693da2f9f529466d1dfed8ea', // Same (Wellness)
    '693da2f9f529466d1dfed8e1'  // 100% Fruit Juices
  ],

  // Packaged Waters (compare waters to waters only)
  '693da2f9f529466d1dfed8ec': [
    '693da2f9f529466d1dfed8ec'  // Same (Waters only)
  ]
};

/**
 * FALLBACK CONFIGURATION
 * Whether to allow relaxing score thresholds when no ideal alternatives exist.
 */
export const FALLBACK_CONFIG = {
  // Allow showing Okay-tier (40-59) when Poor/Very Poor product has no Good/Very Good alternatives
  allowOkayFallback: true,

  // Fallback message template
  fallbackMessage: '⚠️ No ideal alternatives found. We couldn\'t find healthier options in this category that meet our quality threshold. These products score slightly better but may still have concerns. We\'re continuously adding new products to our database. Check back soon!'
};

/**
 * TOP-LEVEL CATEGORY ID (Drinks)
 * Used for validation and category isolation.
 */
export const DRINKS_CATEGORY_ID = '693da2f9f529466d1dfed8e0';