<div align="center">

# 🍎 ScanToKnow

### Food Intelligence, Ingredient Analysis & Health-Aware Product Discovery Platform

**Scan → Identify → Analyze → Explain → Score → Compare → Discover**

<p>
  <img src="https://img.shields.io/badge/Flutter-App-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.9%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Node.js-Backend-339933?style=for-the-badge&logo=node.js&logoColor=white" alt="Node.js">
  <img src="https://img.shields.io/badge/Express.js-API-000000?style=for-the-badge&logo=express&logoColor=white" alt="Express.js">
  <img src="https://img.shields.io/badge/MongoDB-Atlas-47A248?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB Atlas">
  <img src="https://img.shields.io/badge/ML%20Kit-Barcode%20Scanning-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="Google ML Kit">
  <img src="https://img.shields.io/badge/OCR.Space-OCR-6C63FF?style=for-the-badge" alt="OCR.Space">
  <img src="https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/License-MIT-2EA44F?style=for-the-badge" alt="MIT License">
</p>

**[💻 GitHub Repository](<YOUR_GITHUB_REPOSITORY_URL>)**

</div>

---

## 🎯 What is ScanToKnow?

**ScanToKnow** is an end-to-end food intelligence platform that transforms packaged-food information into structured, understandable product analysis.

Instead of stopping at barcode lookup, ScanToKnow connects scanning, OCR, ingredient intelligence, nutrition analysis, food-processing classification, health-oriented scoring, product search and alternative discovery into one workflow.

```text
Food Product
      ↓
Barcode / Ingredient Label
      ↓
Barcode Detection / OCR
      ↓
Product & Ingredient Resolution
      ↓
Nutrition + Ingredient + Additive Analysis
      ↓
NOVA Processing Classification
      ↓
CPHS Health-Oriented Score
      ↓
Product Explanation
      ↓
Search / Comparison / Alternatives
```

---

# ⭐ Why ScanToKnow Stands Out

ScanToKnow is designed as a **Software Engineering + Data Intelligence + Mobile + Backend** portfolio project rather than a basic barcode scanner.

### Multi-input food intelligence

The application supports both:

- **Barcode-based product identification**
- **Ingredient-label OCR**

### Entity-resolution pipeline

OCR text can be imperfect. ScanToKnow therefore uses normalization, exact matching, aliases, partial matching and fuzzy matching with **Levenshtein distance**.

### Multi-factor product scoring

The **Comprehensive Product Health Score (CPHS)** combines nutrition, ingredients, sugar, NOVA processing and additive-related signals.

### Product-aware discovery

The system separates products and product variants and provides category-aware healthier-alternative logic.

### Backend-oriented architecture

The project uses a structured REST backend with routes, controllers, services, models, validation, security middleware and tests.

---

# 📸 Product Walkthrough

ScanToKnow is designed around a mobile-first product workflow.

Recommended repository screenshots can be stored under:

```text
docs/screenshots/
```

Example screenshot organization:

```text
docs/screenshots/
├── 01-home.png
├── 02-barcode-scanner.png
├── 03-product-details.png
├── 04-ingredient-ocr.png
├── 05-ingredient-analysis.png
├── 06-nutrition-analysis.png
├── 07-cphs-score.png
├── 08-search.png
├── 09-categories.png
└── 10-healthier-alternatives.png
```

> Add only screenshots that actually exist in the repository. The README intentionally does not claim screenshot files that are not present.

---

## 1. Home

The Home experience provides the primary entry points into product scanning, food discovery and the application's core workflows.

```text
Home
 ↓
Scan Product
Search Product
Explore Categories
Ingredient Analysis
```

---

## 2. Barcode Scanner

The barcode workflow uses the device camera and Google ML Kit to detect product barcodes.

```text
Camera
   ↓
Google ML Kit
   ↓
Barcode
   ↓
REST API
   ↓
Product / Variant Lookup
```

---

