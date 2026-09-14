/**
 * src/services/cphs.service.js
 *
 * CPHS v2.5 — Comprehensive Product Health Score
 * Pure formula. Zero DB access. Zero side effects.
 *
 * Formula:
 *   CPHS = clamp( [ (0.6 × S_Nutri) + (0.4 × S_Ing) − P_Sugar ] × M_NOVA × M_Add , 0, 1 )
 *   Final score = round(CPHS × 100)
 *
 * Inputs (pre-loaded by caller, NOT fetched here):
 *   - variant        : raw productVariant document (plain object from .lean())
 *   - additivesMap   : Map<code_string, health_rating_number>
 *   - ingredientsMap : Map<ingredient_id_string, health_rating_number>
 *                      + Map<canonical_name_lower, health_rating_number>
 */

// ─── Constants ────────────────────────────────────────────────────────────────

/** Position weights for top-5 ingredients (index 0 = rank 1) */
const ING_WEIGHTS = [0.35, 0.30, 0.25, 0.07, 0.03];

/** NOVA group → processing multiplier */
const NOVA_MULTIPLIER = { 1: 1.00, 2: 0.95, 3: 0.90, 4: 0.75 };

/**
 * Fallback health_rating used when an ingredient or additive
 * is not found in either lookup map.
 * 65 = midpoint of Moderate Concern band — neither rewarded nor harshly penalized.
 */
const FALLBACK_RATING = 65;

// ─── Internal helpers ─────────────────────────────────────────────────────────

/**
 * Clamp a value between min and max (inclusive).
 */
function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

/**
 * Safe numeric parse for health_rating.
 * Handles Number, numeric String, null, undefined.
 * Returns FALLBACK_RATING if the value is missing or non-numeric.
 *
 * @param {*} raw
 * @returns {number}
 */
function safeRating(raw) {
  const n = parseFloat(raw);
  return Number.isFinite(n) ? clamp(n, 0, 100) : FALLBACK_RATING;
}

// ─── Component 1: S_Nutri ─────────────────────────────────────────────────────

/**
 * Fallback FSAm-NPS beverage algorithm.
 * Used ONLY when nutriscore_score_raw is null / undefined on the variant.
 *
 * Beverage-specific bad/good point tables (FSAm-NPS 2024 rules):
 *
 * Bad points:
 *   Energy   (kcal/100ml) : 0→0, ≤30→1, ≤60→2, ≤90→3, ≤120→4, ≤150→5,
 *                           ≤180→6, ≤210→7, ≤240→8, ≤270→9, >270→10
 *   Sugar    (g/100ml)    : 0→0, ≤1.5→1, ≤3→2, ≤4.5→3, ≤6→4, ≤7.5→5,
 *                           ≤9→6, ≤10.5→7, ≤12→8, ≤13.5→9, >13.5→10
 *   Sat fat  (g/100ml)    : 0→0, ≤1→1, ≤2→2, ≤3→3, ≤4→4, ≤5→5,
 *                           ≤6→6, ≤7→7, ≤8→8, ≤9→9, >9→10
 *   Sodium   (mg/100ml)   : 0→0, ≤90→1, ≤180→2, ≤270→3, ≤360→4, ≤450→5,
 *                           ≤540→6, ≤630→7, ≤720→8, ≤810→9, >810→10
 *   NNS penalty           : +4 if product contains non-nutritive sweeteners
 *                           (we cannot detect NNS from nutriments alone —
 *                            the caller sets this via hasNNS flag derived from additives)
 *
 * Good points:
 *   FV%  (fruit/veg %)    : 0→0, ≤40→1, ≤60→2, ≤80→3, ≤90→4, >90→5
 *   Fiber (g/100ml)       : 0→0, ≤0.9→1, ≤1.9→2, ≤2.8→3, ≤3.7→4, >3.7→5
 *   Protein (g/100ml)     : 0→0, ≤1.6→1, ≤3.2→2, ≤4.8→3, ≤6.4→4, >6.4→5
 *
 * @param {object} nutriments  - variant.nutriments
 * @param {boolean} hasNNS     - true if product contains sweetener additives (E950-E969 range)
 * @returns {number}           - raw FSAm-NPS score
 */
