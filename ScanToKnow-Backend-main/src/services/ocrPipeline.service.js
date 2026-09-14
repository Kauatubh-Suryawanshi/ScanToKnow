/* OCR parsing + database-backed ingredient/additive resolution. */

import Ingredient from "../models/ingredient.model.js";
import Additive from "../models/additive.model.js";
import { extractIngredientsAndAdditives } from "./ingredientExtractor.service.js";

const CACHE_TTL_MS = 5 * 60 * 1000;
let dictionaryCache = null;

function levenshtein(a, b) {
  const prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i += 1) {
    let prevDiagonal = prev[0];
    prev[0] = i;
    for (let j = 1; j <= b.length; j += 1) {
      const saved = prev[j];
      prev[j] = a[i - 1] === b[j - 1]
        ? prevDiagonal
        : 1 + Math.min(prev[j], prev[j - 1], prevDiagonal);
      prevDiagonal = saved;
    }
  }
  return prev[b.length];
}

function normalize(value) {
  return String(value ?? "").trim().toLowerCase();
}

function resolveHealthInfo(doc) {
  const parsed = Number.parseInt(String(doc.health_rating ?? ""), 10);
  const rating = Number.isFinite(parsed) ? Math.max(0, Math.min(100, parsed)) : null;

  if (rating === null) {
    return { health_rating: null, health_label: "unknown", health_color: "grey" };
  }
  if (rating >= 85) return { health_rating: rating, health_label: "very_good", health_color: "green" };
  if (rating >= 60) return { health_rating: rating, health_label: "good", health_color: "green" };
  if (rating >= 40) return { health_rating: rating, health_label: "okay", health_color: "yellow" };
  if (rating >= 20) return { health_rating: rating, health_label: "poor", health_color: "orange" };
  return { health_rating: rating, health_label: "very_poor", health_color: "red" };
}

async function loadDictionary() {
  const now = Date.now();
  if (dictionaryCache && now - dictionaryCache.loadedAt < CACHE_TTL_MS) {
    return dictionaryCache;
  }

  const [allAdditives, allIngredients] = await Promise.all([
    Additive.find({}).lean(),
    Ingredient.find({}).lean(),
  ]);

  const additivesByCode = new Map();
  const additiveNames = new Map();
  const additiveSynonyms = new Map();
  const ingredientsById = new Map();
  const ingredientNames = new Map();
  const ingredientAliases = new Map();

  for (const add of allAdditives) {
    if (add.code) additivesByCode.set(normalize(add.code), add);
    if (add.name) additiveNames.set(normalize(add.name), add);
    for (const synonym of add.synonyms || []) {
      const key = normalize(synonym);
      if (key) additiveSynonyms.set(key, add);
    }
  }

  for (const ingredient of allIngredients) {
    ingredientsById.set(String(ingredient._id), ingredient);
    if (ingredient.canonical_name) {
      ingredientNames.set(normalize(ingredient.canonical_name), ingredient);
    }
    for (const alias of ingredient.aliases || []) {
      const key = normalize(alias);
      if (key) ingredientAliases.set(key, ingredient);
    }
  }

  dictionaryCache = {
    loadedAt: now,
    allAdditives,
    allIngredients,
    additivesByCode,
    additiveNames,
    additiveSynonyms,
    ingredientsById,
    ingredientNames,
    ingredientAliases,
  };

  return dictionaryCache;
}

export function clearOCRDictionaryCache() {
  dictionaryCache = null;
}

