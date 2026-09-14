/* =========================================================
   ingredientExtractor.service.js — v5.0

   RULES ADDED based on product label analysis:

   RULE 1: INS normalization
     "INS 296", "INS296", "ins296", "INS-296" → e296
     "INS 452(i)" → e452
     "INS 331(iii)" → e331

   RULE 2: E-code with space
     "E 460(i)", "E 330" → e460, e330

   RULE 3: Roman numeral qualifier stripping
     "331(iii)", "503(ii)", "341(i)" → 331, 503, 341

   RULE 4: Multiple codes same bracket with INS prefix
     "(INS 296, INS 331, INS 300)" → e296, e331, e300

   RULE 5: Sequestrant/category labels
     "SEQUESTRANTS (452(i), 385)" → e452, e385

   RULE 6: Percentage annotations
     "CAFFEINE (0.03%)" → "Caffeine" (ingredient, not additive)
     "CASHEW NUTS (4.5%)" → "Cashew Nuts"

   RULE 7: Vitamin annotations
     "VITAMINS (NIACIN, VITAMIN B6, VITAMIN B12)" →
       ["Niacin", "Vitamin B6", "Vitamin B12"] as name candidates

   RULE 8: Compound ingredient groups
     "MILK PRODUCTS (MILK SOLIDS & SWEETENED CONDENSED MILK)" →
       ["Milk Products", "Milk Solids"] as candidates

   RULE 9: Seasoning blocks
     "*SEASONING (...long block...)" → parse inner contents
     "++SEASONING (...)" → same

   RULE 10: "CONTAINS PERMITTED..." lines
     → Extract code from bracket, ignore text

   RULE 11: Percentage-only content in brackets
     "(0.03%)" "(4.5%)" → skip bracket, treat base as ingredient

   RULE 12: "COLOUR (CARAMEL E150D)" → extract E150d
   ========================================================= */

const MIN_E = 100;
const MAX_E = 1520;

/* =========================================================
   NOISE PATTERNS — lines/tokens definitely not ingredients
   ========================================================= */
const NOISE_PATTERNS = [
  /^may contain/i,
  /^contains no /i,
  /^allergen/i,
  /^allergy/i,
  /manufactured\s*(by|in)/i,
  /packed\s*(by|in)/i,
  /best before/i,
  /use before/i,
  /expiry/i,
  /net\s*wt/i,
  /net\s*weight/i,
  /serving size/i,
  /per\s*100\s*(ml|g)/i,
  /per\s*serve/i,
  /%\s*rda/i,
  /based on.*kcal/i,
  /approx.*val/i,
  /nutrition(al)?\s*(info|fact|value)/i,
  /^\s*energy\s*[\d]/i,
  /^\s*carbohydrate/i,
  /^\s*total fat/i,
  /^\s*protein\s*[\d]/i,
  /^\s*sodium\s*[\d]/i,
  /^\s*dietary\s*fib/i,
  /product of/i,
  /imported by/i,
  /distributed by/i,
  /marketed by/i,
  /fssai/i,
  /lic(ence|ense|\.)\s*no/i,
  /batch\s*no/i,
  /mfg\s*date/i,
  /^\s*vegetarian\s*$/i,
  /^\s*vegan\s*$/i,
  /^\s*halal\s*$/i,
  /^\s*kosher\s*$/i,
  /contains no fruit/i,
  /sweetened carbonated/i,
  /^\s*\d+(\.\d+)?\s*(ml|g|kg|l)\s*$/i,
  /^\s*\d+(\.\d+)?%\s*$/i,
  /contient\s*:/i,
  /ingr[eé]dients\s*:/i,
  /^\s*[a-z]{1,2}\s*$/i,
  /^\s*total sugars/i,
  /^\s*added sugars/i,
  /^\s*\*based on/i,
  /^\s*serving\s*=/i,
  /^\s*per\s*\d/i,
  /^\s*%rda/i,
  /^\s*\d+(\.\d+)?\s*kcal/i,
  /^\s*\d+(\.\d+)?\s*kj/i,
  /contains a source of/i,         // "Contains a Source of Phenylalanine"
  /numbers in brackets/i,           // "(Numbers in brackets as per INS)"
  /as per international/i,
  /as per ins/i,
  /store in/i,
  /transfer.*container/i,
  /once opened/i,
  /^\s*traces\s*:/i,
  /^\s*gluten\s*,/i,
  /lic\.\s*no\./i,
  /mfg unit/i,
  /for mfg/i,
];