function calcNutriScoreRaw(nutriments, hasNNS) {
  const n = nutriments || {};

  // ── Bad points ──────────────────────────────────────────────
  const energy = n.energy_kcal_100g ?? 0;
  const sugar  = n.sugar_g_100g     ?? 0;
  const satFat = n.saturated_fat_g_100g ?? 0;
  // sodium_g_100g in the model is grams — convert to mg for the table
  const sodiumMg = (n.sodium_g_100g ?? (n.salt_g_100g ? n.salt_g_100g / 2.5 : 0)) * 1000;

  function energyPts(v) {
    if (v <= 0)   return 0; if (v <= 30)  return 1; if (v <= 60)  return 2;
    if (v <= 90)  return 3; if (v <= 120) return 4; if (v <= 150) return 5;
    if (v <= 180) return 6; if (v <= 210) return 7; if (v <= 240) return 8;
    if (v <= 270) return 9; return 10;
  }
  function sugarPts(v) {
    if (v <= 0)    return 0; if (v <= 1.5)  return 1; if (v <= 3)    return 2;
    if (v <= 4.5)  return 3; if (v <= 6)    return 4; if (v <= 7.5)  return 5;
    if (v <= 9)    return 6; if (v <= 10.5) return 7; if (v <= 12)   return 8;
    if (v <= 13.5) return 9; return 10;
  }
  function satFatPts(v) {
    if (v <= 0) return 0; if (v <= 1) return 1; if (v <= 2) return 2;
    if (v <= 3) return 3; if (v <= 4) return 4; if (v <= 5) return 5;
    if (v <= 6) return 6; if (v <= 7) return 7; if (v <= 8) return 8;
    if (v <= 9) return 9; return 10;
  }
  function sodiumPts(v) {
    if (v <= 0)   return 0; if (v <= 90)  return 1; if (v <= 180) return 2;
    if (v <= 270) return 3; if (v <= 360) return 4; if (v <= 450) return 5;
    if (v <= 540) return 6; if (v <= 630) return 7; if (v <= 720) return 8;
    if (v <= 810) return 9; return 10;
  }

  const badPoints =
    energyPts(energy) +
    sugarPts(sugar)   +
    satFatPts(satFat) +
    sodiumPts(sodiumMg) +
    (hasNNS ? 4 : 0);

  // ── Good points ─────────────────────────────────────────────
  const fvPct  = n.fruit_veg_pct ?? 0;
  const fiber  = n.fiber_g_100g  ?? 0;
  const protein = n.protein_g_100g ?? 0;

  function fvPts(v) {
    if (v <= 0)  return 0; if (v <= 40) return 1; if (v <= 60) return 2;
    if (v <= 80) return 3; if (v <= 90) return 4; return 5;
  }
  function fiberPts(v) {
    if (v <= 0)   return 0; if (v <= 0.9) return 1; if (v <= 1.9) return 2;
    if (v <= 2.8) return 3; if (v <= 3.7) return 4; return 5;
  }
  function proteinPts(v) {
    if (v <= 0)   return 0; if (v <= 1.6) return 1; if (v <= 3.2) return 2;
    if (v <= 4.8) return 3; if (v <= 6.4) return 4; return 5;
  }

  const goodPoints = fvPts(fvPct) + fiberPts(fiber) + proteinPts(protein);

  return badPoints - goodPoints;
}

/**
 * Normalize FSAm-NPS raw score to 0-1 scale.
 * Range: raw -15 (best) → +40 (worst)
 * S_Nutri = 1 − (raw + 15) / 55
 * Clamped to [0, 1].
 *
 * @param {number} raw
 * @returns {number}
 */
function normalizeNutriScore(raw) {
  return clamp(1 - (raw + 15) / 55, 0, 1);
}

