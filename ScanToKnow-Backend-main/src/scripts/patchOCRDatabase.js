// scripts/patchOCRDatabase.js
// Run with: node scripts/patchOCRDatabase.js
// Patches additives and ingredients collections for better OCR matching

import mongoose from "mongoose";
import dotenv from "dotenv";
import { fileURLToPath } from "url";
import path from "path";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, "../../.env") });
const ADDITIVES_PATCHES = [
  // ── Fix empty E1450 synonyms ──────────────────────────
  {
    filter: { code: "E1450" },
    update: { $set: { synonyms: [
      "E1450", "INS 1450", "INS1450", "Starch Sodium Octenyl Succinate",
      "Modified Starch", "OSA Starch"
    ]}}
  },
  // ── Add E290 (missing entirely — Carbon Dioxide) ──────
  // Insert via insertIfMissing below

  // ── Add E150a synonyms (already exists as E150C but fix code) ─
  {
    filter: { code: "E150C" },
    update: { $set: {
      synonyms: [
        "Caramel Colour III", "Ammonia Caramel", "E150c", "INS 150c",
        "INS150c", "Caramel Color III", "E150C"
      ]
    }}
  },
  // ── Fix E150d synonyms (add more label variants) ──────
  {
    filter: { code: "E150d" },
    update: { $set: {
      synonyms: [
        "Caramel Colour IV", "Sulphite Ammonia Caramel", "INS 150d",
        "INS150d", "Caramel IV", "E150d", "Caramel E150d",
        "Caramel Color IV", "Caramel (E150d)", "Colour (Caramel E150d)"
      ]
    }}
  },
  // ── Add E452 sub-type synonyms ─────────────────────────
  {
    filter: { code: "E452" },
    update: { $set: {
      synonyms: [
        "Polyphosphates", "Sodium Polyphosphate", "E452",
        "E452i", "E452(i)", "INS 452", "INS 452(i)", "INS452",
        "Sequestrant", "Sequestrants"
      ]
    }}
  },
  // ── Fix E331(III) to also catch label variants ─────────
  {
    filter: { code: "E331 (III)" },
    update: { $set: {
      code: "E331",
      synonyms: [
        "Sodium Citrate", "E331", "INS 331", "INS331",
        "Trisodium Citrate", "E331(iii)", "331(iii)",
        "Sodium citrate (E331)", "E331 (III)"
      ]
    }}
  },
  // ── Fix E330 — add INS variant ─────────────────────────
  {
    filter: { code: "E330" },
    update: { $set: {
      synonyms: [
        "Citric Acid", "Sour salt", "E330", "INS 330", "INS330",
        "2-hydroxypropane-1,2,3-tricarboxylic acid",
        "Acidity Regulator (330)", "330"
      ]
    }}
  },
  // ── Fix E296 (Malic Acid) — add INS variant ────────────
  {
    filter: { code: "E296" },
    update: { $set: {
      synonyms: [
        "Malic Acid", "E296", "INS 296", "INS296",
        "apple acid", "DL-Malic Acid"
      ]
    }}
  },
  // ── Fix E211 — add INS variant ─────────────────────────
  {
    filter: { code: "E211" },
    update: { $set: {
      synonyms: [
        "Sodium Benzoate", "Benzoate of soda", "E211", "INS 211", "INS211",
        "Sodium salt of benzoic acid", "Preservative E211",
        "Preservative (211)", "211"
      ]
    }}
  },
  // ── Fix E110 — add INS variant ─────────────────────────
  {
    filter: { code: "E110" },
    update: { $set: {
      synonyms: [
        "Sunset Yellow FCF", "Orange Yellow S", "FD&C Yellow 6",
        "CI 15985", "E110 dye", "Food Yellow 3",
        "INS 110", "INS110", "Colour (110)", "Color (110)"
      ]
    }}
  },
  // ── Fix E414 — add INS variant ─────────────────────────
  {
    filter: { code: "E414" },
    update: { $set: {
      synonyms: [
        "Gum Arabic", "Acacia gum", "Gum acacia", "E414",
        "INS 414", "INS414", "Indian gum", "Gum Acacia"
      ]
    }}
  },
  // ── Fix E445 — add INS variant ─────────────────────────
  {
    filter: { code: "E445" },
    update: { $set: {
      synonyms: [
        "Glycerol esters of wood rosin", "Ester gum", "GEWR", "E445",
        "INS 445", "INS445", "Glyceryl abietate", "Stabilizer (445)"
      ]
    }}
  },
  // ── Fix E440 — add INS variant ─────────────────────────
  {
    filter: { code: "E440" },
    update: { $set: {
      synonyms: [
        "Pectin", "Fruit pectin", "Amidated pectin",
        "Vegetable gum 440", "E440", "INS 440", "INS440",
        "Stabilizer (440)", "Gelling Agent (440)"
      ]
    }}
  },
  // ── Fix E202 — add INS variant ─────────────────────────
  {
    filter: { code: "E202" },
    update: { $set: {
      synonyms: [
        "Potassium Sorbate", "E202", "INS 202", "INS202",
        "Preservative (202)"
      ]
    }}
  },
  // ── Fix E955 — add INS variant ─────────────────────────
  {
    filter: { code: "E955" },
    update: { $set: {
      synonyms: [
        "Sucralose", "E955", "INS 955", "INS955",
        "Sweetener (955)", "Trichlorogalactosucrose"
      ]
    }}
  },
  // ── Fix E950 — add INS variant + label variants ────────
  {
    filter: { code: "E950" },
    update: { $set: {
      synonyms: [
        "Acesulfame K", "Ace-K", "E950", "INS 950", "INS950",
        "Acesulfame Potassium", "Sweetener (950)"
      ]
    }}
  },
  // ── Fix E951 — add INS variant ─────────────────────────
  {
    filter: { code: "E951" },
    update: { $set: {
      synonyms: [
        "Aspartame", "E951", "INS 951", "INS951",
        "Sweetener (951)"
      ]
    }}
  },
  // ── Fix E627 — add INS variant ─────────────────────────
  {
    filter: { code: "E627" },
    update: { $set: {
      synonyms: [
        "Disodium Guanylate", "E627", "INS 627", "INS627",
        "Flavour Enhancer (627)", "Flavor Enhancer (627)"
      ]
    }}
  },
  // ── Fix E631 — add INS variant ─────────────────────────
  {
    filter: { code: "E631" },
    update: { $set: {
      synonyms: [
        "Disodium Inosinate", "E631", "INS 631", "INS631",
        "Flavour Enhancer (631)", "Flavor Enhancer (631)"
      ]
    }}
  },
  // ── Fix E551 — add INS variant ─────────────────────────
  {
    filter: { code: "E551" },
    update: { $set: {
      synonyms: [
        "Silicon Dioxide", "E551", "INS 551", "INS551",
        "Silica", "Anticaking Agent (551)", "Anti-caking Agent (551)"
      ]
    }}
  },
  // ── Fix E338 — add label variants ─────────────────────
  {
    filter: { code: "E338" },
    update: { $set: {
      synonyms: [
        "Orthophosphoric acid", "Phosphoric Acid", "E338",
        "INS 338", "INS338"
      ]
    }}
  },
  // ── Fix E300 — add INS variant ─────────────────────────
  {
    filter: { code: "E300" },
    update: { $set: {
      synonyms: [
        "Ascorbic Acid", "E300", "INS 300", "INS300",
        "Vitamin C", "Antioxidant (300)"
      ]
    }}
  },
  // ── Fix E160C (Paprika) ───────────────────────────────
  {
    filter: { code: "E160C" },
    update: { $set: {
      synonyms: [
        "Paprika Extract", "E160c", "E160C", "INS 160c", "INS160c",
        "Paprika Oleoresin", "Colour (160c)"
      ]
    }}
  },
  // ── Fix E129 — add INS variant ─────────────────────────
  {
    filter: { code: "E129" },
    update: { $set: {
      synonyms: [
        "Allura Red AC", "FD&C Red 40", "CI 16035", "E129",
        "INS 129", "INS129", "Colour (129)"
      ]
    }}
  },
  // ── Fix E133 — add INS variant ─────────────────────────
  {
    filter: { code: "E133" },
    update: { $set: {
      synonyms: [
        "Brilliant Blue FCF", "FD&C Blue No. 1", "Blue 1",
        "CI 42090", "E133", "INS 133", "INS133", "Colour (133)"
      ]
    }}
  },
  // ── Fix E334 — add INS variant ─────────────────────────
  {
    filter: { code: "E334" },
    update: { $set: {
      synonyms: [
        "Tartaric Acid", "E334", "INS 334", "INS334",
        "L-Tartaric Acid", "Acidity Regulator (334)"
      ]
    }}
  },
  // ── Fix E471 — add label variants ─────────────────────
  {
    filter: { code: "E471" },
    update: { $set: {
      synonyms: [
        "Mono and Diglycerides", "E471", "INS 471", "INS471",
        "Mono- and Diglycerides of Fatty Acids",
        "Emulsifier (471)", "Emulsifying Agent (471)"
      ]
    }}
  },
  // ── Fix E322 (Lecithin) — add label variants ──────────
  {
    filter: { code: "E322" },
    update: { $set: {
      synonyms: [
        "Lecithin", "Soy Lecithin", "Sunflower Lecithin",
        "E322", "E322(i)", "INS 322", "INS322",
        "Emulsifier (322)", "Emulsifier (322(i))"
      ]
    }}
  },
  // ── Fix E500 ──────────────────────────────────────────
  {
    filter: { code: "E500" },
    update: { $set: {
      synonyms: [
        "E500", "Sodium carbonates", "Soda ash",
        "INS 500", "INS500", "Raising Agent (500)"
      ]
    }}
  },
  // ── Fix E500ii ────────────────────────────────────────
  {
    filter: { code: "E500ii" },
    update: { $set: {
      synonyms: [
        "E500(ii)", "Sodium bicarbonate", "Baking soda",
        "INS 500(ii)", "INS500ii", "Raising Agent (500(ii))",
        "Sodium Hydrogen Carbonate"
      ]
    }}
  },
  // ── Fix E341(III) ─────────────────────────────────────
  {
    filter: { code: "E341 (III)" },
    update: { $set: {
      synonyms: [
        "Tricalcium Phosphate", "E341(iii)", "E341 (III)",
        "INS 341", "INS 341(iii)", "INS341",
        "Anticaking Agent (341(iii))"
      ]
    }}
  },
  // ── Fix E262(I) ───────────────────────────────────────
  {
    filter: { code: "E262 (I)" },
    update: { $set: {
      synonyms: [
        "Sodium Acetate", "E262(i)", "E262 (I)",
        "INS 262", "INS 262(i)", "INS262",
        "Preservative (262(i))"
      ]
    }}
  },
  // ── Fix E460(i) ───────────────────────────────────────
  {
    filter: { code: "E460(i)" },
    update: { $set: {
      synonyms: [
        "Microcrystalline Cellulose", "MCC", "INS 460(i)",
        "E460(i)", "E 460(i)", "Stabilizer (E 460(i))",
        "INS460i"
      ]
    }}
  },
  // ── Fix E503 (Ammonium Carbonates) — add if missing ───
  // Insert below
];

