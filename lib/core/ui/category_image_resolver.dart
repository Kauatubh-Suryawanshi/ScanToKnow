// lib/core/ui/category_image_resolver.dart
// central place to map category slug -> local asset path
// update this map whenever you add new assets to images/home_page_images/
// NOTE: This file preserves the original top-category logic and only adds
//       a drinks subcategory resolution before falling back to the original code.

String? assetForCategorySlug(String slug) {
  final s = slug.toLowerCase();

  // -------------------------
  // NEW: drinks subcategory support
  // -------------------------
  // If this slug matches a known drinks subcategory slug, return the subcategory asset.
  // We only add support for the drinks subfolder here (images/categories/drinks/<slug>.png).
  // This is deterministic (no runtime asset checks). Make sure these files exist.
  const drinksSubcategorySlugs = <String>{
    '100-percent-fruit-juices',
    'fruit-drinks-nectars',
    'carbonated-soft-drinks',
    'masala-sparkling-sodas',
    'ethnic-still-beverages',
    'energy-sports-drinks',
    'non-alcoholic-malts-beers',
    'mixers-tonics',
    'concentrates-instant-mixes',
    'wellness-juices',
    'dairy-based-beverages',
    'packaged-waters',
  };

  if (drinksSubcategorySlugs.contains(s)) {
    return 'images/categories/drinks/$s.png';
  }

  // -------------------------
  // ORIGINAL resolver code (unchanged)
  // -------------------------
  const mapping = <String, String>{
    // exact matches (use the filenames you already have)
    'drinks': 'images/home_page_images/drinks.png',
    'noodles_&_pasta': 'images/home_page_images/noodles_&_pasta.png',
    'noodles-and-pasta': 'images/home_page_images/noodles_&_pasta.png',
    'noodles': 'images/home_page_images/noodles_&_pasta.png',
    'chips': 'images/home_page_images/chips.png',
    'chips-&-crunch': 'images/home_page_images/chips.png',
    'chips-and-crunch': 'images/home_page_images/chips.png',
    'chocolates': 'images/home_page_images/chocolate.png',
    'chocolate': 'images/home_page_images/chocolate.png',
    'biscuits': 'images/home_page_images/cookies.png',
    'cookies': 'images/home_page_images/cookies.png',
    'namkeen': 'images/home_page_images/namkeen.png',
    // add more slug -> asset mappings here as you add assets
  };

  // direct lookup
  if (mapping.containsKey(s)) return mapping[s];

  // some heuristic checks
  if (s.contains('drink')) return 'images/home_page_images/drinks.png';
  if (s.contains('noodl')) return 'images/home_page_images/noodles_&_pasta.png';
  if (s.contains('chip')) return 'images/home_page_images/chips.png';
  if (s.contains('chocolate') || s.contains('choco')) return 'images/home_page_images/chocolate.png';
  if (s.contains('biscuit') || s.contains('cookie')) return 'images/home_page_images/cookies.png';
  if (s.contains('namkeen') || s.contains('savory')) return 'images/home_page_images/namkeen.png';

  // final fallback (must exist)
  return 'images/home_page_images/drinks.png';
}
