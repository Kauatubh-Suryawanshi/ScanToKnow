/**
 * src/scripts/computeCphs.js
 *
 * CPHS v2.5 — Batch computation script.
 *
 * What it does:
 *   1. Connects to MongoDB using MONGO_URI from .env
 *   2. Loads ALL additive health ratings into memory (Map) — one query
 *   3. Loads ALL ingredient health ratings into memory (Map) — one query
 *   4. Iterates every product_variant in batches of BATCH_SIZE
 *   5. Runs calculateCPHS() for each variant
 *   6. Writes cphs_final, health_label, health_stars back using bulkWrite
 *   7. Logs a summary and disconnects cleanly
 *
 * Usage:
 *   node src/scripts/computeCphs.js
 *   node src/scripts/computeCphs.js --dry-run     (calculate but do not write)
 *   node src/scripts/computeCphs.js --id <variantId>  (single variant)
 *
 * When to run:
 *   - Once after deploying v2.5 (scores all existing products)
 *   - After any update to fooddb.additives health_rating values
 *   - After any update to fooddb.ingredients health_rating values
 *   - After a large import of new product_variants
 *
 * Safe to re-run: always overwrites cphs_final with freshly computed value.
 * Does NOT touch any other field on the product_variant document.
 */

import mongoose from "mongoose";
import dotenv from "dotenv";
import { calculateCPHS } from "../services/cphs.service.js";

dotenv.config();

// ─── Configuration ────────────────────────────────────────────────────────────

const BATCH_SIZE = 200;     // variants processed per bulkWrite round
const LOG_EVERY  = 500;     // log progress every N variants

// ─── CLI flags ────────────────────────────────────────────────────────────────

const args    = process.argv.slice(2);
const DRY_RUN = args.includes("--dry-run");
const idIndex = args.indexOf("--id");
const SINGLE_ID = idIndex !== -1 ? args[idIndex + 1] : null;

// ─── MongoDB raw collection access ───────────────────────────────────────────
//
// We use mongoose.connection.db (native driver) instead of Mongoose models
// for two reasons:
//   1. Additive and Ingredient models declare health_rating as Number — after
//      the model reform they will coerce correctly. But raw .lean() from the
//      native driver gives us the actual stored value without coercion, so we
//      call parseFloat() ourselves via safeRating() inside cphs.service.js.
//   2. The batch runner owns the DB connection lifecycle — no need to import
//      all Mongoose models just for bulk reads.
//
// product_variants is written via native bulkWrite for maximum throughput.

// ─── Build lookup maps ────────────────────────────────────────────────────────

/**
 * Load all additives and build a Map<code, health_rating>.
 * E.g. Map { "E110" => 20, "E330" => 100, ... }
 *
 * @param {object} db - mongoose.connection.db
 * @returns {Promise<Map<string, number>>}
 */
async function buildAdditivesMap(db) {
  const docs = await db
    .collection("additives")
    .find({}, { projection: { code: 1, health_rating: 1 } })
    .toArray();

  const map = new Map();
  for (const doc of docs) {
    if (!doc.code) continue;
    const rating = parseFloat(doc.health_rating);
    if (Number.isFinite(rating)) {
      map.set(String(doc.code).trim(), rating);
    }
  }

  console.log(`  Additives map: ${map.size} entries loaded`);
  return map;
}

/**
 * Load all ingredients and build a dual-key Map:
 *   Key type A → ObjectId string     : "507f1f77bcf86cd799439011" => 97
 *   Key type B → canonical_name lower: "mango"                    => 97
 *
 * Dual-key enables two lookup paths inside cphs.service.js:
 *   1. ingredient_id (ObjectId) — fastest, most reliable
 *   2. name (string match)      — fallback when ingredient_id is missing
 *
 * @param {object} db
 * @returns {Promise<Map<string, number>>}
 */
async function buildIngredientsMap(db) {
  const docs = await db
    .collection("ingredients")
    .find({}, { projection: { _id: 1, canonical_name: 1, health_rating: 1 } })
    .toArray();

  const map = new Map();
  for (const doc of docs) {
    const rating = parseFloat(doc.health_rating);
    if (!Number.isFinite(rating)) continue;

    // Key A: ObjectId string
    map.set(String(doc._id), rating);

    // Key B: canonical_name lowercase
    if (doc.canonical_name) {
      map.set(doc.canonical_name.trim().toLowerCase(), rating);
    }
  }

  console.log(`  Ingredients map: ${map.size} entries loaded (${docs.length} documents × 2 keys)`);
  return map;
}

// ─── Core batch processor ─────────────────────────────────────────────────────

/**
 * Process a single variant: compute CPHS and return a bulkWrite operation.
 *
 * @param {object} variant       - raw document from product_variants
 * @param {Map}    additivesMap
 * @param {Map}    ingredientsMap
 * @returns {{ op: object, result: object }}
 */