## 3. Product Details

After a successful barcode lookup, the application can present product information including product identity, variant information, nutrition and ingredient-related intelligence.

```text
Barcode
   ↓
Product Variant
   ↓
Parent Product
   ↓
Nutrition
   ↓
Ingredients
   ↓
Additives
   ↓
CPHS
```

---

## 4. Ingredient OCR

Ingredient labels can be captured through the camera and processed through the OCR pipeline.

```text
Ingredient Label Image
        ↓
Image Capture
        ↓
Multipart Upload
        ↓
Backend Validation
        ↓
OCR.Space
        ↓
Ingredient Text
```

---

## 5. Ingredient Analysis

OCR output is normalized and matched against the ingredient knowledge base.

```text
OCR Text
   ↓
Normalization
   ↓
Exact Match
   ↓
Alias Match
   ↓
Partial Match
   ↓
Fuzzy Match
   ↓
Levenshtein Distance
   ↓
Resolved Entity
```

---

## 6. Nutrition Analysis

Product nutrition data can be presented as part of the overall product-analysis workflow.

Nutrition is also one of the major inputs into the CPHS scoring engine.

---

## 7. CPHS Score

The Comprehensive Product Health Score converts multiple signals into a normalized score from **0 to 100**.

```text
Nutrition
   +
Ingredients
   +
Sugar
   +
NOVA
   +
Additives
   ↓
CPHS
   ↓
0–100 Product Score
```

---

## 8. Search

The search workflow uses MongoDB Atlas Search to support product discovery, autocomplete and filtering.

```text
Search Query
    ↓
Flutter Search UI
    ↓
REST API
    ↓
MongoDB Atlas Search
    ↓
Matching Products
    ↓
Paginated Results
```

---

## 9. Categories

Products can be organized through the category hierarchy and explored through category-specific product queries.

---

## 10. Healthier Alternatives

The alternative engine compares relevant products and applies category-aware rules to identify potentially healthier options.

```text
Current Product
      ↓
Category
      ↓
Comparable Products
      ↓
CPHS Evaluation
      ↓
Category Rules
      ↓
Ranked Alternatives
```

The current implementation includes dedicated category-aware logic for **Drinks**, with future expansion possible for additional categories.

---

# 🧠 End-to-End Food Intelligence Workflow

```text
                         ┌──────────────────────┐
                         │      ScanToKnow      │
                         │   Flutter Frontend   │
                         └──────────┬───────────┘
                                    │
                   ┌────────────────┴────────────────┐
                   ↓                                 ↓
             Barcode Scan                       Ingredient OCR
                   ↓                                 ↓
             Google ML Kit                       OCR.Space
                   └────────────────┬────────────────┘
                                    ↓
                           Express REST API
                                    ↓
                           MongoDB Atlas
                                    ↓
                 ┌──────────────────┼──────────────────┐
                 ↓                  ↓                  ↓
             Products          Ingredients          Additives
                 │                  │                  │
                 └──────────────────┼──────────────────┘
                                    ↓
                           Nutrition Analysis
                                    ↓
                            NOVA Classification
                                    ↓
                         CPHS Scoring Engine
                                    ↓
                     Product Search / Comparison
                                    ↓
                       Healthier Alternatives
                                    ↓
                         User-Friendly Result
```

---

# 📊 Application Capabilities

| Capability | Implementation |
|---|---|
| Product identification | Barcode scanning |
| Barcode detection | Google ML Kit |
| Ingredient extraction | OCR.Space |
| OCR processing | Ingredient-section extraction and E-code detection |
| Entity resolution | Exact, alias, partial and fuzzy matching |
| Fuzzy matching | Levenshtein distance |
| Nutrition analysis | Structured product nutrition data |
| Food processing | NOVA classification |
| Health-oriented scoring | Comprehensive Product Health Score (CPHS) |
| Additive intelligence | Additive codes, names and risk signals |
| Product discovery | MongoDB Atlas Search |
| Autocomplete | Search suggestion endpoint |
| Alternatives | Category-aware rule-based engine |
| Product modeling | Product + Product Variant architecture |
| Mobile UI | Flutter |
| API | Node.js + Express |
| Database | MongoDB Atlas |
| Image upload | Multer |
| Security | Helmet, CORS, limits and validation |
| Reliability | Health/readiness endpoints and graceful shutdown |
| Testing | Node.js native test runner |
| CI | GitHub Actions |

