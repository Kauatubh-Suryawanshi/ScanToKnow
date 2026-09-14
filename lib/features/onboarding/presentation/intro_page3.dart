import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_theme.dart';

class IntroPage3Content extends StatelessWidget {
  const IntroPage3Content({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(child: const _HealthScoreRing()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR FOOD, YOUR CHOICE', style: AppTheme.eyebrow),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: AppTheme.heading,
                  children: [
                    const TextSpan(text: "Eat smarter,\nstarting "),
                    TextSpan(text: "today", style: AppTheme.headingAccent),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Every scan builds your awareness. Make choices you feel good about — one product at a time.",
                style: AppTheme.body,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _FeatureBadge(icon: Icons.bar_chart_rounded,    label: 'Health score'),
                  _FeatureBadge(icon: Icons.warning_amber_rounded, label: 'Additive alerts'),
                  _FeatureBadge(icon: Icons.shield_outlined,       label: '100% Free'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthScoreRing extends StatelessWidget {
  const _HealthScoreRing();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(painter: _RingPainter(score: 75), size: const Size(220, 220)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '75',
                style: GoogleFonts.dmSans(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentLight,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text('Health Score',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          Positioned(
            top: 12, left: 0,
            child: _FloatingBadge(label: '✓ Gluten free', color: AppTheme.safe, bg: AppTheme.safeBg),
          ),
          Positioned(
            top: 12, right: 0,
            child: _FloatingBadge(label: '✕ High sodium', color: AppTheme.bad, bg: AppTheme.badBg),
          ),
          Positioned(
            bottom: 16, right: 0,
            child: _FloatingBadge(label: '⚠ Palm oil', color: AppTheme.warn, bg: AppTheme.warnBg),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double score;
  const _RingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const sw = 14.0;

    canvas.drawCircle(center, radius,
        Paint()
          ..color = AppTheme.cardBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (score / 100) * 2 * math.pi,
      false,
      Paint()
        ..color = AppTheme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _FloatingBadge extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _FloatingBadge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        border: Border.all(color: AppTheme.cardBorder),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
