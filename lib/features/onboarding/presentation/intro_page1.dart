import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage1Content extends StatelessWidget {
  const IntroPage1Content({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(child: _BarcodeIllustration()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FOOD INTELLIGENCE', style: AppTheme.eyebrow),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: AppTheme.heading,
                  children: [
                    const TextSpan(text: "Know what's "),
                    TextSpan(text: "really", style: AppTheme.headingAccent),
                    const TextSpan(text: " in\nyour food"),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Point your camera at any barcode or ingredient label. Get an instant health verdict — no guesswork.",
                style: AppTheme.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarcodeIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280, maxHeight: 220),
      child: CustomPaint(
        painter: _BarcodePainter(),
        child: Align(
          alignment: const Alignment(0, 0.8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              "✓  Safe to Eat",
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cardPaint  = Paint()..color = AppTheme.cardBg;
    final strokePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final barPaint = Paint()..color = AppTheme.textPrimary.withValues(alpha: 0.75);
    final bracketPaint = Paint()
      ..color = AppTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final scanPaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final cl = size.width * 0.1, ct = size.height * 0.05;
    final cr = size.width * 0.9, cb = size.height * 0.62;
    final cw = cr - cl, ch = cb - ct;

    final cardRect = RRect.fromLTRBR(cl, ct, cr, cb, const Radius.circular(16));
    canvas.drawRRect(cardRect, cardPaint);
    canvas.drawRRect(cardRect, strokePaint);

    // Bars
    final bars = [3.0, 6.0, 2.0, 5.0, 3.0, 7.0, 2.0, 5.0, 3.0, 6.0, 2.0, 4.0, 3.0];
    double bx = cl + cw * 0.15;
    bool fill = true;
    for (final w in bars) {
      if (fill) canvas.drawRect(Rect.fromLTRB(bx, ct + ch * 0.18, bx + w, ct + ch * 0.78), barPaint);
      bx += w + 2;
      fill = !fill;
    }

    // Dashed scan line
    final scanY = ct + ch * 0.5;
    double dx = cl + 12;
    bool draw = true;
    while (dx < cr - 12) {
      if (draw) canvas.drawLine(Offset(dx, scanY), Offset(dx + 5, scanY), scanPaint);
      dx += draw ? 5 : 3;
      draw = !draw;
    }

    // Corner brackets
    for (int i = 0; i < 4; i++) {
      final cx = (i == 0 || i == 2) ? cl : cr;
      final cy = (i == 0 || i == 1) ? ct : cb;
      final hd = (i == 0 || i == 2) ? 1.0 : -1.0;
      final vd = (i == 0 || i == 1) ? 1.0 : -1.0;
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy + vd * 18)
          ..lineTo(cx, cy)
          ..lineTo(cx + hd * 18, cy),
        bracketPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