---

# 📷 Barcode Scanning

ScanToKnow uses **Google ML Kit Barcode Scanning** for on-device barcode detection.

### Why ML Kit?

Barcode scanning requires fast camera-based detection. Using an established mobile computer-vision library avoids the complexity of building and maintaining a custom barcode-detection model.

### Workflow

```text
Camera Frame
     ↓
Barcode Detection
     ↓
Barcode Value
     ↓
Backend Request
     ↓
Database Lookup
```

---

# 🧾 Ingredient OCR

The OCR workflow provides an alternative when product identification or ingredient understanding requires reading the physical label.

### OCR pipeline

```text
Camera Image
     ↓
Upload
     ↓
Validation
     ↓
OCR.Space
     ↓
Raw Text
     ↓
Ingredient Section
     ↓
E-Code Detection
     ↓
Entity Resolution
```

The pipeline recognizes common additive formats such as:

```text
E330
E 330
INS 330
INS-330
E150D
```

---

# 🧠 Ingredient Entity Resolution

OCR output can contain spelling and formatting errors.

ScanToKnow uses a layered matching approach:

```text
Raw OCR Term
     ↓
Text Normalization
     ↓
Exact Database Match
     ↓
Alias Match
     ↓
Partial Match
     ↓
Fuzzy Match
     ↓
Levenshtein Distance
     ↓
Resolved Ingredient / Additive
```

This approach improves resilience when the extracted OCR text differs slightly from the stored database representation.

---

# 🧪 Ingredient & Additive Intelligence

The data model supports structured information for:

- Ingredients
- Ingredient aliases
- Additives
- Additive codes
- Additive names
- Ingredient ratings
- Additive risk signals
- Product relationships

This converts a raw ingredient list into structured analytical information.

---

# 💯 Comprehensive Product Health Score — CPHS

CPHS is an application-specific heuristic scoring engine that produces a normalized product score between **0 and 100**.

### Formula

```text
CPHS = clamp(
    ((0.60 × S_Nutri) + (0.40 × S_Ing) − P_Sugar)
    × M_NOVA
    × M_Add,
    0,
    1
)

Final Score = round(CPHS × 100)
```

### Core inputs

```text
Nutrition
   ↓
Ingredient Quality
   ↓
Sugar Penalty
   ↓
NOVA Multiplier
   ↓
Additive Multiplier
   ↓
Final CPHS
```

---

# 🥗 CPHS Components

## Nutritional Component

The nutrition component contributes **60%** of the base score.

```text
S_Nutri
```

---

## Ingredient Component

The ingredient component contributes **40%**.

| Component | Weight |
|---|---:|
| Primary ingredient quality | 35% |
| Secondary ingredient quality | 30% |
| Ingredient profile | 25% |
| Additional ingredient signals | 7% |
| Other signals | 3% |

---

# 🍬 Sugar Penalty

Sugar-related signals can reduce the base score through the application's sugar penalty mechanism.

```text
Base Score
    ↓
Sugar Evaluation
    ↓
Sugar Penalty
    ↓
NOVA Adjustment
    ↓
Additive Adjustment
    ↓
Final CPHS
```

---

# 🏭 NOVA Classification

ScanToKnow incorporates NOVA-style food-processing classification.

| NOVA Group | Multiplier |
|---|---:|
| NOVA 1 | 1.00 |
| NOVA 2 | 0.95 |
| NOVA 3 | 0.90 |
| NOVA 4 | 0.75 |