function matchSingleName(nameLower, dictionary) {
  const exactAdditiveSynonym = dictionary.additiveSynonyms.get(nameLower);
  if (exactAdditiveSynonym) return { type: "additive", doc: exactAdditiveSynonym };

  const exactAdditive = dictionary.additiveNames.get(nameLower);
  if (exactAdditive) return { type: "additive", doc: exactAdditive };

  const exactIngredient = dictionary.ingredientNames.get(nameLower);
  if (exactIngredient) return { type: "ingredient", doc: exactIngredient };

  const exactAlias = dictionary.ingredientAliases.get(nameLower);
  if (exactAlias) return { type: "ingredient", doc: exactAlias };

  const nameWords = nameLower.split(/\s+/).filter(Boolean);
  for (const ingredient of dictionary.allIngredients) {
    const canonical = normalize(ingredient.canonical_name);
    const aliases = (ingredient.aliases || []).map(normalize);
    const containsMatch =
      (canonical.length > 3 && canonical.split(/\s+/).every((w) => nameLower.includes(w))) ||
      aliases.some((alias) =>
        (alias.length > 3 && alias.split(/\s+/).every((w) => nameLower.includes(w))) ||
        nameWords.every((w) => alias.includes(w))
      );
    if (containsMatch) return { type: "ingredient", doc: ingredient };
  }

  if (nameLower.length <= 25) {
    const maxDist = nameLower.length <= 10 ? 2 : 3;
    let best = null;
    let bestDist = Infinity;
    for (const ingredient of dictionary.allIngredients) {
      const dist = levenshtein(nameLower, normalize(ingredient.canonical_name));
      if (dist <= maxDist && dist < bestDist) {
        best = ingredient;
        bestDist = dist;
      }
    }
    if (best) return { type: "ingredient", doc: best };

    for (const additive of dictionary.allAdditives) {
      for (const synonym of additive.synonyms || []) {
        const dist = levenshtein(nameLower, normalize(synonym));
        if (dist <= maxDist && dist < bestDist) {
          best = additive;
          bestDist = dist;
        }
      }
    }
    if (best) return { type: "additive", doc: best };
  }

  return null;
}

async function resolveECodes(eCodes, dictionary) {
  if (!eCodes.length) return { resolved: [], unresolved: [] };
  const resolved = [];
  const unresolved = [];

  for (const code of eCodes) {
    const doc = dictionary.additivesByCode.get(normalize(code)) ||
      dictionary.additiveSynonyms.get(normalize(code));

    if (!doc) {
      unresolved.push(code);
      continue;
    }

    resolved.push({
      code: doc.code,
      name: doc.name,
      description: doc.description ?? null,
      category: doc.category ?? null,
      ...resolveHealthInfo(doc),
    });
  }
  return { resolved, unresolved };
}

async function resolveCandidateGroups(candidateGroups, dictionary) {
  if (!candidateGroups.length) {
    return { ingredients: [], additives: [], unresolved_terms: [] };
  }

  const ingredients = [];
  const additives = [];
  const unresolved_terms = [];
  const addedIngredients = new Set();
  const addedAdditives = new Set();

  for (const group of candidateGroups) {
    const candidates = Array.isArray(group) ? group : [group];
    let matched = false;

    for (const candidate of candidates) {
      const nameLower = normalize(candidate);
      if (nameLower.length < 2) continue;

      const result = matchSingleName(nameLower, dictionary);
      if (!result) continue;

      if (result.type === "ingredient") {
        const key = String(result.doc._id);
        if (!addedIngredients.has(key)) {
          addedIngredients.add(key);
          ingredients.push({
            name: result.doc.canonical_name,
            description: result.doc.description ?? null,
            category: result.doc.category ?? null,
            ...resolveHealthInfo(result.doc),
          });
        }
      } else {
        const key = result.doc.code;
        if (!addedAdditives.has(key)) {
          addedAdditives.add(key);
          additives.push({
            code: result.doc.code,
            name: result.doc.name,
            description: result.doc.description ?? null,
            category: result.doc.category ?? null,
            ...resolveHealthInfo(result.doc),
          });
        }
      }
      matched = true;
      break;
    }

    if (!matched) {
      unresolved_terms.push(Array.isArray(group) ? group[0] : group);
    }
  }

  return { ingredients, additives, unresolved_terms };
}

export async function runOCRPipeline(rawText) {
  const dictionary = await loadDictionary();
  const { eCodes, candidateGroups } = extractIngredientsAndAdditives(rawText);

  const { resolved: additivesFromCodes, unresolved: unresolvedCodes } =
    await resolveECodes(eCodes, dictionary);
  const { ingredients, additives: additivesFromNames, unresolved_terms } =
    await resolveCandidateGroups(candidateGroups, dictionary);

  const seenCodes = new Set(additivesFromCodes.map((a) => a.code));
  const mergedAdditives = [
    ...additivesFromCodes,
    ...additivesFromNames.filter((a) => {
      if (seenCodes.has(a.code)) return false;
      seenCodes.add(a.code);
      return true;
    }),
  ];

  return {
    ingredients,
    additives: mergedAdditives,
    unresolved_terms: [
      ...unresolved_terms,
      ...unresolvedCodes.map((code) => code.toUpperCase()),
    ],
    raw_text: rawText,
  };
}
