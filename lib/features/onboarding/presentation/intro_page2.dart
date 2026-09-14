import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_theme.dart';

class IntroPage2Content extends StatelessWidget {
  const IntroPage2Content({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _IngredientCard(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INGREDIENT X-RAY', style: AppTheme.eyebrow),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: AppTheme.heading,
                  children: [
                    const TextSpan(text: "Spot harmful "),
                    TextSpan(text: "additives", style: AppTheme.headingAccent),
                    const TextSpan(text: "\ninstantly"),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Each ingredient is flagged individually — see what's safe, what to moderate, and what to avoid.",
                style: AppTheme.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IngredientCard extends StatelessWidget {
  static const _items = [
    ('Whole wheat flour',      _Status.safe),
    ('Palm oil',               _Status.warn),
    ('Sodium benzoate (E211)', _Status.bad),
    ('Sugar',                  _Status.warn),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              "Biscuit Ingredients",
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: AppTheme.cardBorder),
          ..._items.map((e) => _IngRow(name: e.$1, status: e.$2)),
          Divider(height: 1, color: AppTheme.cardBorder),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Pill(label: '2\nconcerns', color: AppTheme.bad,  bg: AppTheme.badBg),
                const SizedBox(width: 8),
                _Pill(label: '1\ncaution',  color: AppTheme.warn, bg: AppTheme.warnBg),
                const SizedBox(width: 8),
                _Pill(label: '2\nsafe',     color: AppTheme.safe, bg: AppTheme.safeBg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Status { safe, warn, bad }

class _IngRow extends StatelessWidget {
  final String name;
  final _Status status;
  const _IngRow({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _Status.safe => ('✓ Safe',    AppTheme.safe),
      _Status.warn => ('⚠ Moderate', AppTheme.warn),
      _Status.bad  => ('✕ Harmful', AppTheme.bad),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(name,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textPrimary)),
          ),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  height: 1.3, color: color)),
        ],
      ),
    );
  }
}