NOVA 4 receives the strongest scoring adjustment in the current implementation.

---

# ⚠️ Additive Risk Adjustment

Additive-related signals can influence the final CPHS.

This makes the score multi-dimensional instead of depending only on calories, sugar or a single nutritional measurement.

---

# ⭐ CPHS Interpretation

| Score | Classification | Rating |
|---:|---|---|
| 85–100 | Very Good | ★★★★★ |
| 60–84 | Good | ★★★★ |
| 40–59 | Okay | ★★★ |
| 20–39 | Poor | ★★ |
| 0–19 | Very Poor | ★ |

> **Important:** CPHS is an application-specific heuristic intended for product comparison and educational use. It is not a medical diagnosis, clinical assessment or substitute for professional nutrition advice.

---

# 🔎 Product Search

ScanToKnow uses **MongoDB Atlas Search** for product discovery.

### Supported search functionality

- Product search
- Autocomplete
- Category filtering
- Product lookup
- Pagination
- Variant resolution

### Search flow

```text
User Query
    ↓
Flutter Search UI
    ↓
Express API
    ↓
MongoDB Atlas Search
    ↓
Product Matching
    ↓
Pagination / Filters
    ↓
Search Results
```

---

# 🔄 Healthier Alternatives

The current alternative engine is rule-based and category-aware.

```text
Selected Product
      ↓
Determine Category
      ↓
Retrieve Comparable Products
      ↓
Evaluate CPHS
      ↓
Apply Category Rules
      ↓
Rank Candidates
      ↓
Display Alternatives
```

The current implementation includes dedicated logic for **Drinks**.

Future category expansion can include:

- Snacks
- Cereals
- Biscuits
- Dairy
- Sauces
- Instant foods
- Frozen foods
- Other packaged-food categories

---

# 🗂️ Database Architecture

ScanToKnow uses **MongoDB Atlas**.

```text
MongoDB Atlas
│
├── products
├── product_variants
├── ingredients
├── additives
└── categories
```

---

# 📦 Product vs Product Variant

The application separates parent product information from individual variants.

### Product

Represents the parent product/entity.

### Product Variant

Represents a specific variation such as:

- Barcode
- SKU
- Pack size
- Regional version
- Packaging variation
- Product-specific nutrition data

This structure allows multiple variants to be associated with a parent product.

---

# 🏗️ Backend Architecture

The backend follows a modular Node.js + Express architecture.

```text
Express Server
│
├── Routes
│
├── Controllers
│
├── Services
│
├── Models
│
├── Utilities
│
├── Configuration
│
├── Scripts
│
└── Tests
```

### Main backend responsibilities

- REST API routing
- Product retrieval
- Barcode lookup
- Search
- Category browsing
- OCR processing
- Ingredient resolution
- CPHS calculation
- Alternative recommendations
- Security and request validation

---