// New additives to INSERT (missing from DB entirely)
const NEW_ADDITIVES = [
  {
    code: "E290",
    name: "Carbon Dioxide",
    description: "Gas used as carbonating agent in beverages.",
    health_rating: 90,
    source_tag: "🔵",
    notes: "Naturally occurring gas; safe as food additive.",
    synonyms: [
      "Carbon Dioxide", "E290", "INS 290", "INS290",
      "CO2", "Carbonating Agent", "Carbonating Agent (INS 290)",
      "Carbonation Agent"
    ],
    category: "carbonating agent"
  },
  {
    code: "E503i",
    name: "Ammonium Carbonate",
    description: "Leavening agent used in biscuits and baked goods.",
    health_rating: 75,
    source_tag: "🟢",
    notes: "Traditional baking agent; safe at food levels.",
    synonyms: [
      "Ammonium Carbonate", "E503", "E503(i)", "E503i",
      "INS 503", "INS 503(i)", "INS503",
      "Raising Agent (503)", "Raising Agent (503(i))"
    ],
    category: "leavening agent"
  },
  {
    code: "E503ii",
    name: "Ammonium Hydrogen Carbonate",
    description: "Leavening agent used in biscuits and baked goods.",
    health_rating: 75,
    source_tag: "🟢",
    notes: "Used as raising agent in baked goods.",
    synonyms: [
      "Ammonium Bicarbonate", "Ammonium Hydrogen Carbonate",
      "E503(ii)", "E503ii", "INS 503(ii)", "INS503ii",
      "Raising Agent (503(ii))"
    ],
    category: "leavening agent"
  },
  {
    code: "E472e",
    name: "Diacetyltartaric Acid Esters of Mono- and Diglycerides",
    description: "Emulsifier used in baked goods.",
    health_rating: 70,
    source_tag: "🟢",
    notes: "DATEM; considered safe at regulated levels.",
    synonyms: [
      "DATEM", "E472e", "E472(e)", "INS 472e", "INS472e",
      "Diacetyltartaric And Fatty Acid Esters Of Glycerol",
      "Emulsifier (472e)"
    ],
    category: "emulsifier"
  },
  {
    code: "E223",
    name: "Sodium Metabisulphite",
    description: "Preservative and dough conditioner.",
    health_rating: 55,
    source_tag: "🟡",
    notes: "May cause reactions in sulphite-sensitive individuals.",
    synonyms: [
      "Sodium Metabisulphite", "Sodium Metabisulfite",
      "E223", "INS 223", "INS223",
      "Dough Conditioner (223)", "Flour Treatment Agent (223)"
    ],
    category: "preservative / dough conditioner"
  },
  {
    code: "E270",
    name: "Lactic Acid",
    description: "Acidity regulator naturally found in fermented foods.",
    health_rating: 85,
    source_tag: "🟢",
    notes: "Naturally occurring; safe at food levels.",
    synonyms: [
      "Lactic Acid", "E270", "INS 270", "INS270",
      "Acidity Regulator (270)"
    ],
    category: "acidity regulator"
  },
];

