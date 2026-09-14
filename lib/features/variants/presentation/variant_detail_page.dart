// lib/features/variants/presentation/variant_detail_page.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_service.dart';
import '../../../core/app_theme.dart';

class VariantDetailPage extends StatefulWidget {
  final String variantId;

  const VariantDetailPage({super.key, required this.variantId});

  @override
  State<VariantDetailPage> createState() => _VariantDetailPageState();
}

class _VariantDetailPageState extends State<VariantDetailPage>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _variantFuture;
  late Future<Map<String, dynamic>> _alternativesFuture;

  // Expansion states
  bool _novaExpanded = false;
  bool _nutriExpanded = false;
  bool _cphsExpanded = false;

  // Score ring animation
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _variantFuture = _fetchVariant();
    _alternativesFuture = _fetchAlternatives();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );
  }

  void _startRingAnimation() {
    _ringController.forward(from: 0);
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  // ── DATA FETCHING (UNCHANGED) ─────────────────────────────────────────────

  Future<Map<String, dynamic>> _fetchVariant() async {
    final res = await ApiService.get('/v1/variants/${widget.variantId}');
    if (res is Map && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data']);
    }
    throw Exception('Invalid variant response');
  }

  Future<Map<String, dynamic>> _fetchAlternatives() async {
    try {
      final res = await ApiService.get(
          '/v1/variants/${widget.variantId}/alternatives?limit=10');
      if (res is Map && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data']);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ── PURE LOGIC HELPERS (ALL UNCHANGED) ───────────────────────────────────

  String _safe(dynamic v, {String fallback = 'Coming soon'}) {
    if (v == null) return fallback;
    final s = v.toString();
    if (s.isEmpty) return fallback;
    return s;
  }

  String _formatValue(dynamic v, {int decimals = 1, String fallback = '—'}) {
    if (v == null) return fallback;
    if (v is num) {
      if (decimals == 0) return v.round().toString();
      return v.toStringAsFixed(decimals).replaceAll(RegExp(r'\.?0+$'), '');
    }
    final parsed = double.tryParse(v.toString());
    if (parsed != null) {
      if (decimals == 0) return parsed.round().toString();
      return parsed
          .toStringAsFixed(decimals)
          .replaceAll(RegExp(r'\.?0+$'), '');
    }
    return v.toString();
  }

  dynamic _getNutriment(Map<String, dynamic>? nutriments, List<String> keys) {
    if (nutriments == null) return null;
    for (final k in keys) {
      if (nutriments.containsKey(k)) {
        final val = nutriments[k];
        if (val != null) return val;
      }
    }
    return null;
  }

  int _cphsScore(dynamic cphsFinal) {
    if (cphsFinal == null) return 0;
    final double? n = (cphsFinal is num)
    ? cphsFinal.toDouble()
    : double.tryParse(cphsFinal.toString());
    if (n == null) return 0;
    return (n * 100).round().clamp(0, 100);
  }

  String _tagName(String emoji) {
    switch (emoji) {
      case '🔵': return 'Optimal';
      case '🟢': return 'Safe';
      case '🟡': return 'Moderate';
      case '🟠': return 'Caution';
      case '🔴': return 'Hazard';
      default: return 'Unknown';
    }
  }

  Color _tagColor(String emoji) {
    switch (emoji) {
      case '🔵': return const Color(0xFF1E88E5);
      case '🟢': return const Color(0xFF43A047);
      case '🟡': return const Color(0xFFFDD835);
      case '🟠': return const Color(0xFFFF9800);
      case '🔴': return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }

  String _healthLabelText(String? label) {
    if (label == null) return 'Not Rated';
    switch (label.toLowerCase()) {
      case 'very_good': return 'Very Good';
      case 'good': return 'Good';
      case 'okay': return 'Okay';
      case 'poor': return 'Poor';
      case 'very_poor': return 'Very Poor';
      default: return label;
    }
  }

  Color _healthLabelColor(String? label) {
    if (label == null) return Colors.grey;
    switch (label.toLowerCase()) {
      case 'very_good': return const Color(0xFF2E7D32);
      case 'good': return const Color(0xFF558B2F);
      case 'okay': return const Color(0xFFF9A825);
      case 'poor': return const Color(0xFFEF6C00);
      case 'very_poor': return const Color(0xFFC62828);
      default: return Colors.grey;
    }
  }

  Color _categoryMatchColor(String? match) {
    switch (match?.toLowerCase()) {
      case 'same': return const Color(0xFF2E7D32);
      case 'sibling': return const Color(0xFF1976D2);
      case 'cousin': return const Color(0xFFFF9800);
      default: return Colors.grey;
    }
  }

  String _categoryMatchText(String? match) {
    switch (match?.toLowerCase()) {
      case 'same': return 'Same Category';
      case 'sibling': return 'Related Category';
      case 'cousin': return 'Similar Product';
      default: return '';
    }
  }

  Color _novaColor(dynamic nova) {
    final int n = (nova is int)
        ? nova
        : (int.tryParse(nova?.toString() ?? '') ?? 4);
    switch (n) {
      case 1: return const Color(0xFF2E7D32);
      case 2: return const Color(0xFF558B2F);
      case 3: return const Color(0xFFF9A825);
      case 4: return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }

  Color _nutriScoreColor(dynamic score) {
    final String s = (score ?? 'e').toString().toLowerCase();
    switch (s) {
      case 'a': return const Color(0xFF2E7D32);
      case 'b': return const Color(0xFF66BB6A);
      case 'c': return const Color(0xFFFDD835);
      case 'd': return const Color(0xFFFF9800);
      case 'e': return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: FutureBuilder<Map<String, dynamic>>(
          future: _variantFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }
            if (snap.hasError) {
              return _buildError(snap.error);
            }

            final d = snap.data!;
            final Map<String, dynamic> nutriments =
            Map<String, dynamic>.from(d['nutriments'] ?? {});

            final energy = _getNutriment(nutriments,
                ['energy_kcal_100g', 'energy-kcal_100g', 'energy_100g', 'energy_kcal']);
            final sugar = _getNutriment(
                nutriments, ['sugar_g_100g', 'sugars_100g', 'sugars']);
            final fat = _getNutriment(
                nutriments, ['fat_g_100g', 'fat_100g', 'fat']);
            final protein = _getNutriment(
                nutriments, ['protein_g_100g', 'proteins_100g', 'proteins']);
            final salt = _getNutriment(
                nutriments, ['salt_g_100g', 'salt_100g', 'salt']);
            final fiber = _getNutriment(
                nutriments, ['fiber_g_100g', 'fiber_100g', 'fiber']);
            final saturatedFat = _getNutriment(nutriments, [
              'saturated_fat_g_100g', 'saturated-fat_100g',
              'saturated-fat', 'saturated_fat', 'saturated_fat_100g'
            ]);
            final sodium = _getNutriment(
                nutriments, ['sodium_g_100g', 'sodium_100g', 'sodium']);

            final cphsScore = _cphsScore(d['cphs_final']);
            final healthLabel = d['health_label']?.toString();
            final healthStars = d['health_stars'] is num
                ? (d['health_stars'] as num).toInt()
                : (int.tryParse(d['health_stars']?.toString() ?? '') ?? 0);
            final scoreColor = _healthLabelColor(healthLabel);

            // Kick off ring animation once data is ready
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _startRingAnimation());

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── SLIVER APP BAR ───────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _GlassButton(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary, size: 16),
                    ),
                  ),
                  title: Text('Product Details',
                      style: AppTheme.label.copyWith(
                          fontSize: 16, color: AppTheme.textPrimary)),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppTheme.cardBorder.withValues(alpha: 0),
                          AppTheme.cardBorder,
                          AppTheme.cardBorder.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                  ),
                ),

                // ── BODY CONTENT ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ═══════════════════════════════
                      // SECTION 1: CPHS HERO — animated ring
                      // ═══════════════════════════════
                      _buildCphsHero(
                          cphsScore, healthLabel, healthStars, scoreColor, d),

                      const SizedBox(height: 16),

                      // ═══════════════════════════════
                      // ALTERNATIVES
                      // ═══════════════════════════════
                      _buildAlternativesSection(),

                      const SizedBox(height: 8),

                      // ═══════════════════════════════
                      // SECTION 2: PRODUCT IDENTITY
                      // ═══════════════════════════════
                      _buildSection(
                        child: _buildProductIdentity(d),
                      ),

                      const SizedBox(height: 16),

                      // ═══════════════════════════════
                      // SECTION 3: NOVA + NUTRI-SCORE
                      // ═══════════════════════════════
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildMetricCard(
                              title: 'NOVA Processing Level',
                              value: _safe(d['nova_group'], fallback: 'N/A'),
                              valueColor: _novaColor(d['nova_group']),
                              isExpanded: _novaExpanded,
                              onTap: () => setState(
                                      () => _novaExpanded = !_novaExpanded),
                              icon: Icons.factory_outlined,
                              explanation: _buildNovaExplanation(),
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              title: 'Nutri-Score Grade',
                              value: _safe(d['nutri_score'], fallback: 'N/A')
                                  .toUpperCase(),
                              valueColor: _nutriScoreColor(d['nutri_score']),
                              isExpanded: _nutriExpanded,
                              onTap: () => setState(
                                      () => _nutriExpanded = !_nutriExpanded),
                              icon: Icons.star_half_outlined,
                              explanation: _buildNutriExplanation(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ═══════════════════════════════
                      // SECTION 4: NUTRIMENTS
                      // ═══════════════════════════════
                      _buildSectionHeader('Nutritional Values',
                          subtitle: 'Per 100g / 100ml'),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          children: [
                            _buildNutrimentBar('Energy', energy, 'kcal', 2000, Colors.orange),
                            const SizedBox(height: 10),
                            _buildNutrimentBar('Sugar', sugar, 'g', 50, Colors.red),
                            const SizedBox(height: 10),
                            _buildNutrimentBar('Fat', fat, 'g', 70, Colors.amber),
                            const SizedBox(height: 10),
                            _buildNutrimentBar('Saturated Fat', saturatedFat, 'g', 20, Colors.deepOrange),
                            const SizedBox(height: 10),
                            _buildNutrimentBar('Protein', protein, 'g', 50, Colors.green),
                            const SizedBox(height: 10),
                            _buildNutrimentBar('Salt', salt, 'g', 6, Colors.blueGrey),
                            const SizedBox(height: 10),
                            _buildNutrimentBar('Fiber', fiber, 'g', 25, Colors.brown),
                            const SizedBox(height: 10),
                            _buildNutrimentBar('Sodium', sodium, 'g', 2.4, Colors.indigo),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ═══════════════════════════════
                      // SECTION 5: INGREDIENTS
                      // ═══════════════════════════════
                      _buildSectionHeader('Ingredients'),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          children: [
                            _buildTagLegend(),
                            const SizedBox(height: 14),
                            ...List.from(d['ingredient_summary'] ?? [])
                                .map((i) => _buildIngredientTile(i)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ═══════════════════════════════
                      // SECTION 6: ADDITIVES
                      // ═══════════════════════════════
                      _buildSectionHeader('Additives'),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _buildAdditivesSection(d),
                      ),

                      const SizedBox(height: 24),

                      // ═══════════════════════════════
                      // SECTION 7: VARIANT SWITCHER
                      // ═══════════════════════════════
                      if ((d['parent_product']?['variants'] as List?)
                          ?.isNotEmpty ??
                          false)
                        _buildVariantSwitcher(d),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // SECTION BUILDERS
  // ═════════════════════════════════════════════════════════════════════

  // ── CPHS HERO ─────────────────────────────────────────────────────────
  Widget _buildCphsHero(int cphsScore, String? healthLabel, int healthStars,
      Color scoreColor, Map<String, dynamic> d) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        children: [
          // Eyebrow
          Text('HEALTH SCORE', style: AppTheme.eyebrow),
          const SizedBox(height: 24),

          // ── Animated score ring ──────────────────────────────────────
          AnimatedBuilder(
            animation: _ringAnimation,
            builder: (_, __) {
              final progress = _ringAnimation.value;
              return CustomPaint(
                size: const Size(180, 180),
                painter: _ScoreRingPainter(
                  progress: (cphsScore / 100.0) * progress,
                  scoreColor: scoreColor,
                  trackColor: AppTheme.cardBorder,
                ),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated number counter
                        Text(
                          (cphsScore * progress).round().toString(),
                          style: TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: scoreColor,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: AppTheme.body.copyWith(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Label
          Text(
            _healthLabelText(healthLabel),
            style: AppTheme.heading.copyWith(
              fontSize: 22,
              color: scoreColor,
            ),
          ),

          const SizedBox(height: 10),

          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
                  (i) => Icon(
                i < healthStars ? Icons.star_rounded : Icons.star_border_rounded,
                color: i < healthStars
                    ? scoreColor
                    : AppTheme.cardBorder,
                size: 26,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // "How calculated" pill
          GestureDetector(
            onTap: () => setState(() => _cphsExpanded = !_cphsExpanded),
            child: Container(
              padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.accent, size: 16),
                  const SizedBox(width: 8),
                  Text('How is this calculated?',
                      style: AppTheme.label.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  Icon(
                    _cphsExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // CPHS explanation expandable
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildCphsBreakdown(scoreColor),
            crossFadeState: _cphsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildCphsBreakdown(Color scoreColor) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CPHS Score Breakdown',
              style: AppTheme.label
                  .copyWith(fontSize: 15, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Text(
            'The Comprehensive Product Health Score (CPHS) is calculated on a 0–100 scale based on:',
            style: AppTheme.body.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          ...[
            'Nutrition quality (Nutri-Score algorithm)',
            'Ingredient quality (whole foods vs refined)',
            'Sugar content penalty',
            'Processing level (NOVA classification)',
            'Additive safety ratings',
          ].map((t) => _buildBullet(t)),
          const SizedBox(height: 14),
          Text('Score Ranges:',
              style: AppTheme.label.copyWith(color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          _buildScoreRange('85–100', 'Very Good', const Color(0xFF2E7D32)),
          _buildScoreRange('60–84', 'Good', const Color(0xFF558B2F)),
          _buildScoreRange('40–59', 'Okay', const Color(0xFFF9A825)),
          _buildScoreRange('20–39', 'Poor', const Color(0xFFEF6C00)),
          _buildScoreRange('0–19', 'Very Poor', const Color(0xFFC62828)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warnBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.warn.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Disclaimer: This score is for informational and educational purposes only. It is not a substitute for professional medical or nutritional advice.',
              style: AppTheme.body.copyWith(
                  fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  // ── PRODUCT IDENTITY ──────────────────────────────────────────────────
  Widget _buildProductIdentity(Map<String, dynamic> d) {
    return Column(
      children: [
        // Image
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          padding: const EdgeInsets.all(16),
          child: Image.network(
            d['images']?['front'] ?? '',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.image_not_supported_rounded,
              size: 60,
              color: AppTheme.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          d['title'] ?? 'Unknown Product',
          textAlign: TextAlign.center,
          style: AppTheme.heading.copyWith(fontSize: 19),
        ),
        const SizedBox(height: 4),
        Text(_safe(d['brand']),
            style: AppTheme.body
                .copyWith(fontSize: 15, color: AppTheme.accentLight)),
        const SizedBox(height: 2),
        Text(
          '${_safe(d['quantity_value'])} ${_safe(d['quantity_unit'])}',
          style: AppTheme.body.copyWith(fontSize: 13),
        ),
      ],
    );
  }

  // ── ALTERNATIVES ──────────────────────────────────────────────────────
  Widget _buildAlternativesSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _alternativesFuture,
      builder: (context, altSnap) {
        if (altSnap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _DarkCard(
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (!altSnap.hasData || altSnap.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final altData = altSnap.data!;
        final mode = altData['recommendation_mode']?.toString() ?? '';
        final message = altData['message']?.toString() ?? '';
        final alternatives = List.from(altData['alternatives'] ?? []);
        final fallbackUsed = altData['fallback_used'] == true;

        if (alternatives.isEmpty && mode != 'excellent_choice') {
          return const SizedBox.shrink();
        }

        final msgColor = _getMessageBorderColor(mode, fallbackUsed);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getModeIcon(mode),
                  const SizedBox(width: 12),
                  Text('Healthier Alternatives',
                      style: AppTheme.heading.copyWith(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),

              // Message card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: msgColor.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getMessageIcon(mode, fallbackUsed),
                        color: _getMessageIconColor(mode, fallbackUsed),
                        size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(message,
                          style: AppTheme.body.copyWith(fontSize: 13)),
                    ),
                  ],
                ),
              ),

              if (alternatives.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: alternatives.length,
                    itemBuilder: (context, index) =>
                        _buildAlternativeCard(alternatives[index], context),
                  ),
                ),
              ],

              if (fallbackUsed) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warnBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.warn.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 16, color: AppTheme.warn),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "We're continuously adding new products. Check back soon!",
                          style: AppTheme.body.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── INGREDIENTS ───────────────────────────────────────────────────────
  Widget _buildTagLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: AppTheme.accent),
              const SizedBox(width: 6),
              Text('Health Rating Tags',
                  style: AppTheme.label.copyWith(color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildTagLegendItem('🔵', 'Optimal', const Color(0xFF1E88E5)),
              _buildTagLegendItem('🟢', 'Safe', const Color(0xFF43A047)),
              _buildTagLegendItem('🟡', 'Moderate', const Color(0xFFFDD835)),
              _buildTagLegendItem('🟠', 'Caution', const Color(0xFFFF9800)),
              _buildTagLegendItem('🔴', 'Hazard', const Color(0xFFE53935)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(dynamic i) {
    final tag = i['source_tag']?.toString() ?? '⚪';
    final tagName = _tagName(tag);
    final tagColor = _tagColor(tag);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: tagColor.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Text(tag,
                    style: const TextStyle(fontSize: 20))),
          ),
          title: Text(
            (i['canonical_name'] ?? 'Unknown').toUpperCase(),
            style: AppTheme.label
                .copyWith(fontSize: 13, color: AppTheme.textPrimary),
          ),
          subtitle: Text(tagName,
              style: AppTheme.body.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tagColor)),
          iconColor: AppTheme.textSecondary,
          collapsedIconColor: AppTheme.textSecondary,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i['percentage'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.pie_chart_outline,
                              size: 13,
                              color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${_formatValue(i['percentage'], decimals: 1)}% of product',
                            style: AppTheme.body.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  Text(_safe(i['description']),
                      style: AppTheme.body.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADDITIVES ─────────────────────────────────────────────────────────
  Widget _buildAdditivesSection(Map<String, dynamic> d) {
    if ((d['additives'] as List?)?.isEmpty ?? true) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.safeBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.safe.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppTheme.safe, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No additives detected — this product uses only whole food ingredients.',
                style: AppTheme.body.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.from(d['additives'] ?? []).map((a) {
        final tag = a['source_tag']?.toString() ?? '⚪';
        final tagName = _tagName(tag);
        final tagColor = _tagColor(tag);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: tagColor.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Theme(
            data: Theme.of(context)
                .copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                    child: Text(tag,
                        style: const TextStyle(fontSize: 20))),
              ),
              title: Text(
                '${a['code']} — ${a['name']}'.toUpperCase(),
                style: AppTheme.label
                    .copyWith(fontSize: 12, color: AppTheme.textPrimary),
              ),
              subtitle: Text(tagName,
                  style: AppTheme.body.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tagColor)),
              iconColor: AppTheme.textSecondary,
              collapsedIconColor: AppTheme.textSecondary,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (a['description'] != null) ...[
                        Text('What it is:',
                            style: AppTheme.body.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text(_safe(a['description']),
                            style: AppTheme.body.copyWith(fontSize: 13)),
                        const SizedBox(height: 10),
                      ],
                      if (a['notes'] != null) ...[
                        Text('Safety notes:',
                            style: AppTheme.body.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text(_safe(a['notes']),
                            style: AppTheme.body.copyWith(
                                fontSize: 13,
                                fontStyle: FontStyle.italic)),
                        const SizedBox(height: 10),
                      ],
                      if (a['synonyms'] != null &&
                          (a['synonyms'] as List).isNotEmpty) ...[
                        Text('Also known as:',
                            style: AppTheme.body.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          (a['synonyms'] as List).join(', '),
                          style: AppTheme.body.copyWith(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.accentLight),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── VARIANT SWITCHER ──────────────────────────────────────────────────
  Widget _buildVariantSwitcher(Map<String, dynamic> d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Other Sizes'),
          const SizedBox(height: 12),
          ...List.from(d['parent_product']?['variants'] ?? []).map((v) {
            return GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        VariantDetailPage(variantId: v['id'])),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        v['image'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBorder,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image_rounded,
                              size: 24,
                              color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v['title'] ?? 'Unknown',
                              style: AppTheme.label.copyWith(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 2),
                          Text(
                            '${v['quantity_value']} ${v['quantity_unit']}',
                            style: AppTheme.body.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // METRIC CARD (NOVA / NUTRI-SCORE) — styled dark
  // ═════════════════════════════════════════════════════════════════════

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color valueColor,
    required bool isExpanded,
    required VoidCallback onTap,
    required IconData icon,
    required Widget explanation,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: valueColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: valueColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style: AppTheme.label
                            .copyWith(color: AppTheme.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: valueColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'DM Sans')),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: explanation,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildNovaExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOVA classifies foods by processing level:',
            style: AppTheme.label
                .copyWith(fontSize: 13, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        _buildNovaBadge('1', 'Unprocessed / Minimally Processed',
            'Fresh fruits, vegetables, milk', const Color(0xFF2E7D32)),
        const SizedBox(height: 6),
        _buildNovaBadge('2', 'Culinary Ingredients',
            'Oils, butter, sugar, salt', const Color(0xFF558B2F)),
        const SizedBox(height: 6),
        _buildNovaBadge('3', 'Processed Foods',
            'Canned vegetables, cheeses, bread', const Color(0xFFF9A825)),
        const SizedBox(height: 6),
        _buildNovaBadge('4', 'Ultra-Processed',
            'Soft drinks, packaged snacks, instant noodles',
            const Color(0xFFE53935)),
      ],
    );
  }

  Widget _buildNutriExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nutri-Score grades nutritional quality from A (best) to E (worst):',
            style: AppTheme.label
                .copyWith(fontSize: 13, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        _buildNutriBadge('A', 'Excellent', const Color(0xFF2E7D32)),
        const SizedBox(height: 4),
        _buildNutriBadge('B', 'Good', const Color(0xFF66BB6A)),
        const SizedBox(height: 4),
        _buildNutriBadge('C', 'Fair', const Color(0xFFFDD835)),
        const SizedBox(height: 4),
        _buildNutriBadge('D', 'Poor', const Color(0xFFFF9800)),
        const SizedBox(height: 4),
        _buildNutriBadge('E', 'Very Poor', const Color(0xFFE53935)),
        const SizedBox(height: 10),
        Text(
          'Calculated by balancing negative factors (sugar, salt, saturated fat, energy) against positive factors (fiber, protein, fruits/vegetables).',
          style: AppTheme.body.copyWith(
              fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // ALTERNATIVES HELPERS (LOGIC UNCHANGED)
  // ═════════════════════════════════════════════════════════════════════

  Widget _buildAlternativeCard(
      Map<String, dynamic> alt, BuildContext context) {
    final score = _cphsScore(alt['cphs_final']);
    final healthLabel = alt['health_label']?.toString();
    final categoryMatch = alt['category_match']?.toString();
    final scoreColor = _healthLabelColor(healthLabel);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => VariantDetailPage(variantId: alt['id'])),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                alt['images']?['front'] ?? '',
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 90,
                  color: AppTheme.accent.withValues(alpha: 0.07),
                  child: Icon(Icons.image_not_supported_rounded,
                      size: 32,
                      color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alt['title'] ?? 'Unknown',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.label.copyWith(
                            fontSize: 12, color: AppTheme.textPrimary)),
                    const SizedBox(height: 3),
                    Text(alt['brand'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body.copyWith(fontSize: 11)),
                    const Spacer(),
                    if (categoryMatch != null && categoryMatch.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: _categoryMatchColor(categoryMatch)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: _categoryMatchColor(categoryMatch)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Text(_categoryMatchText(categoryMatch),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color:
                                _categoryMatchColor(categoryMatch))),
                      ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(score.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'DM Sans')),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            size: 13,
                            color: AppTheme.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getModeIcon(String mode) {
    IconData icon;
    Color color;
    switch (mode) {
      case 'avoid': icon = Icons.warning_rounded; color = const Color(0xFFC62828); break;
      case 'better_alternatives': icon = Icons.trending_up_rounded; color = const Color(0xFFEF6C00); break;
      case 'safe_choices': icon = Icons.info_outline_rounded; color = const Color(0xFFF9A825); break;
      case 'premium_options': icon = Icons.auto_awesome_rounded; color = const Color(0xFF558B2F); break;
      case 'excellent_choice': icon = Icons.verified_rounded; color = const Color(0xFF2E7D32); break;
      default: icon = Icons.help_outline_rounded; color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _getMessageBorderColor(String mode, bool fallbackUsed) {
    if (fallbackUsed) return AppTheme.warn;
    switch (mode) {
      case 'avoid': return const Color(0xFFE53935);
      case 'better_alternatives': return const Color(0xFFFF9800);
      case 'safe_choices': return const Color(0xFF1E88E5);
      case 'premium_options': return const Color(0xFF43A047);
      case 'excellent_choice': return AppTheme.accent;
      default: return Colors.grey;
    }
  }

  IconData _getMessageIcon(String mode, bool fallbackUsed) {
    if (fallbackUsed) return Icons.lightbulb_outline;
    switch (mode) {
      case 'avoid': return Icons.error_outline;
      case 'better_alternatives': return Icons.trending_up;
      case 'safe_choices': return Icons.info_outline;
      case 'premium_options': return Icons.star_border;
      case 'excellent_choice': return Icons.check_circle_outline;
      default: return Icons.help_outline;
    }
  }

  Color _getMessageIconColor(String mode, bool fallbackUsed) {
    return _getMessageBorderColor(mode, fallbackUsed);
  }

  // ═════════════════════════════════════════════════════════════════════
  // SHARED HELPER WIDGETS
  // ═════════════════════════════════════════════════════════════════════

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent,
                backgroundColor: AppTheme.cardBorder,
              ),
            ),
            const SizedBox(height: 14),
            Text('Loading product…',
                style: AppTheme.body.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
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
                  child:
                  const Icon(Icons.error_outline, color: AppTheme.bad, size: 28),
                ),
                const SizedBox(height: 16),
                Text('Failed to load product',
                    style: AppTheme.label
                        .copyWith(fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Text(error.toString(),
                    textAlign: TextAlign.center,
                    style: AppTheme.body.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.heading.copyWith(fontSize: 18)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: AppTheme.body.copyWith(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrimentBar(
      String label, dynamic value, String unit, double ref, Color color) {
    final numValue = (value is num)
        ? value.toDouble()
        : (double.tryParse(value?.toString() ?? '0') ?? 0.0);
    final pct = (numValue / ref).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: AppTheme.label
                      .copyWith(color: AppTheme.textPrimary, fontSize: 13)),
              Text(
                value != null ? '${_formatValue(value)} $unit' : '—',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'DM Sans'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.cardBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reference: ~${ref.toStringAsFixed(0)}$unit / day',
            style: AppTheme.body.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: AppTheme.body
                  .copyWith(fontSize: 15, color: AppTheme.accent)),
          Expanded(
              child: Text(text, style: AppTheme.body.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildScoreRange(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 5),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$range — ',
              style: AppTheme.label
                  .copyWith(fontSize: 12, color: AppTheme.textPrimary)),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DM Sans')),
        ],
      ),
    );
  }

  Widget _buildNovaBadge(
      String level, String name, String example, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
              child: Text(level,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppTheme.label
                      .copyWith(fontSize: 12, color: AppTheme.textPrimary)),
              Text(example,
                  style: AppTheme.body
                      .copyWith(fontSize: 11, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutriBadge(String grade, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          child: Center(
              child: Text(grade,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13))),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.body.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildTagLegendItem(String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'DM Sans')),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// SCORE RING PAINTER
// ═════════════════════════════════════════════════════════════════════════

class _ScoreRingPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color scoreColor;
  final Color trackColor;

  _ScoreRingPainter({
    required this.progress,
    required this.scoreColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 14;
    const strokeWidth = 10.0;
    const startAngle = -math.pi / 2; // top
    const fullSweep = 2 * math.pi;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Filled arc — single color matching healthLabel
    final arcPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + fullSweep * progress,
        colors: [
          scoreColor.withValues(alpha: 0.6),
          scoreColor,
        ],
        tileMode: TileMode.clamp,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep * progress,
      false,
      arcPaint,
    );

    // Dot at the tip of the arc
    if (progress > 0.01) {
      final angle = startAngle + fullSweep * progress;
      final tipX = center.dx + radius * math.cos(angle);
      final tipY = center.dy + radius * math.sin(angle);

      final dotPaint = Paint()
        ..color = scoreColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 2 + 1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress ||
          old.scoreColor != scoreColor ||
          old.trackColor != trackColor;
}

// ═════════════════════════════════════════════════════════════════════════
// SHARED SMALL WIDGETS
// ═════════════════════════════════════════════════════════════════════════

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
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: child,
    );
  }
}
