# CPHS Validation Plan

CPHS (Comprehensive Product Health Score) is a **custom heuristic ranking score**, not a medical diagnostic or clinically validated health prediction model.

## Current automated validation

The repository now includes unit tests covering:

- 0–100 score bounds
- NOVA 4 processing penalty
- explicit sugar penalty
- additive penalty
- missing ingredient-rating fallback

Run:

```bash
cd ScanToKnow-Backend-main
npm test
```

## Recommended empirical validation

To establish external validity, create a labelled evaluation set containing a representative sample of packaged foods. For each product, record the product nutrition data, ingredient list, additive list, NOVA classification, an established reference label (for example, an independently sourced nutrition classification), and the CPHS output.

Evaluate:

1. Spearman rank correlation for ranking agreement.
2. Pearson correlation for linear association.
3. MAE/RMSE for numeric agreement where a numeric reference is appropriate.
4. Confusion matrix, precision, recall and macro-F1 after mapping scores to the five CPHS bands.
5. Sensitivity analysis for ingredient weights, sugar penalty, NOVA multipliers and additive multiplier.
6. Ablation studies showing the effect of removing each CPHS component.

Until this study is completed, documentation and resumes should describe CPHS as a **custom, interpretable heuristic scoring framework**.