function processVariant(variant, additivesMap, ingredientsMap) {
  const result = calculateCPHS(variant, additivesMap, ingredientsMap);

  const op = {
    updateOne: {
      filter: { _id: variant._id },
      update: {
        $set: {
          cphs_final:   result.cphs_final,
          health_label: result.health_label,
          health_stars: result.health_stars
        }
      }
    }
  };

  return { op, result };
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const MONGO_URI = process.env.MONGO_URI;
  if (!MONGO_URI) {
    console.error("ERROR: MONGO_URI not set in environment / .env");
    process.exit(1);
  }

  console.log("\n══════════════════════════════════════════════");
  console.log("  CPHS v2.5 — Batch Computation Script");
  console.log("══════════════════════════════════════════════");
  if (DRY_RUN)   console.log("  MODE: DRY RUN (no writes)");
  if (SINGLE_ID) console.log(`  MODE: SINGLE variant — ${SINGLE_ID}`);
  console.log();

  // ── Connect ────────────────────────────────────────────────
  await mongoose.connect(MONGO_URI);
  console.log("✔ MongoDB connected\n");

  const db = mongoose.connection.db;

  // ── Build lookup maps (one query each) ────────────────────
  console.log("Loading lookup maps...");
  const additivesMap   = await buildAdditivesMap(db);
  const ingredientsMap = await buildIngredientsMap(db);
  console.log();

  // ── Build query filter ────────────────────────────────────
  const variantsCol = db.collection("product_variants");

  let filter = {};
  if (SINGLE_ID) {
    if (!mongoose.Types.ObjectId.isValid(SINGLE_ID)) {
      console.error(`ERROR: Invalid ObjectId — "${SINGLE_ID}"`);
      await mongoose.disconnect();
      process.exit(1);
    }
    filter = { _id: new mongoose.Types.ObjectId(SINGLE_ID) };
  }

  const totalCount = await variantsCol.countDocuments(filter);
  console.log(`Product variants to process: ${totalCount}\n`);

  if (totalCount === 0) {
    console.log("Nothing to process. Exiting.");
    await mongoose.disconnect();
    return;
  }

  // ── Stats ─────────────────────────────────────────────────
  let processed = 0;
  let written   = 0;
  let errors    = 0;

  const labelCounts = {
    very_good: 0,
    good:      0,
    okay:      0,
    poor:      0,
    very_poor: 0
  };

  // ── Batch cursor ──────────────────────────────────────────
  const cursor = variantsCol.find(filter, {
    projection: {
      _id:                  1,
      nutriscore_score_raw: 1,
      nutriments:           1,
      nova_group:           1,
      ingredient_summary:   1,
      additives:            1,
      title:                1
    }
  });

  let batch = [];

  const flushBatch = async () => {
    if (batch.length === 0) return;

    if (!DRY_RUN) {
      try {
        const bulkOps = batch.map(b => b.op);
        const bulkRes = await variantsCol.bulkWrite(bulkOps, { ordered: false });
        written += bulkRes.modifiedCount;
      } catch (err) {
        console.error(`  bulkWrite error: ${err.message}`);
        errors += batch.length;
      }
    } else {
      written += batch.length;   // count as "would write" in dry-run
    }

    batch = [];
  };

  // ── Main loop ─────────────────────────────────────────────
  console.log("Processing...\n");

  for await (const variant of cursor) {
    try {
      const { op, result } = processVariant(variant, additivesMap, ingredientsMap);
      batch.push({ op, result });
      labelCounts[result.health_label] = (labelCounts[result.health_label] || 0) + 1;
      processed++;

      // Log individual result for single-variant mode or every LOG_EVERY
      if (SINGLE_ID) {
        console.log(`  Title       : ${variant.title || "(no title)"}`);
        console.log(`  cphs_score  : ${result.cphs_score}/100`);
        console.log(`  health_label: ${result.health_label}`);
        console.log(`  health_stars: ${result.health_stars}`);
        console.log(`  Breakdown   :`, result.breakdown);
        console.log();
      } else if (processed % LOG_EVERY === 0) {
        console.log(`  → ${processed}/${totalCount} processed...`);
      }

    } catch (err) {
      console.error(`  ERROR on variant ${variant._id}: ${err.message}`);
      errors++;
    }

    // Flush when batch is full
    if (batch.length >= BATCH_SIZE) {
      await flushBatch();
    }
  }

  // Flush any remaining
  await flushBatch();

  // ── Summary ───────────────────────────────────────────────
  console.log("\n══════════════════════════════════════════════");
  console.log("  SUMMARY");
  console.log("══════════════════════════════════════════════");
  console.log(`  Variants processed : ${processed}`);
  console.log(`  Written to DB      : ${DRY_RUN ? `${written} (dry run — no actual writes)` : written}`);
  console.log(`  Errors             : ${errors}`);
  console.log();
  console.log("  Score distribution:");
  console.log(`    ★★★★★  very_good  (85-100) : ${labelCounts.very_good}`);
  console.log(`    ★★★★   good       (60-84)  : ${labelCounts.good}`);
  console.log(`    ★★★    okay       (40-59)  : ${labelCounts.okay}`);
  console.log(`    ★★     poor       (20-39)  : ${labelCounts.poor}`);
  console.log(`    ★      very_poor  (0-19)   : ${labelCounts.very_poor}`);
  console.log("══════════════════════════════════════════════\n");

  await mongoose.disconnect();
  console.log("✔ MongoDB disconnected. Done.\n");
}

main().catch(err => {
  console.error("Fatal error:", err);
  process.exit(1);
});