// New ingredients to INSERT (missing from DB)
const NEW_INGREDIENTS = [
  {
    canonical_name: "Niacin",
    aliases: ["Nicotinic Acid", "Vitamin B3", "Niacinamide", "Vitamin PP"],
    description: "B-vitamin essential for energy metabolism.",
    health_rating: 88,
    source_tag: "🟢",
    category: "vitamin"
  },
  {
    canonical_name: "Phosphoric Acid",
    aliases: ["Orthophosphoric Acid", "INS 338", "E338", "Acidity Regulator (338)"],
    description: "Acidity regulator used in cola beverages.",
    health_rating: 45,
    source_tag: "🟡",
    category: "acidity regulator"
  },
  {
    canonical_name: "Citric Acid",
    aliases: ["E330", "INS 330", "Sour Salt", "Acidity Regulator (330)"],
    description: "Natural acid used as acidity regulator and preservative.",
    health_rating: 78,
    source_tag: "🟢",
    category: "acidity regulator"
  },
  {
    canonical_name: "Spices And Condiments",
    aliases: [
      "Spices", "Condiments", "Spices & Condiments",
      "Mixed Spices", "Spice Mix", "Masala"
    ],
    description: "Blend of spices and condiments for flavouring.",
    health_rating: 80,
    source_tag: "🟢",
    category: "spice blend"
  },
  {
    canonical_name: "Paprika Extract",
    aliases: [
      "Paprika Oleoresin", "E160c", "INS 160c",
      "Colour (INS 160c)", "Colour (160c)"
    ],
    description: "Natural red colour extracted from paprika.",
    health_rating: 82,
    source_tag: "🟢",
    category: "natural colour"
  },
  {
    canonical_name: "Invert Sugar Syrup",
    aliases: [
      "Invert Sugar", "Inverted Sugar", "Invert Syrup",
      "Trimoline", "Glucose-Fructose Syrup"
    ],
    description: "Mixture of glucose and fructose from sucrose hydrolysis.",
    health_rating: 38,
    source_tag: "🟠",
    category: "sweetener"
  },
  {
    canonical_name: "Raising Agents",
    aliases: [
      "Raising Agent", "Leavening Agent", "Leavening Agents",
      "Baking Powder", "Rising Agent"
    ],
    description: "Agents used to leaven baked goods.",
    health_rating: 72,
    source_tag: "🟢",
    category: "leavening agent"
  },
  {
    canonical_name: "Baker's Yeast",
    aliases: [
      "Yeast", "Baker Yeast", "Bakers Yeast",
      "Active Dry Yeast", "Instant Yeast"
    ],
    description: "Leavening microorganism used in baked goods.",
    health_rating: 85,
    source_tag: "🟢",
    category: "leavening agent"
  },
  {
    canonical_name: "Malt Extract",
    aliases: [
      "Malted Barley Extract", "Barley Malt Extract",
      "Malt Syrup", "Liquid Malt"
    ],
    description: "Sweet extract from malted barley used for flavour.",
    health_rating: 68,
    source_tag: "🟢",
    category: "flavouring / sweetener"
  },
  {
    canonical_name: "Enzyme",
    aliases: [
      "Enzymes", "Food Enzyme", "Protease", "Amylase",
      "Beta Galactosidase", "Lactase", "Lipase"
    ],
    description: "Biological catalyst used in food processing.",
    health_rating: 80,
    source_tag: "🟢",
    category: "processing aid"
  },
  {
    canonical_name: "Cheese Powder",
    aliases: [
      "Cheese", "Cheddar Powder", "Processed Cheese Powder",
      "Cheese Seasoning"
    ],
    description: "Dehydrated cheese used as flavouring.",
    health_rating: 55,
    source_tag: "🟡",
    category: "dairy / flavouring"
  },
  {
    canonical_name: "Natural Flavouring Substances",
    aliases: [
      "Natural Flavourings", "Natural Flavouring", "Natural Flavor",
      "Natural Flavors", "Natural Flavour", "Added Natural Flavour",
      "Natural And Nature Identical Flavouring Substances",
      "Nature Identical And Natural Flavouring Substances",
      "Natural Flavouring Substances"
    ],
    description: "Flavouring derived from natural sources.",
    health_rating: 70,
    source_tag: "🟢",
    category: "flavouring"
  },
  {
    canonical_name: "Palmolein",
    aliases: [
      "Palm Olein", "Refined Palmolein", "Palmolein Oil",
      "Edible Palmolein"
    ],
    description: "Liquid fraction of palm oil used in frying.",
    health_rating: 42,
    source_tag: "🟡",
    category: "edible oil"
  },
  {
    canonical_name: "Rice Bran Oil",
    aliases: [
      "Rice Bran", "Rice Bran Extract", "Rice Oil"
    ],
    description: "Oil extracted from the outer bran layer of rice.",
    health_rating: 70,
    source_tag: "🟢",
    category: "edible oil"
  },
];

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log("Connected to MongoDB");

  const AdditiveColl   = mongoose.connection.collection("additives");
  const IngredientColl = mongoose.connection.collection("ingredients");

  // ── Patch existing additives ──────────────────────────
  console.log("\n── Patching existing additives ──");
  for (const patch of ADDITIVES_PATCHES) {
    const result = await AdditiveColl.updateOne(patch.filter, patch.update);
    if (result.matchedCount > 0) {
      console.log(`  ✅ Patched: ${JSON.stringify(patch.filter)}`);
    } else {
      console.log(`  ⚠️  Not found: ${JSON.stringify(patch.filter)}`);
    }
  }

  // ── Insert new additives ──────────────────────────────
  console.log("\n── Inserting new additives ──");
  for (const add of NEW_ADDITIVES) {
    const exists = await AdditiveColl.findOne({ code: add.code });
    if (!exists) {
      await AdditiveColl.insertOne(add);
      console.log(`  ✅ Inserted: ${add.code} - ${add.name}`);
    } else {
      console.log(`  ⏭️  Already exists: ${add.code}`);
    }
  }

  // ── Insert new ingredients ────────────────────────────
  console.log("\n── Inserting new ingredients ──");
  for (const ing of NEW_INGREDIENTS) {
    const exists = await IngredientColl.findOne({
      canonical_name: ing.canonical_name
    });
    if (!exists) {
      await IngredientColl.insertOne(ing);
      console.log(`  ✅ Inserted: ${ing.canonical_name}`);
    } else {
      // Update aliases if new ones added
      await IngredientColl.updateOne(
        { canonical_name: ing.canonical_name },
        { $addToSet: { aliases: { $each: ing.aliases } } }
      );
      console.log(`  🔄 Updated aliases: ${ing.canonical_name}`);
    }
  }

  console.log("\n✅ DB patch complete.");
  await mongoose.disconnect();
}

run().catch(console.error);