/**
 * Calculate S_Nutri for a variant.
 * Prefers nutriscore_score_raw if present, falls back to FSAm-NPS calculation.
 *
 * @param {object} variant
 * @param {boolean} hasNNS
 * @returns {number} S_Nutri in [0, 1]
 */
function calcSNutri(variant, hasNNS) {
  const stored = variant.nutriscore_score_raw;
  const raw = (stored !== null && stored !== undefined && Number.isFinite(Number(stored)))
    ? Number(stored)
    : calcNutriScoreRaw(variant.nutriments, hasNNS);

  return normalizeNutriScore(raw);
}

// ─── Component 2: S_Ing ──────────────────────────────────────────────────────

/**
 * Resolve a single ingredient's health_rating from the lookup maps.
 *
 * Lookup order:
 *   1. ingredient_id → ingredientsMap (fastest, most reliable)
 *   2. name (lowercase) → ingredientsMap by canonical_name key
 *   3. FALLBACK_RATING
 *
 * @param {object} ingRef           - item from variant.ingredient_summary
 * @param {Map}    ingredientsMap   - pre-loaded map from computeCphs script
 * @returns {number}                - health_rating [0, 100]
 */
function resolveIngredientRating(ingRef, ingredientsMap) {
  // Path 1: by ObjectId string
  if (ingRef.ingredient_id) {
    const idKey = String(ingRef.ingredient_id);
    if (ingredientsMap.has(idKey)) {
      return safeRating(ingredientsMap.get(idKey));
    }
  }

  // Path 2: by name (canonical_name stored lowercase as key)
  if (ingRef.name) {
    const nameKey = ingRef.name.trim().toLowerCase();
    if (ingredientsMap.has(nameKey)) {
      return safeRating(ingredientsMap.get(nameKey));
    }
  }

  // Path 3: fallback
  return FALLBACK_RATING;
}

/**
 * Calculate S_Ing — ingredient quality score.
 *
 * Takes top 5 ingredients from ingredient_summary (already ordered by
 * percentage descending as stored in the DB).
 * quality = health_rating / 100
 * Weights are dynamically normalized if fewer than 5 ingredients exist.
 *
 * @param {Array}  ingredientSummary - variant.ingredient_summary
 * @param {Map}    ingredientsMap
 * @returns {number} S_Ing in [0, 1]
 */
function calcSIng(ingredientSummary, ingredientsMap) {
  const items = (ingredientSummary || []).slice(0, 5);

  if (items.length === 0) return FALLBACK_RATING / 100;

  const baseWeights = ING_WEIGHTS.slice(0, items.length);
  const totalWeight = baseWeights.reduce((s, w) => s + w, 0);

  let score = 0;
  for (let i = 0; i < items.length; i++) {
    const wNorm   = baseWeights[i] / totalWeight;   // dynamic normalization
    const rating  = resolveIngredientRating(items[i], ingredientsMap);
    const quality = rating / 100;
    score += wNorm * quality;
  }

  return clamp(score, 0, 1);
}

// ─── Component 3: P_Sugar ────────────────────────────────────────────────────

/**
 * Sugar penalty — piecewise linear (v2.5, same as v2.4).
 *
 * 0–5g    : 0.000
 * 5–10g   : (sugar − 5) × 0.015
 * 10–20g  : 0.075 + (sugar − 10) × 0.0175
 * >20g    : 0.250 (capped)
 *
 * @param {number} sugarG - sugar_g_100g
 * @returns {number} penalty in [0, 0.25]
 */
function calcPSugar(sugarG) {
  const s = sugarG ?? 0;
  if (s <= 5)  return 0;
  if (s <= 10) return (s - 5) * 0.015;
  if (s <= 20) return 0.075 + (s - 10) * 0.0175;
  return 0.25;
}

// ─── Component 4: M_NOVA ─────────────────────────────────────────────────────