# 🌐 API Overview

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/health` | Health check |
| GET | `/ready` | Readiness check |
| GET | `/v1/categories` | List categories |
| GET | `/v1/categories/:id` | Get category |
| GET | `/v1/categories/:id/children` | Get child categories |
| GET | `/v1/categories/:id/products` | Get category products |
| GET | `/v1/products/:id` | Get product |
| GET | `/v1/variants/:id` | Get product variant |
| GET | `/v1/scan/:barcode` | Find product by barcode |
| GET | `/v1/search` | Search products |
| GET | `/v1/search/autocomplete` | Search suggestions |
| GET | `/v1/variants/:id/alternatives` | Find alternatives |
| POST | `/v1/ocr/scan` | Process ingredient image |

---

# 🔐 Security & Reliability

The backend includes defensive engineering measures.

### Security

- Helmet security headers
- CORS configuration
- Request-size limits
- OCR upload validation
- Rate limiting
- Controlled external API requests
- Environment-based configuration

### Reliability

- Health endpoint
- Readiness endpoint
- Graceful shutdown
- Database connection handling
- External OCR error handling
- Request validation
- Controlled upload processing

---

# 🧪 Testing

The backend uses the native **Node.js test runner**.

Current CPHS tests cover:

- Score range validation
- NOVA 4 penalty behavior
- High-sugar penalty
- Additive-risk impact
- Missing ingredient-rating fallback

The MongoDB integration test is optional and can be enabled when a valid MongoDB connection is available.

### Run tests

```bash
npm test
```

Expected normal suite:

```text
5 passed
0 failed
1 skipped
```

The skipped test is the optional MongoDB integration test.

---

# 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| Mobile application | Flutter |
| Language | Dart |
| Backend runtime | Node.js |
| API framework | Express.js |
| ODM | Mongoose |
| Database | MongoDB Atlas |
| Search | MongoDB Atlas Search |
| Barcode scanning | Google ML Kit |
| OCR | OCR.Space |
| Image upload | Multer |
| HTTP client | Axios / HTTP |
| Security headers | Helmet |
| Cross-origin requests | CORS |
| Logging | Morgan |
| Configuration | dotenv |
| Fuzzy matching | Levenshtein distance |
| Product scoring | CPHS |
| Food processing | NOVA classification |
| Testing | Node.js native test runner |
| CI | GitHub Actions |
| Version control | Git / GitHub |

---

# 📁 Repository Structure

```text
ScanToKnow/
│
├── lib/
│   ├── core/
│   │   ├── app_theme.dart
│   │   ├── config/
│   │   ├── network/
│   │   └── ui/
│   │
│   └── features/
│       ├── onboarding/
│       ├── home/
│       ├── scan/
│       ├── ocr/
│       ├── search/
│       ├── products/
│       ├── variants/
│       └── categories/
│
├── images/
│   ├── home_page_images/
│   ├── categories/
│   ├── intro_page_images/
│   └── packet_images/
│
├── ScanToKnow-Backend-main/
│   └── src/
│       ├── config/
│       ├── controllers/
│       ├── models/
│       ├── routes/
│       ├── services/
│       ├── scripts/
│       ├── test/
│       └── utils/
│
├── docs/
│   ├── ARCHITECTURE.md
│   └── CPHS_VALIDATION.md
│
├── .github/
│   └── workflows/
│
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

---

# ⚙️ Local Setup

### 1. Clone the repository

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd ScanToKnow
```

### 2. Backend setup

```bash
cd ScanToKnow-Backend-main
npm install
```

Create a `.env` file:

```env
MONGO_URI=your_mongodb_atlas_connection_string
PORT=4000
```

Start the development server:

```bash
npm run dev
```

Or:

```bash
npm start
```

Default backend:

```text
http://localhost:4000
```

---

# 📱 Flutter Setup

From the project root:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

# 🔗 Backend URL Configuration

ScanToKnow supports environment-based backend configuration.

The Flutter application uses:

```text
BACKEND_URL
```

Local development:

```bash
flutter run --dart-define=BACKEND_URL=http://localhost:4000
```

Production example:

```bash
flutter run --dart-define=BACKEND_URL=https://your-production-api.example.com
```

Do not commit real credentials or private production configuration.

---

# 📸 Platform Permissions

The application requires camera access for:

- Barcode scanning
- Ingredient-label image capture

Platform configuration includes the required camera permission descriptions.

Android development supports local HTTP communication for development environments.

---

# 🧠 Engineering Design Decisions

## Why Flutter?

Flutter provides a single cross-platform application codebase with strong camera and mobile UI support.

It is suitable for:

- Cross-platform development
- Camera integration
- Consistent UI
- Rapid iteration
- Mobile deployment

---

## Why Node.js + Express?

Node.js and Express provide a lightweight REST API layer suitable for:

- Product APIs
- MongoDB integration
- OCR integration
- Search
- Upload handling
- Rapid backend development

---

## Why MongoDB Atlas?

Food-product data is flexible and can contain different attributes between products and variants.

MongoDB supports document-oriented modeling and allows the data model to evolve as the food knowledge base expands.

MongoDB Atlas also provides managed cloud infrastructure and Atlas Search.

---

## Why Google ML Kit?

Barcode detection is a well-defined computer-vision problem.

Using Google ML Kit avoids the need to build and maintain a custom barcode detector while providing a mobile-optimized scanning workflow.

---

## Why OCR.Space?

OCR.Space provides an external OCR service that can convert ingredient-label images into text without requiring ScanToKnow to maintain its own OCR infrastructure.

The OCR provider is isolated behind the backend so it can be replaced or supplemented later.

---

## Why Levenshtein Distance?

OCR can introduce small character-level differences.

Levenshtein distance provides a practical similarity mechanism for resolving imperfect OCR output against known ingredient records.

---

## Why CPHS?

CPHS provides an application-specific framework for combining several food-related signals into one comparable score.

```text
Nutrition
    +
