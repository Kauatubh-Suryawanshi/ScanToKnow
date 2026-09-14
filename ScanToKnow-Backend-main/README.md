# ScanToKnow Backend

Node.js/Express backend for the ScanToKnow food-intelligence application.

## Responsibilities

- Barcode/product/variant lookup
- MongoDB Atlas data access
- Atlas Search autocomplete and full search
- OCR.Space integration
- Ingredient/additive extraction and fuzzy entity resolution
- CPHS computation and batch recomputation
- Category-aware alternative recommendations

## Run

```bash
cp .env.example .env
npm install
npm start
```

Development:

```bash
npm run dev
```

Tests:

```bash
npm test
```

## Environment

See `.env.example`. Never commit `.env`.

## Health endpoints

- `GET /health` — process liveness
- `GET /ready` — MongoDB readiness

## OCR endpoint

`POST /v1/ocr/scan` with multipart field `image`.

Security controls include an 8 MB file limit, MIME validation and a dedicated OCR rate limiter.

## CPHS batch job

```bash
node src/scripts/computeCphs.js --dry-run
node src/scripts/computeCphs.js
node src/scripts/computeCphs.js --id <variantId>
```

See the root README and `docs/CPHS_VALIDATION.md` for the scoring model and validation approach.
