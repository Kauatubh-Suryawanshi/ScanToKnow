/* =====================================================
   NOVA Classification Service (OCR)
   ===================================================== */

const nova4 = [
  'aspartame', 'e951', 'ins951',
  'sucralose', 'e955', 'ins955',
  'acesulfame potassium', 'acesulfame k', 'e950', 'ins950',
  'saccharin', 'sodium saccharin', 'e954', 'ins954',
  'neotame', 'e961', 'ins961',
  'stevia', 'stevia extract', 'steviol glycosides',
  'e960', 'ins960',
  'thaumatin', 'e957', 'ins957',

  // ============================
  // SUGAR ALCOHOLS (ULTRA-PROCESSED IN DRINKS)
  // ============================
  'sorbitol', 'e420', 'ins420',
  'mannitol', 'e421', 'ins421',
  'xylitol', 'e967', 'ins967',
  'maltitol', 'e965', 'ins965',
  'isomalt', 'e953', 'ins953',
  'lactitol', 'e966', 'ins966',
  'polyglycitol syrup',

  // ============================
  // INDUSTRIAL SWEETENING SYSTEMS
  // ============================
  'high fructose corn syrup', 'hfcs',
  'invert sugar syrup', 'glucose syrup',

  // ============================
  // COSMETIC / FLAVOR ADDITIVES
  // ============================
  'artificial flavor', 'artificial flavours',
  'flavouring substances',
  'vanillin', 'ethyl vanillin',

  // ============================
  // FLAVOR ENHANCERS
  // ============================
  'monosodium glutamate', 'msg', 'e621', 'ins621',
  'disodium inosinate', 'e631', 'ins631',
  'disodium guanylate', 'e627', 'ins627',

  // ============================
  // COLORING AGENTS (COSMETIC)
  // ============================
  'caramel color', 'caramel colour',
  'e150', 'e150a', 'e150b', 'e150c', 'e150d',
  'tartrazine', 'e102', 'ins102',
  'sunset yellow', 'e110', 'ins110',
  'carmoisine', 'e122', 'ins122',
  'allura red', 'e129', 'ins129',
  'brilliant blue', 'e133', 'ins133',
  'indigo carmine', 'e132', 'ins132',
  'erythrosine', 'e127', 'ins127',
  'annatto', 'e160b', 'ins160b',
  'beta carotene', 'beta-carotene', 'e160a', 'ins160a',
  'cochineal', 'carmine', 'e120', 'ins120',
  'color added', 'added color'
];

const nova3 = [
  'citric acid', 'e330', 'ins330',
  'sodium citrate', 'e331', 'e331i', 'e331ii', 'e331iii', 'ins331',
  'potassium citrate', 'e332', 'ins332',
  'calcium citrate', 'e333', 'ins333',
  'acidity regulator', 'acidity regulators',

  // ============================
  // ANTIOXIDANTS (SHELF LIFE)
  // ============================
  'ascorbic acid', 'vitamin c', 'e300', 'ins300',
  'sodium ascorbate', 'e301', 'ins301',
  'calcium ascorbate', 'e302', 'ins302',

  // ============================
  // TRADITIONAL PRESERVATIVES
  // ============================
  'sorbic acid', 'e200', 'ins200',
  'potassium sorbate', 'e202', 'ins202',
  'benzoic acid', 'e210', 'ins210',
  'sodium benzoate', 'e211', 'ins211',

  // ============================
  // DRINK INGREDIENTS
  // ============================
  'fruit juice concentrate',
  'carbonated water',
  'fruit pulp',
  'natural juice',
];

const nova2 = [
    'sugar', 'brown sugar', 'white sugar',
  'salt',
  'honey',
  'vinegar'];
const nova1 = ['plain water',
  'milk',
  'coconut water',
  'fresh fruit juice',
  'orange juice',
  'apple juice',
  'grape juice'];


  function normalize(items) {
  return items
    .map(i => i.toLowerCase().trim())
    .filter(i => i.length > 2);
}

export function computeNOVA({ ingredients = [], additives = [] }) {
  const combined = normalize([...ingredients, ...additives]);
  const reasons = [];

  for (const i of combined) {
    if (nova4.some(n => i.includes(n))) {
      reasons.push(`Contains ultra-processed component (${i})`);
      return { group: 4, label: "NOVA 4:Ultra-Processed", reasons };
    }
  }

  for (const i of combined) {
    if (nova3.some(n => i.includes(n))) {
      reasons.push(`Processed ingredient (${i})`);
      return { group: 3, label: "NOVA 3:Processed", reasons };
    }
  }

  for (const i of combined) {
    if (nova2.some(n => i.includes(n))) {
      reasons.push(`Culinary ingredient (${i})`);
      return { group: 2, label: "NOVA 2:Culinary Ingredients", reasons };
    }
  }

  return {
    group: 1,
    label: "NOVA 1:Unprocessed / Minimally Processed",
    reasons: ["Only whole or minimally processed ingredients detected"]
  };
}
