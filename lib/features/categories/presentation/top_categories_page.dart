import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/ui/widgets/top_categories.dart' show CategoryItem;
import '../../../core/ui/category_image_resolver.dart';
import 'category_page.dart';

// ── Inline theme tokens ───────────────────────────────────────────────────────
class _T {
  static const Color bg      = Color(0xFF0F1E1B);
  static const Color card    = Color(0xFF162320);
  static const Color border  = Color(0xFF1F3530);
  static const Color accent  = Color(0xFF0D9E7A);
  static const Color accentLt= Color(0xFF1DB890);
  static const Color textPri = Color(0xFFE8F5F1);
  static const Color textSec = Color(0xFF7AB5A6);
  static const Color textEye = Color(0xFF0D9E7A);
  static const Color bad     = Color(0xFFE74C3C);
  static const Color badBg   = Color(0xFF2A0E0E);

  static TextStyle eyebrow({Color? color}) => GoogleFonts.dmSans(
      fontSize: 10, fontWeight: FontWeight.w600,
      letterSpacing: 1.4, color: color ?? textEye);
  static TextStyle heading({double fontSize = 28}) => GoogleFonts.dmSans(
      fontSize: fontSize, fontWeight: FontWeight.w700,
      height: 1.2, color: textPri);
  static TextStyle headingAccent({double fontSize = 30}) =>
      GoogleFonts.dmSerifDisplay(
          fontStyle: FontStyle.italic, fontSize: fontSize,
          fontWeight: FontWeight.w400, color: accentLt);
  static TextStyle body({double fontSize = 15}) => GoogleFonts.dmSans(
      fontSize: fontSize, height: 1.65, color: textSec);
  static TextStyle label({Color? color, double fontSize = 12}) =>
      GoogleFonts.dmSans(
          fontSize: fontSize, fontWeight: FontWeight.w600,
          color: color ?? textPri);
}

class TopCategoriesPage extends StatefulWidget {
  const TopCategoriesPage({super.key});

  @override
  State<TopCategoriesPage> createState() => _TopCategoriesPageState();
}