/* =========================================================
   STOP SECTION PHRASES
   ========================================================= */
const STOP_PHRASES = [
  "allergen",
  "allergy advice",
  "may contain",
  "contains no",
  "nutrition information",
  "nutritional information",
  "nutrition facts",
  "nutritional value",
  "nutrition value",
  "manufactured by",
  "manufactured in",
  "packed by",
  "best before",
  "expiry date",
  "net weight",
  "net wt",
  "fssai",
  "customer care",
  "for more information",
  "contient :",
  "ingrédients :",
  "zutaten",
  "ingredienti",
  "nutrition information",
  "approximate values",
  "serving =",
  "per 100",
  "*based on",
  "contains wheat",              // allergen block
  "contains milk",
  "contains soy",
  "contains a source",
  "allergen advice",
  "allergen information",
  "numbers in brackets",         // label footnote
  "as per international numbering",
  "store in a",
];

/* =========================================================
   HEADER PATTERNS
   ========================================================= */
const HEADER_PATTERNS = [
  /ingredi[ea]nts?\s*:/i,
  /ingr[ei]di[ea]nts?\s*:/i,
  /lngredients?\s*:/i,
  /lngr[ei]di[ea]nts?\s*:/i,
  /composition\s*:/i,
  /made\s+with\s*:/i,
  /ingredi[ea]nts?\s*\n/i,
  /ingredi[ea]nts\s+include/i,
];

/* =========================================================
   CATEGORY LABELS — when these appear as base token with
   codes in brackets, treat codes as primary result
   ========================================================= */
const CATEGORY_LABELS = new Set([
  "acidity regulator", "acidity regulators",
  "stabilizer", "stabilizers", "stabiliser", "stabilisers",
  "preservative", "preservatives",
  "colour", "color", "colours", "colors",
  "permitted synthetic food colour",
  "contains permitted synthetic food colour",
  "synthetic food colour",
  "emulsifier", "emulsifiers",
  "antioxidant", "antioxidants",
  "thickener", "thickeners",
  "flavour", "flavours", "flavor", "flavors",
  "added flavours", "added flavors",
  "sweetener", "sweeteners",
  "humectant", "humectants",
  "raising agent", "raising agents",
  "firming agent", "firming agents",
  "anti-caking agent", "anti caking agent", "anticaking agent",
  "sequestrant", "sequestrants",
  "flour treatment agent", "flour treatment agents",
  "dough conditioner", "dough conditioners",
  "flavour enhancer", "flavour enhancers",
  "flavor enhancer", "flavor enhancers",
  "gelling agent", "gelling agents",
  "natural colour", "natural color",
  "natural flavour", "natural flavor",
  "vitamins",
  "minerals",
]);

/* =========================================================
   STEP 1 — OCR TEXT CLEANUP + LINE-JOIN HEALING
   ========================================================= */
function cleanOCRText(raw) {
  if (!raw) return "";

  let text = raw;
  text = text.replace(/\r\n/g, "\n").replace(/\r/g, "\n");

  // Fix OCR confusion: l/I before 3-4 digits in E-code range → e
  text = text.replace(/\b[lI](\d{3,4}[a-z]?)\b/g, (match, n) => {
    const num = parseInt(n, 10);
    if (num >= MIN_E && num <= MAX_E) return `e${n}`;
    return match;
  });

  // Normalize "lns" → "ins"
  text = text.replace(/\b[lL][nN][sS]\b/g, "ins");

  // Remove asterisk prefixes from seasoning blocks: "*Seasoning" "++Seasoning"
  text = text.replace(/^[\*\+]+\s*/gm, "");

  // Normalize per-line whitespace
  const lines = text
    .split("\n")
    .map(line => line.trim().replace(/\s+/g, " "))
    .filter(Boolean);

  // ── LINE-JOIN HEALING ──────────────────────────────────
  const healed = [];
  for (let i = 0; i < lines.length; i++) {
    const cur  = lines[i];
    const prev = healed[healed.length - 1];

    if (!prev) { healed.push(cur); continue; }

    const prevEndsWithDelimiter = /[,\.;\u2022]\s*$/.test(prev);
    const prevEndsWithClose     = /\)\s*$/.test(prev);
    const curStartsNewSection   = HEADER_PATTERNS.some(p => p.test(cur));
    const curStartsAllCaps      = /^[A-Z][A-Z\s]{4,}:/.test(cur);

    const openCount  = (prev.match(/\(/g) || []).length;
    const closeCount = (prev.match(/\)/g) || []).length;
    const hasUnclosedBracket = openCount > closeCount;

    if (
      hasUnclosedBracket ||
      (!prevEndsWithDelimiter && !prevEndsWithClose &&
       !curStartsNewSection && !curStartsAllCaps)
    ) {
      healed[healed.length - 1] = prev + " " + cur;
    } else {
      healed.push(cur);
    }
  }

  return healed.join("\n").trim();
}

