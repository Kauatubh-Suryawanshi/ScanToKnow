// product_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/search_repository.dart';
import '../domain/search_item.dart';
import '../../variants/presentation/variant_detail_page.dart';
import 'widgets/search_result_tile.dart';
import '../../../core/app_theme.dart';

class ProductPage extends StatefulWidget {
  final String productId;
  final String productLabel;

  const ProductPage({
    super.key,
    required this.productId,
    required this.productLabel,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with SingleTickerProviderStateMixin {
  late Future<List<VariantCard>> _futureVariants;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _futureVariants = SearchRepository.searchByProductId(widget.productId);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            _buildVariantList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.background,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _GlassButton(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 16,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.fadeTitle],
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VARIANTS',
              style: AppTheme.eyebrow.copyWith(fontSize: 9),
            ),
            const SizedBox(height: 2),
            Text(
              widget.productLabel,
              style: AppTheme.heading.copyWith(fontSize: 20),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient mesh background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D2E28),
                    AppTheme.background,
                  ],
                ),
              ),
            ),
            // Decorative teal orb
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom fade
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.background.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.cardBorder.withValues(alpha: 0),
                AppTheme.cardBorder,
                AppTheme.cardBorder.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantList() {
    return SliverFillRemaining(
      child: FutureBuilder<List<VariantCard>>(
        future: _futureVariants,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snap.hasError) {
            return _buildErrorState();
          }

          final variants = snap.data ?? [];

          if (variants.isEmpty) {
            return _buildEmptyState();
          }

          // Trigger animation once data arrives
          WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimation());

          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: variants.length,
                itemBuilder: (_, i) {
                  final v = variants[i];
                  return _AnimatedTile(
                    index: i,
                    child: _VariantTileWrapper(
                      item: v,
                      onTap: () => Navigator.push(
                        context,
                        _smoothRoute(VariantDetailPage(variantId: v.id)),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.accent,
            backgroundColor: AppTheme.cardBorder,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading variants…',
          style: AppTheme.body.copyWith(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.badBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.bad.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.wifi_off_rounded,
              color: AppTheme.bad, size: 28),
        ),
        const SizedBox(height: 16),
        Text('Failed to load variants',
            style: AppTheme.label.copyWith(color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text('Check your connection and try again.',
            style: AppTheme.body.copyWith(fontSize: 13)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: const Icon(Icons.layers_clear_rounded,
              color: AppTheme.textSecondary, size: 32),
        ),
        const SizedBox(height: 20),
        Text('No variants found',
            style: AppTheme.label.copyWith(
                color: AppTheme.textPrimary, fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          'This product has no listed variants yet.',
          style: AppTheme.body.copyWith(fontSize: 13),
        ),
      ],
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
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// ── Animated stagger wrapper ─────────────────────────────────────────────────
class _AnimatedTile extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedTile({required this.index, required this.child});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Variant tile wrapper (styled shell around SearchResultTile) ──────────────
class _VariantTileWrapper extends StatefulWidget {
  final VariantCard item;
  final VoidCallback onTap;

  const _VariantTileWrapper({required this.item, required this.onTap});

  @override
  State<_VariantTileWrapper> createState() => _VariantTileWrapperState();
}

class _VariantTileWrapperState extends State<_VariantTileWrapper> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          transform: Matrix4.diagonal3Values(_pressed ? 0.975 : 1.0, _pressed ? 0.975 : 1.0, _pressed ? 0.975 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed
                ? AppTheme.cardBorder.withValues(alpha: 0.6)
                : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed
                  ? AppTheme.accent.withValues(alpha: 0.35)
                  : AppTheme.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Subtle left accent bar
                Positioned(
                  left: 0,
                  top: 12,
                  bottom: 12,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 3,
                    decoration: BoxDecoration(
                      color: _pressed
                          ? AppTheme.accent
                          : AppTheme.accent.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SearchResultTile(
                    item: widget.item,
                    onTap: widget.onTap,
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

// ── Glass icon button ────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Center(child: child),
      ),
    );
  }
}