Ingredients
    +
Sugar
    +
NOVA
    +
Additives
    ↓
CPHS
```

---

# ⚠️ Current Limitations

ScanToKnow is an evolving engineering and academic/portfolio project.

Current limitations include:

- OCR accuracy depends on image quality
- OCR may misread uncommon ingredients
- Unknown ingredients may remain unresolved
- CPHS is a heuristic rather than a clinical assessment
- Alternative recommendations are currently rule-based
- Category-aware alternative logic is not universal
- Product coverage depends on the available database
- OCR functionality depends on the external OCR service
- Production deployment requires production infrastructure, monitoring and operational controls

---

# 🔮 Future Roadmap

## Phase 1 — Data Expansion

- Expand product database
- Expand ingredient knowledge base
- Expand additive knowledge base
- Improve category hierarchy
- Add more regional products

## Phase 2 — Ingredient Intelligence

- Better OCR correction
- Improved entity resolution
- Ingredient synonym graphs
- Ingredient relationships
- Improved additive modeling

## Phase 3 — Machine Learning

Potential future ML components:

```text
Ingredient Classification
        ↓
Product Classification
        ↓
Product Similarity
        ↓
Personalized Recommendation
```

Possible technologies include:

- Scikit-learn
- XGBoost
- LightGBM
- TensorFlow
- NLP models
- Transformer-based models

These are future development directions and are not claims that these technologies are currently implemented in the application.

---

# 🤖 Future AI Integration

Future versions may introduce AI-assisted capabilities such as:

- Natural-language ingredient explanations
- Conversational food assistant
- Personalized food recommendations
- AI-powered product comparison
- Multilingual ingredient explanations
- Ingredient-risk explanations
- Context-aware recommendations
- Personalized food preferences

A possible future architecture:

```text
ScanToKnow
     │
     ├── Product Database
     ├── Ingredient Knowledge Base
     ├── CPHS Engine
     ├── Search Engine
     └── AI Intelligence Layer
              │
              ├── NLP
              ├── Explanation
              ├── Recommendation
              └── Personalization