/* =========================================================
   STEP 2 — ISOLATE INGREDIENTS SECTION
   ========================================================= */
function isolateSection(text) {
  let headerEnd = -1;
  for (const pattern of HEADER_PATTERNS) {
    const match = text.match(pattern);
    if (match && match.index !== undefined) {
      headerEnd = match.index + match[0].length;
      break;
    }
  }

  if (headerEnd === -1) {
    const commas  = (text.match(/,/g)  || []).length;
    const bullets = (text.match(/•/g)  || []).length;
    if (commas > 2 || bullets > 2) headerEnd = 0;
    else return "";
  }

  let section = text.substring(headerEnd);
  const sectionLower = section.toLowerCase();
  let cutAt = section.length;

  for (const stop of STOP_PHRASES) {
    const idx = sectionLower.indexOf(stop);
    if (idx > 0 && idx < cutAt) cutAt = idx;
  }

  section = section.substring(0, cutAt).trim();
  section = section.replace(/\.\s*$/, "").trim();
  return section;
}

/* =========================================================
   STEP 3 — SMART SPLIT (respects bracket depth)
   ========================================================= */
function smartSplit(text) {
  const tokens = [];
  let depth = 0, current = "";

  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === "(" || ch === "[") { depth++; current += ch; }
    else if (ch === ")" || ch === "]") { depth = Math.max(0, depth - 1); current += ch; }
    else if (ch === "," && depth === 0) {
      const t = current.trim();
      if (t) tokens.push(t);
      current = "";
    } else { current += ch; }
  }
  const t = current.trim();
  if (t) tokens.push(t);
  return tokens;
}

function splitIntoTokens(section) {
  if (!section) return [];
  let text = section;
  text = text.replace(/•/g, ",");
  text = text.replace(/;/g, ",");
  text = text.split("\n").map(l => l.trim()).filter(Boolean).join(", ");
  text = text.replace(/,\s*,+/g, ",");
  return smartSplit(text).map(t => t.trim()).filter(Boolean);
}

/* =========================================================
   NORMALIZE INS/E CODE — RULE 1, 2, 3
   Handles all real-world label variants:
   "INS 296", "INS296", "INS-296", "INS 331(iii)",
   "E 330", "E330", "330", "331(iii)", "503(ii)"
   ========================================================= */
function normalizeToECode(raw) {
  let s = raw.toString().trim().toLowerCase();

  // Remove Roman numeral qualifiers in brackets: "331(iii)" → "331"
  // Also "503(ii)", "341(i)", "452(i)"
  s = s.replace(/\(([ivx]+)\)$/i, "");
  // Remove trailing Roman numerals without bracket: "331iii" → "331"
  s = s.replace(/([0-9])([ivx]+)$/i, "$1");

  // INS format: "ins 296", "ins296", "ins-296", "ins331(iii)"
  const insMatch = s.match(/^ins\s*[-:]?\s*(\d{3,4})/i);
  if (insMatch) {
    const n = parseInt(insMatch[1], 10);
    if (n >= MIN_E && n <= MAX_E) return `e${n}`;
  }

  // E-code with optional space: "e 330", "e330", "e150d"
  const eMatch = s.match(/^e\s*(\d{3,4})/i);
  if (eMatch) {
    const n = parseInt(eMatch[1], 10);
    if (n >= MIN_E && n <= MAX_E) return `e${n}`;
  }

  // Bare number: "330", "211"
  const bareMatch = s.match(/^(\d{3,4})$/);
  if (bareMatch) {
    const n = parseInt(bareMatch[1], 10);
    if (n >= MIN_E && n <= MAX_E) return `e${n}`;
  }

  return null;
}

