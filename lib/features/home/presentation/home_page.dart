import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_service.dart';
import '../../../core/ui/widgets/top_header.dart';
import '../../../core/ui/widgets/top_categories.dart';
import '../../../core/ui/widgets/bottom_nav_bar.dart';
import '../../../core/ui/widgets/bottom_nav_onboarding.dart';

import '../../categories/presentation/top_categories_page.dart';
import '../../categories/presentation/category_page.dart';
import '../../scan/presentation/barcode_scan_page.dart';
import '../../search/presentation/search_page.dart';
import '../../ocr/presentation/ocr_scan_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;

  final List<GlobalKey> _navKeys = List.generate(5, (_) => GlobalKey());

  late final Future<List<CategoryItem>> _categoriesFuture =
  _fetchTopCategories();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<List<CategoryItem>> _fetchTopCategories() async {
    final response = await ApiService.get('/v1/categories?level=1&limit=6');
    // ignore: avoid_print
    print('HomePage: raw response -> $response');
    if (response is Map && response['data'] is List) {
      final List data = response['data'];
      return data.map<CategoryItem>((c) {
        return CategoryItem(
          id: (c['_id'] ?? '').toString(),
          slug: (c['slug'] ?? '').toString(),
          title: (c['name'] ?? '').toString(),
          imageUrl: null,
          productCount: null,
        );
      }).toList();
    }
    throw Exception('Invalid category response shape');
  }

  void _openSearch() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const SearchPage()));

  void _openScan() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const BarcodeScanPage()));

  void _openTopCategories() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const TopCategoriesPage()));

  void _openCategory(CategoryItem category) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CategoryPage(
              topSlug: category.slug, topTitle: category.title)));

  void _openSmartRead() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const OCRScanPage()));

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0A1612),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // Header
              SliverToBoxAdapter(
                child: TopHeader(
                  avatarAsset: 'images/home_page_images/user_logo.png',
                  onSearchTap: _openSearch,
                ),
              ),

              // Hero scan banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                  child: _HeroBanner(
                    onScanTap: _openScan,
                    onSmartReadTap: _openSmartRead,
                  ),
                ),
              ),

              // Section label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9E7A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Top Categories',
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE8F5F1),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openTopCategories,
                        child: Text(
                          'View all',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0D9E7A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: FutureBuilder<List<CategoryItem>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0D9E7A),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF162320),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.red.shade900.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off_rounded,
                                  size: 32, color: Colors.red.shade400),
                              const SizedBox(height: 10),
                              Text(
                                'Failed to load categories',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade300,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                snapshot.error.toString(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: const Color(0xFF7AB5A6)),
                              ),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () => setState(() {}),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9E7A)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                        color: const Color(0xFF0D9E7A)
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    'Retry',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0D9E7A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final categories = snapshot.data ?? [];
                    return _DarkCategories(
                      categories: categories,
                      onViewAll: _openTopCategories,
                      onCategoryTap: _openCategory,
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),

          bottomNavigationBar: BottomNavBar(
            selectedIndex: _selectedTab,
            navKeys: _navKeys,
            onTabSelected: (index) {
              setState(() => _selectedTab = index);
              if (index == 1) _openSearch();
              if (index == 2) _openScan();
              if (index == 3) _openTopCategories();
              if (index == 4) _openSmartRead();
            },
          ),
        ),

        BottomNavOnboarding(navKeys: _navKeys),
      ],
    );
  }
}

// ── Hero scan banner ──────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onSmartReadTap;

  const _HeroBanner({
    required this.onScanTap,
    required this.onSmartReadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162320),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF0D9E7A).withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9E7A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
              border:
              Border.all(color: const Color(0xFF0D9E7A).withValues(alpha: 0.3)),
            ),
            child: Text(
              '✦  INSTANT ANALYSIS',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: const Color(0xFF0D9E7A),
              ),
            ),
          ),

          const SizedBox(height: 12),

          RichText(
            text: TextSpan(
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE8F5F1),
                height: 1.25,
              ),
              children: [
                const TextSpan(text: 'Scan any product,\nget the '),
                TextSpan(
                  text: 'full truth',
                  style: GoogleFonts.dmSerifDisplay(
                    fontStyle: FontStyle.italic,
                    fontSize: 24,
                    color: const Color(0xFF1DB890),
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Barcodes, ingredient lists, health scores — instantly.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF7AB5A6),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onScanTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9E7A),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9E7A).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Scan Barcode',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onSmartReadTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9E7A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF0D9E7A).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.document_scanner_rounded,
                            color: const Color(0xFF1DB890), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Smart Read',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF1DB890),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dark categories row ───────────────────────────────────────────────────────

class _DarkCategories extends StatelessWidget {
  final List<CategoryItem> categories;
  final VoidCallback onViewAll;
  final void Function(CategoryItem) onCategoryTap;

  const _DarkCategories({
    required this.categories,
    required this.onViewAll,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    const int visibleCount = 6;

    return SizedBox(
      height: 118,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: visibleCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index < categories.length) {
            final item = categories[index];
            return _DarkCategoryCard(
              item: item,
              onTap: () => onCategoryTap(item),
            );
          }
          return _DarkPlaceholderCard();
        },
      ),
    );
  }
}

class _DarkCategoryCard extends StatelessWidget {
  final CategoryItem item;
  final VoidCallback onTap;

  const _DarkCategoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: const Color(0xFF162320),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF0D9E7A).withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9E7A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.category_rounded,
                  color: const Color(0xFF0D9E7A).withValues(alpha: 0.6), size: 24),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFB0D4CC),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkPlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF162320),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF0D9E7A).withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded,
              color: const Color(0xFF0D9E7A).withValues(alpha: 0.2), size: 24),
          const SizedBox(height: 8),
          Text(
            'Coming\nSoon',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFF4A7A70),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
