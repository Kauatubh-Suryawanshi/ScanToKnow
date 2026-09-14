// lib/features/categories/presentation/category_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_service.dart';
import '../../../core/ui/category_image_resolver.dart';
import '../../../core/app_theme.dart';
import '../../products/presentation/product_list_page.dart';

// ── Model — unchanged ─────────────────────────────────────────────────────────

class CategoryChild {
  final String id;
  final String slug;
  final String name;
  final int level;
  final String? parentId;
  final int? displayOrder;

  CategoryChild({
    required this.id,
    required this.slug,
    required this.name,
    required this.level,
    this.parentId,
    this.displayOrder,
  });

  factory CategoryChild.fromMap(Map m) {
    return CategoryChild(
      id: (m['_id'] ?? m['id'] ?? '').toString(),
      slug: (m['slug'] ?? m['code'] ?? '').toString(),
      name: (m['name'] ?? m['title'] ?? '').toString(),
      level: (m['level'] is int)
          ? m['level'] as int
          : int.tryParse((m['level'] ?? '').toString()) ?? 0,
      parentId: (m['parent_id'] ?? m['parentId'])?.toString(),
      displayOrder: m['display_order'] is int
          ? m['display_order'] as int
          : (m['display_order'] != null
          ? int.tryParse(m['display_order'].toString())
          : null),
    );
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class CategoryPage extends StatefulWidget {
  final String topSlug;
  final String topTitle;

  const CategoryPage({
    super.key,
    required this.topSlug,
    required this.topTitle,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with SingleTickerProviderStateMixin {
  late Future<List<CategoryChild>> _futureChildren;
  late AnimationController _gridAnimController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _gridAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _futureChildren = _fetchChildren();
  }

  @override
  void dispose() {
    _gridAnimController.dispose();
    super.dispose();
  }

  Future<List<CategoryChild>> _fetchChildren() async {
    final resp =
    await ApiService.get('/v1/categories/${widget.topSlug}/children');
    // ignore: avoid_print
    print('CategoryPage: children raw -> $resp');

    if (resp is Map && resp.containsKey('data')) {
      final data = resp['data'];
      if (data is List) {
        final list = data
            .map<CategoryChild>((m) => CategoryChild.fromMap(m as Map))
            .toList();
        list.sort((a, b) {
          final da = a.displayOrder ?? 9999;
          final db = b.displayOrder ?? 9999;
          return da.compareTo(db);
        });
        return list;
      } else {
        throw Exception('Unexpected "data" type: ${data.runtimeType}');
      }
    } else {
      throw Exception('Unexpected response: ${resp.runtimeType}');
    }
  }

  void _openProductsForSubcategory(CategoryChild child) {
    Navigator.push(
      context,
      _smoothRoute(ProductListPage(subSlug: child.slug, title: child.name)),
    );
  }

  PageRouteBuilder _smoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, anim, __) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  // ── Category tile ───────────────────────────────────────────────────────
  Widget _buildTile(CategoryChild c, int index) {
    final localAsset = assetForCategorySlug(c.slug);
    return _CategoryTile(
      child: c,
      localAsset: localAsset,
      index: index,
      onTap: () => _openProductsForSubcategory(c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cols = width > 700 ? 3 : 2;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<CategoryChild>>(
              future: _futureChildren,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }
                if (snapshot.hasError) {
                  return _buildError(snapshot.error);
                }
                final children = snapshot.data ?? [];
                if (children.isEmpty) {
                  return _buildEmpty();
                }
                // Start grid animation once
                WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _gridAnimController.forward(from: 0));
                return _buildGrid(children, cols);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button
              _GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CATEGORY', style: AppTheme.eyebrow),
                    const SizedBox(height: 2),
                    Text(
                      widget.topTitle,
                      style: AppTheme.heading.copyWith(fontSize: 22),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grid ─────────────────────────────────────────────────────────────────
  Widget _buildGrid(List<CategoryChild> children, int cols) {
    return FadeTransition(
      opacity: _gridAnimController,
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        itemCount: children.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, idx) => _buildTile(children[idx], idx),
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppTheme.accent,
        backgroundColor: AppTheme.cardBorder,
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.bad.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.badBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.wifi_off_rounded,
                    color: AppTheme.bad, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load subcategories',
                style: AppTheme.label.copyWith(
                    color: AppTheme.textPrimary, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 20),
              _RetryButton(
                onTap: () =>
                    setState(() => _futureChildren = _fetchChildren()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Icon(Icons.grid_off_rounded,
                color: AppTheme.textSecondary, size: 32),
          ),
          const SizedBox(height: 18),
          Text('No subcategories',
              style: AppTheme.label
                  .copyWith(fontSize: 16, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text('Nothing to show here yet.',
              style: AppTheme.body.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Category tile widget ──────────────────────────────────────────────────────
class _CategoryTile extends StatefulWidget {
  final CategoryChild child;
  final String? localAsset;
  final int index;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.child,
    required this.localAsset,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _entryFade =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
        begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 45 * widget.index),
            () { if (mounted) _entryCtrl.forward(); });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            transform: Matrix4.diagonal3Values(_pressed ? 0.96 : 1.0, _pressed ? 0.96 : 1.0, _pressed ? 0.96 : 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: _pressed
                  ? AppTheme.cardBorder.withValues(alpha: 0.7)
                  : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _pressed
                    ? AppTheme.accent.withValues(alpha: 0.45)
                    : AppTheme.cardBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Image area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: widget.localAsset != null
                        ? Image.asset(
                      widget.localAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported_rounded,
                        color: AppTheme.textSecondary.withValues(alpha: 0.4),
                        size: 28,
                      ),
                    )
                        : Icon(
                      Icons.category_rounded,
                      color: AppTheme.accent.withValues(alpha: 0.45),
                      size: 32,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Name
                Text(
                  widget.child.name,
                  style: AppTheme.label.copyWith(
                    fontSize: 12.5,
                    color: AppTheme.textPrimary,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Arrow indicator
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: _pressed ? 1.0 : 0.0,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass icon button ─────────────────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 16),
      ),
    );
  }
}

// ── Retry button ──────────────────────────────────────────────────────────────
class _RetryButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RetryButton({required this.onTap});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding:
        const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
        decoration: BoxDecoration(
          color: _pressed
              ? AppTheme.accent.withValues(alpha: 0.2)
              : AppTheme.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: _pressed ? 0.7 : 0.35),
          ),
        ),
        child: Text(
          'Retry',
          style: AppTheme.label.copyWith(color: AppTheme.accent),
        ),
      ),
    );
  }
}