class _TopCategoriesPageState extends State<TopCategoriesPage>
    with SingleTickerProviderStateMixin {
  late Future<List<CategoryItem>> _futureCategories;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _futureCategories = _fetchTopCategories();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<List<CategoryItem>> _fetchTopCategories() async {
    final response = await ApiService.get('/v1/categories?level=1&limit=100');
    // ignore: avoid_print
    print('TopCategoriesPage: raw response -> $response');

    if (response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) {
        final items = data.map<CategoryItem>((c) {
          final id   = c['_id'] ?? c['id'] ?? '';
          final slug = (c['slug'] ?? c['code'] ?? '').toString();
          final name = (c['name'] ?? c['title'] ?? '').toString();
          return CategoryItem(id: id.toString(), slug: slug, title: name,
              imageUrl: null, productCount: null);
        }).toList();
        // ignore: avoid_print
        print('TopCategoriesPage: parsed ${items.length} categories');
        return items;
      } else {
        throw Exception('Unexpected "data" shape: ${data.runtimeType}');
      }
    } else if (response is List) {
      return response.map<CategoryItem>((c) {
        final id   = c['_id'] ?? c['id'] ?? '';
        final slug = (c['slug'] ?? c['code'] ?? '').toString();
        final name = (c['name'] ?? c['title'] ?? '').toString();
        return CategoryItem(id: id.toString(), slug: slug, title: name,
            imageUrl: null, productCount: null);
      }).toList();
    } else {
      throw Exception('Unexpected response type: ${response.runtimeType}');
    }
  }

  void _openCategoryProducts(CategoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              CategoryPage(topSlug: item.slug, topTitle: item.title)),
    );
  }

  // ── Category card ───────────────────────────────────────────────────
  Widget _buildCard(CategoryItem item, int index) {
    final String? localAsset = assetForCategorySlug(item.slug);
    final bool useNetwork =
        item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - val)), child: child),
      ),
      child: GestureDetector(
        onTap: () => _openCategoryProducts(item),
        child: Container(
          decoration: BoxDecoration(
            color: _T.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _T.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(children: [
              // Teal glow blob
              Positioned(
                top: -20, right: -20,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.accent.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Column(children: [
                // Image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    color: _T.bg,
                    padding: const EdgeInsets.all(18),
                    child: useNetwork
                        ? Image.network(item.imageUrl!, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _placeholder())
                        : (localAsset != null
                        ? Image.asset(localAsset, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder()),
                  ),
                ),
                // Title
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    color: _T.card,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.title,
                              style: _T.label(fontSize: 13).copyWith(height: 1.3),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          if (item.productCount != null) ...[
                            const SizedBox(height: 4),
                            Text('${item.productCount} items',
                                style: _T.body(fontSize: 11)
                                    .copyWith(height: 1)),
                          ],
                        ]),
                  ),
                ),
              ]),
              // Ripple
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openCategoryProducts(item),
                    borderRadius: BorderRadius.circular(18),
                    splashColor: _T.accent.withValues(alpha: 0.1),
                    highlightColor: _T.accent.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Center(
    child: Icon(Icons.category_outlined,
        color: _T.textSec.withValues(alpha: 0.4), size: 36),
  );

  // ── Shimmer skeleton ────────────────────────────────────────────────
  Widget _buildShimmerCard() => AnimatedBuilder(
    animation: _shimmerController,
    builder: (_, __) {
      final s = _shimmerController.value;
      return Container(
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _T.border),
        ),
        child: Column(children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
                gradient: LinearGradient(
                  begin: Alignment(-1 + s * 2, 0),
                  end: Alignment(s * 2, 0),
                  colors: [
                    _T.bg,
                    _T.border.withValues(alpha: 0.5),
                    _T.bg,
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        height: 10, width: double.infinity,
                        decoration: BoxDecoration(
                            color: _T.border,
                            borderRadius: BorderRadius.circular(5))),
                    const SizedBox(height: 6),
                    Container(
                        height: 10, width: 60,
                        decoration: BoxDecoration(
                            color: _T.border.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(5))),
                  ]),
            ),
          ),
        ]),
      );
    },
  );

  // ── Error state ─────────────────────────────────────────────────────
  Widget _buildError(String err) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _T.badBg, shape: BoxShape.circle,
            border: Border.all(color: _T.bad.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Icon(Icons.error_outline, size: 36, color: _T.bad),
        ),
        const SizedBox(height: 20),
        Text("Couldn't load categories",
            style: _T.heading(fontSize: 20)),
        const SizedBox(height: 8),
        Text(err,
            textAlign: TextAlign.center,
            style: _T.body(fontSize: 13)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => setState(
                  () => _futureCategories = _fetchTopCategories()),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
              color: _T.accent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: _T.accent.withValues(alpha: 0.4),
                    blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Text('Try Again',
                style: _T.label(color: Colors.white, fontSize: 14)),
          ),
        ),
      ]),
    ),
  );

  // ── Placeholder card ────────────────────────────────────────────────
  Widget _buildPlaceholderCard() => Container(
    decoration: BoxDecoration(
      color: _T.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _T.border),
    ),
    child: Column(children: [
      Expanded(
        flex: 3,
        child: Container(
          decoration: BoxDecoration(
            color: _T.bg,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Center(
            child: Icon(Icons.add_circle_outline,
                color: _T.textSec.withValues(alpha: 0.25), size: 32),
          ),
        ),
      ),
      Expanded(
        flex: 2,
        child: Center(
          child: Text('Coming Soon',
              style: _T.label(
                  color: _T.textSec.withValues(alpha: 0.5), fontSize: 12)),
        ),
      ),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 700 ? 3 : 2;
    const int minTiles = 6;

    return Scaffold(
      backgroundColor: _T.bg,
      body: CustomScrollView(slivers: [
        // ── Sliver app bar ─────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          backgroundColor: _T.bg,
          surfaceTintColor: Colors.transparent,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _T.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _T.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: _T.textPri, size: 16),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0A2420), _T.bg],
                  ),
                ),
              ),
              Positioned(
                top: -40, right: -40,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.accent.withValues(alpha: 0.06),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('BROWSE', style: _T.eyebrow()),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('Top ', style: _T.heading(fontSize: 26)),
                        Text('Categories',
                            style: _T.headingAccent(fontSize: 28)),
                      ]),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),

        // ── Body ───────────────────────────────────────────────────────
        SliverFillRemaining(
          child: FutureBuilder<List<CategoryItem>>(
            future: _futureCategories,
            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 6,
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 14, crossAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemBuilder: (_, __) => _buildShimmerCard(),
                  ),
                );
              }

              // Error
              if (snapshot.hasError) {
                return _buildError(snapshot.error.toString());
              }

              // Data
              final items = snapshot.data ?? [];
              final children = <Widget>[
                ...items.asMap().entries
                    .map((e) => _buildCard(e.value, e.key)),
              ];
              while (children.length < minTiles) {
                children.add(_buildPlaceholderCard());
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: GridView.builder(
                  itemCount: children.length,
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14, crossAxisSpacing: 14,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (_, index) => children[index],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