```

---

# 📊 Research & Engineering Opportunities

Potential future research areas include:

- OCR error correction
- Food ingredient entity resolution
- Ingredient knowledge graphs
- Food recommendation systems
- Explainable food scoring
- Personalized food intelligence
- Product similarity
- Multilingual food intelligence
- AI-assisted label understanding
- Food-processing classification

---

# 🎓 Academic & Portfolio Positioning

ScanToKnow demonstrates practical experience across:

### Software Engineering

- Cross-platform application development
- REST API architecture
- Modular application design
- External API integration
- Database modeling

### Data Engineering

- Product and variant modeling
- Ingredient entity resolution
- Search indexing
- Data normalization
- Structured food knowledge

### AI / ML Foundations

- OCR pipelines
- Fuzzy matching
- Classification logic
- Scoring algorithms
- Recommendation logic

### Backend Engineering

- Express APIs
- MongoDB
- Mongoose
- Validation
- Security middleware
- Rate limiting
- Error handling

### Mobile Engineering

- Flutter
- Camera integration
- Barcode scanning
- API communication
- Platform configuration

---

# 👥 Contributors

## Author & Project Lead

### **Kaustubh Suryawanshi**

Responsible for the overall project ownership, architecture, development direction, implementation, integration, maintenance and repository management.

## Contributors

- **Parth Mishra**
- **Om Majumdar**
- **Prathamesh Rane**

Contributors are acknowledged for their respective contributions to the development and evolution of ScanToKnow.

---

# 👑 Project Ownership

**Project Author / Rights Holder:**  
**Kaustubh Suryawanshi**

**Project Year:**  
**2026**

ScanToKnow is an original software project owned and maintained by **Kaustubh Suryawanshi**.

Contributors are credited for their respective contributions, while overall project ownership and intellectual property rights remain with the project author unless otherwise agreed in writing.

### 🌐 Social & Professional Profiles

- **GitHub:** https://github.com/Kauatubh-Suryawanshi
- **LinkedIn:** https://linkedin.com/in/kaustubh-suryawanshi18

---

# 📚 Documentation

Additional technical documentation:

```text
docs/
├── ARCHITECTURE.md
└── CPHS_VALIDATION.md
```

### Architecture Documentation

Contains:

- System architecture
- Barcode workflow
- OCR workflow
- Search workflow
- Backend integration
- Database interaction
- CPHS integration
- Alternative recommendation flow

### CPHS Validation

Contains information related to the scoring methodology and validation of the CPHS engine.

---

# 🛡️ Responsible Use

ScanToKnow is designed as an educational and informational food-intelligence application.

The application's scores and classifications should not be interpreted as:

- Medical advice
- Clinical diagnosis
- Professional nutrition advice
- A substitute for a doctor or qualified dietitian

Users with specific medical or dietary requirements should consult an appropriate qualified professional.

---

# 📄 License & Copyright

ScanToKnow is released under the **MIT License**.

**Copyright © 2026 Kaustubh Suryawanshi**

See [`LICENSE`](LICENSE) for the complete license text.

---

# ⚠️ Disclaimer

ScanToKnow is a software engineering and academic/portfolio project intended to demonstrate food-data processing, mobile development, backend engineering, search, OCR and health-oriented analytical concepts.

The **CPHS score, NOVA interpretation, ingredient analysis, additive analysis and alternative recommendations are application-level heuristics and should not be considered medical or clinical assessments.**

---

# 🌟 Project Vision

ScanToKnow aims to make food labels easier to understand by transforming complex product information into simple, actionable intelligence.

```text
                    RAW FOOD LABEL
                          │
                          ↓
                ┌───────────────────┐
                │    ScanToKnow      │
                └─────────┬─────────┘
                          │
          ┌───────────────┼───────────────┐
          ↓               ↓               ↓
       Barcode           OCR          Product Search
          │               │               │
          └───────────────┼───────────────┘
                          ↓
                 Ingredient Intelligence
                          ↓
                   Nutrition Analysis
                          ↓
                    NOVA Analysis
                          ↓
                    Additive Analysis
                          ↓
                       CPHS
                          ↓
                  Product Comparison
                          ↓
                 Healthier Alternatives
                          ↓
              UNDERSTAND YOUR FOOD
```

---

# 🍎 ScanToKnow

### Scan smarter. Understand better. Choose with confidence.

---

## Project Credits

**Project:** ScanToKnow  
**Year:** 2026  
**Author / Project Lead:** Kaustubh Suryawanshi  
**Contributors:** Parth Mishra · Om Majumdar · Prathamesh Rane  

**MIT License · Copyright © 2026 Kaustubh Suryawanshi**