/**
 * NOVA processing multiplier.
 * Unknown/missing NOVA → defaults to 0.75 (most conservative, assume UPF).
 *
 * @param {number} novaGroup
 * @returns {number}
 */
function calcMNova(novaGroup) {
  return NOVA_MULTIPLIER[novaGroup] ?? 0.75;
}

// ─── Component 5: M_Add ──────────────────────────────────────────────────────

/**
 * Additive safety multiplier — continuous numeric scale (NEW in v2.5).
 *
 * Formula: M_Add = clamp( 0.60 + (worstRating / 250) , 0.60 , 1.00 )
 *
 * Scale reference:
 *   worst=5   (E171 TiO₂)        → 0.620
 *   worst=10  (E955 Sucralose)   → 0.640
 *   worst=20  (E110 azo dye)     → 0.680
 *   worst=25  (E951 Aspartame)   → 0.700
 *   worst=40  (E211 Benzoate)    → 0.760
 *   worst=60  (E338 Phosphoric)  → 0.840
 *   worst=88  (E960 Stevia)      → 0.952
 *   worst=100 (E330 Citric)      → 1.000
 *   no additives                 → 1.000
 *
 * Uses ALL additives in the array — not just top 5.
 * A harmful additive at position 8 still penalizes the score.
 *
 * @param {Array} additivesArr  - variant.additives
 * @param {Map}   additivesMap  - pre-loaded Map<code, health_rating>
 * @returns {number} M_Add in [0.60, 1.00]
 */
function calcMAdd(additivesArr, additivesMap) {
  if (!additivesArr || additivesArr.length === 0) return 1.00;

  let worstRating = 100;

  for (const addRef of additivesArr) {
    const code = addRef.code || null;
    if (!code) continue;

    let rating = FALLBACK_RATING;

    if (additivesMap.has(code)) {
      rating = safeRating(additivesMap.get(code));
    }

    if (rating < worstRating) {
      worstRating = rating;
    }
  }

  return clamp(0.60 + (worstRating / 250), 0.60, 1.00);
}

// ─── NNS detection ───────────────────────────────────────────────────────────

/**
 * Detect if product contains non-nutritive sweeteners (NNS).
 * Used by the FSAm-NPS fallback to apply the +4 beverage penalty.
 *
 * NNS E-codes: E950–E969 range covers all approved artificial and natural
 * high-intensity sweeteners (Ace-K, Aspartame, Sucralose, Stevia, etc.)
 *
 * @param {Array} additivesArr
 * @returns {boolean}
 */
function detectNNS(additivesArr) {
  if (!additivesArr || additivesArr.length === 0) return false;

  const NNS_CODES = new Set([
    "E950", "E951", "E952", "E953", "E954", "E955",
    "E956", "E957", "E958", "E959", "E960", "E960a",
    "E961", "E962", "E963", "E964", "E965", "E966",
    "E967", "E968", "E969"
  ]);

  return additivesArr.some(a => a.code && NNS_CODES.has(a.code));
}

// ─── Health label + stars ─────────────────────────────────────────────────────

/**
 * Convert numeric CPHS score (0–100) to health_label and health_stars.
 *
 * Bands (5-tier):
 *   85–100 → very_good  ★★★★★
 *   60–84  → good       ★★★★
 *   40–59  → okay       ★★★
 *   20–39  → poor       ★★
 *   0–19   → very_poor  ★
 *
 * @param {number} score - integer 0-100
 * @returns {{ health_label: string, health_stars: number }}
 */
function scoreToLabel(score) {
  if (score >= 85) return { health_label: "very_good",  health_stars: 5 };
  if (score >= 60) return { health_label: "good",       health_stars: 4 };
  if (score >= 40) return { health_label: "okay",       health_stars: 3 };
  if (score >= 20) return { health_label: "poor",       health_stars: 2 };
  return             { health_label: "very_poor",   health_stars: 1 };
}

// ─── Main exported function ───────────────────────────────────────────────────