/* =========================================================
   EXTRACT CODES FROM BRACKET CONTENT — RULES 1-5
   Handles: "(330, 331(iii))", "(INS 296, INS 331, INS 300)",
            "(452(i), 385)", "(Caramel E150d)"
   ========================================================= */
function extractCodesFromBracket(content) {
  const codes = [];

  // Special case: "Caramel E150d" — name + code in bracket
  // Extract the code part
  const embeddedCode = content.match(/\bE\s*(\d{3,4}[a-z]?)\b/i);
  if (embeddedCode) {
    const n = parseInt(embeddedCode[1], 10);
    if (n >= MIN_E && n <= MAX_E) codes.push(`e${n}`);
  }

  // Split on comma or & at top level
  const parts = smartSplit(content);

  for (let part of parts) {
    part = part.trim();
    if (!part) continue;
    const code = normalizeToECode(part);
    if (code) codes.push(code);
  }

  return [...new Set(codes)];
}

function isDescriptiveBracket(content) {
  // No 3-4 digit number → descriptive
  // Exception: if it has embedded E-code like "Caramel E150d"
  const hasNumericCode = /\b\d{3,4}\b/.test(content);
  const hasEmbeddedE   = /\bE\s*\d{3,4}/i.test(content);
  if (hasEmbeddedE) return false; // has code, not pure descriptive
  return !hasNumericCode;
}

function isPercentageOnlyBracket(content) {
  // "(0.03%)", "(4.5%)", "(29 mg/100 ml)"
  return /^\s*[\d.]+\s*(%|mg|g|ml|\/)\s*/.test(content.trim());
}

/* =========================================================
   STEP 4 — STRIP PERCENTAGE/QUANTITY PREFIX FROM TOKEN
   ========================================================= */
function stripQuantityPrefix(s) {
  return s
    .replace(/^(and\s+)?(less\s+than|more\s+than|at\s+least)?\s*\d+(\.\d+)?\s*%\s*(or\s+less\s+)?(of\s*:?\s*)?/i, "")
    .replace(/^\d+(\.\d+)?\s*%\s*(or\s+less\s+(of\s*)?:?\s*)?/i, "")
    .trim();
}

/* =========================================================
   UTILITY
   ========================================================= */
function toTitleCase(str) {
  return str.toLowerCase().replace(/\b\w/g, c => c.toUpperCase()).trim();
}

function isCategoryLabel(s) {
  return CATEGORY_LABELS.has(s.toLowerCase().trim());
}

/* =========================================================
   STEP 5 — CLASSIFY TOKENS
   Returns { eCodes[], candidateGroups[] }
   candidateGroups entries: string | string[] (OR groups)
   ========================================================= */
