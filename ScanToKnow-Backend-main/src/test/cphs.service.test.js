import test from "node:test";
import assert from "node:assert/strict";
import { calculateCPHS } from "../services/cphs.service.js";

const maps = {
  additives: new Map([
    ["E110", 20],
    ["E330", 100],
  ]),
  ingredients: new Map([
    ["sugar", 20],
    ["oats", 95],
    ["water", 100],
  ]),
};

function variant(overrides = {}) {
  return {
    nutriscore_score_raw: 0,
    nutriments: {
      energy_kcal_100g: 100,
      sugar_g_100g: 4,
      saturated_fat_g_100g: 1,
      sodium_g_100g: 0.1,
      fiber_g_100g: 3,
      protein_g_100g: 5,
      fruit_veg_pct: 50,
    },
    nova_group: 1,
    ingredient_summary: [
      { name: "oats" },
      { name: "water" },
    ],
    additives: [],
    ...overrides,
  };
}

test("CPHS stays within the documented 0-100 range", () => {
  const result = calculateCPHS(variant(), maps.additives, maps.ingredients);
  assert.ok(result.cphs_score >= 0 && result.cphs_score <= 100);
  assert.ok(result.cphs_final >= 0 && result.cphs_final <= 1);
});

test("NOVA 4 applies a stronger processing penalty than NOVA 1", () => {
  const base = calculateCPHS(variant({ nova_group: 1 }), maps.additives, maps.ingredients);
  const upf = calculateCPHS(variant({ nova_group: 4 }), maps.additives, maps.ingredients);
  assert.ok(upf.cphs_score < base.cphs_score);
  assert.equal(upf.breakdown.M_NOVA, 0.75);
});

test("high sugar applies the explicit sugar penalty", () => {
  const low = calculateCPHS(variant({ nutriments: { ...variant().nutriments, sugar_g_100g: 4 } }), maps.additives, maps.ingredients);
  const high = calculateCPHS(variant({ nutriments: { ...variant().nutriments, sugar_g_100g: 25 } }), maps.additives, maps.ingredients);
  assert.equal(low.breakdown.P_Sugar, 0);
  assert.equal(high.breakdown.P_Sugar, 0.25);
  assert.ok(high.cphs_score < low.cphs_score);
});

test("worst additive lowers the score", () => {
  const clean = calculateCPHS(variant(), maps.additives, maps.ingredients);
  const withBadAdditive = calculateCPHS(
    variant({ additives: [{ code: "E110" }] }),
    maps.additives,
    maps.ingredients,
  );
  assert.ok(withBadAdditive.cphs_score < clean.cphs_score);
});

test("missing ingredient ratings use a stable fallback", () => {
  const result = calculateCPHS(
    variant({ ingredient_summary: [{ name: "unknown ingredient" }] }),
    maps.additives,
    maps.ingredients,
  );
  assert.equal(result.breakdown.S_Ing, 0.65);
});