/**
 * calculateCPHS — CPHS v2.5 master function.
 *
 * @param {object} variant
 *   Raw productVariant document from MongoDB (.lean() result).
 *   Required fields:
 *     - nutriscore_score_raw   {number|null}
 *     - nutriments             {object}
 *     - nova_group             {number}
 *     - ingredient_summary     {Array}
 *     - additives              {Array}
 *
 * @param {Map} additivesMap
 *   Map<code_string, health_rating_number>
 *   Built once by the caller (computeCphs.js) from fooddb.additives.
 *   Key   : additive code, e.g. "E110"
 *   Value : health_rating as number, e.g. 20
 *
 * @param {Map} ingredientsMap
 *   Map with TWO key types for dual-path lookup:
 *   Key type A : ObjectId string → health_rating number
 *   Key type B : canonical_name lowercase → health_rating number
 *   Built once by the caller from fooddb.ingredients.
 *
 * @returns {{
 *   cphs_final:    number,   // raw ratio [0, 1], 3 decimal places
 *   cphs_score:    number,   // integer [0, 100]
 *   health_label:  string,   // "very_good" | "good" | "okay" | "poor" | "very_poor"
 *   health_stars:  number,   // 1 | 2 | 3 | 4 | 5
 *   breakdown: {             // useful for debugging / logging
 *     S_Nutri:  number,
 *     S_Ing:    number,
 *     P_Sugar:  number,
 *     base:     number,
 *     M_NOVA:   number,
 *     M_Add:    number,
 *     nutriscore_raw_used: number
 *   }
 * }}
 */
export function calculateCPHS(variant, additivesMap, ingredientsMap) {
  const additivesArr      = variant.additives         || [];
  const ingredientSummary = variant.ingredient_summary || [];

  // ── Detect NNS for nutriscore fallback ──────────────────────
  const hasNNS = detectNNS(additivesArr);

  // ── Component 1: S_Nutri ────────────────────────────────────
  const S_Nutri = calcSNutri(variant, hasNNS);

  // ── Component 2: S_Ing ──────────────────────────────────────
  const S_Ing = calcSIng(ingredientSummary, ingredientsMap);

  // ── Component 3: P_Sugar ────────────────────────────────────
  const P_Sugar = calcPSugar(variant.nutriments?.sugar_g_100g);

  // ── Base score ──────────────────────────────────────────────
  const base = Math.max(0, (0.6 * S_Nutri) + (0.4 * S_Ing) - P_Sugar);

  // ── Component 4: M_NOVA ─────────────────────────────────────
  const M_NOVA = calcMNova(variant.nova_group);

  // ── Component 5: M_Add ──────────────────────────────────────
  const M_Add = calcMAdd(additivesArr, additivesMap);

  // ── Final score ─────────────────────────────────────────────
  const rawRatio   = clamp(base * M_NOVA * M_Add, 0, 1);
  const cphs_final = Math.round(rawRatio * 1000) / 1000;   // 3 decimal places
  const cphs_score = Math.round(rawRatio * 100);            // integer 0-100

  const { health_label, health_stars } = scoreToLabel(cphs_score);

  // ── Nutriscore raw used (for breakdown transparency) ─────────
  const stored = variant.nutriscore_score_raw;
  const nutriscore_raw_used =
    (stored !== null && stored !== undefined && Number.isFinite(Number(stored)))
      ? Number(stored)
      : calcNutriScoreRaw(variant.nutriments, hasNNS);

  return {
    cphs_final,
    cphs_score,
    health_label,
    health_stars,
    breakdown: {
      S_Nutri:             Math.round(S_Nutri * 1000) / 1000,
      S_Ing:               Math.round(S_Ing   * 1000) / 1000,
      P_Sugar:             Math.round(P_Sugar  * 1000) / 1000,
      base:                Math.round(base     * 1000) / 1000,
      M_NOVA,
      M_Add:               Math.round(M_Add    * 1000) / 1000,
      nutriscore_raw_used
    }
  };
}