function classifyTokens(tokens) {
  const eCodes         = new Set();
  const candidateGroups = [];
  const seenNames      = new Set();

  function addCandidate(entry) {
    const key = Array.isArray(entry) ? entry.join("|") : entry;
    if (!seenNames.has(key)) {
      seenNames.add(key);
      candidateGroups.push(entry);
    }
  }

  for (let rawToken of tokens) {
    rawToken = rawToken.trim();
    if (!rawToken) continue;

    // ── NOISE CHECK ───────────────────────────────────────
    if (NOISE_PATTERNS.some(p => p.test(rawToken))) continue;

    // ── STRIP QUANTITY PREFIX ─────────────────────────────
    const deQuant = stripQuantityPrefix(rawToken);
    const working = deQuant || rawToken;

    if (/^\d+(\.\d+)?%?$/.test(working)) continue;
    if (working.length < 2) continue;

    // ── EXTRACT BRACKET CONTENTS ──────────────────────────
    const bracketRegex = /\(([^()]*(?:\([^()]*\)[^()]*)*)\)/g;
    const brackets = [];
    let bMatch;
    while ((bMatch = bracketRegex.exec(working)) !== null) {
      brackets.push(bMatch[1]);
    }

    // Base token with brackets removed
    const base     = working.replace(/\([^()]*(?:\([^()]*\)[^()]*)*\)/g, "").trim();
    const baseLower = base.toLowerCase().trim();
    const baseNorm  = toTitleCase(base);

    // ── DIRECT CODE IN BASE ───────────────────────────────
    const directCode = normalizeToECode(base);
    if (directCode) {
      eCodes.add(directCode);
      continue;
    }

    // ── PROCESS BRACKETS ──────────────────────────────────
    const nameCandidates = [];
    let foundCodesInBracket = false;

    for (const bracketContent of brackets) {

      // RULE 11: Percentage-only bracket → skip it, treat base as ingredient
      if (isPercentageOnlyBracket(bracketContent)) {
        continue; // will fall through to add base as name candidate
      }

      // RULE 10 / 12: Has embedded E-code like "Caramel E150d"
      const embeddedCode = bracketContent.match(/\bE\s*(\d{3,4}[a-z]?)\b/i);
      if (embeddedCode) {
        const n = parseInt(embeddedCode[1], 10);
        if (n >= MIN_E && n <= MAX_E) {
          eCodes.add(`e${n}`);
          foundCodesInBracket = true;
          // Also extract text name: "Caramel E150d" → "Caramel"
          const nameOnly = bracketContent.replace(/\bE\s*\d{3,4}[a-z]?\b/gi, "").trim();
          if (nameOnly.length > 2) nameCandidates.push(toTitleCase(nameOnly));
          continue;
        }
      }

      if (!isDescriptiveBracket(bracketContent)) {
        // Has numeric codes
        const codes = extractCodesFromBracket(bracketContent);
        if (codes.length > 0) {
          codes.forEach(c => eCodes.add(c));
          foundCodesInBracket = true;
        }
      } else {
        // RULE 7: Vitamin group — "VITAMINS (NIACIN, VITAMIN B6, VITAMIN B12)"
        // RULE 8: Compound group — "MILK PRODUCTS (MILK SOLIDS & CONDENSED MILK)"
        // Split descriptive bracket content and add each as candidate
        const parts = bracketContent.split(/[&,+]/);
        for (const part of parts) {
          const p = toTitleCase(part.trim());
          if (p.length > 2 && !NOISE_PATTERNS.some(np => np.test(p))) {
            nameCandidates.push(p);
          }
        }
      }
    }

    // ── BASE NAME HANDLING ────────────────────────────────
    if (baseLower.length > 2 && !NOISE_PATTERNS.some(p => p.test(baseLower))) {

      if (isCategoryLabel(baseLower) && foundCodesInBracket) {
        // Pure category label — codes extracted, also add label as candidate
        // (e.g. "ACIDITY REGULATORS" might match "Citric Acid" in DB)
        // But only add if it's a meaningful standalone term
        if (!["colour", "color", "colours", "flavour", "flavours",
              "preservative", "preservatives"].includes(baseLower)) {
          nameCandidates.unshift(baseNorm);
        }
      } else if (isCategoryLabel(baseLower) && nameCandidates.length > 0) {
        // Category with descriptive bracket — add both
        nameCandidates.unshift(baseNorm);
      } else {
        // Regular ingredient/additive name
        nameCandidates.unshift(baseNorm);
      }
    }

    // ── REGISTER CANDIDATES ───────────────────────────────
    if (nameCandidates.length === 1) {
      addCandidate(nameCandidates[0]);
    } else if (nameCandidates.length > 1) {
      addCandidate(nameCandidates); // OR group
    }
  }

  return {
    eCodes:          Array.from(eCodes),
    candidateGroups,
  };
}

/* =========================================================
   PUBLIC API
   ========================================================= */
export function extractIngredientsAndAdditives(rawText) {
  const cleaned  = cleanOCRText(rawText);
  const section  = isolateSection(cleaned);
  const tokens   = splitIntoTokens(section || cleaned);
  return classifyTokens(tokens);
}