// lib/features/scan/presentation/scanner_overlay.dart

import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  final Animation<double> laserAnimation;

  const ScannerOverlay({super.key, required this.laserAnimation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerPainter(laserAnimation),
      child: Container(),
    );
  }
}

class _ScannerPainter extends CustomPainter {
  final Animation<double> animation;

  _ScannerPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    final cutOutSize = size.width * 0.7;
    final left = (size.width - cutOutSize) / 2;
    final top = (size.height - cutOutSize) / 2;

    final cutOutRect = Rect.fromLTWH(left, top, cutOutSize, cutOutSize);

    // Dark background with rounded hole
    final background = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(RRect.fromRectXY(cutOutRect, 16, 16));
    final overlay = Path.combine(PathOperation.difference, background, hole);
    canvas.drawPath(overlay, overlayPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.tealAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectXY(cutOutRect, 16, 16), borderPaint);

    // Laser
    final laserY = top + (cutOutSize * animation.value);

    final laserPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(left + 10, laserY),
      Offset(left + cutOutSize - 10, laserY),
      laserPaint,
    );

    // Corner markers (help alignment)
    final cornerPaint = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    const cornerLen = 18.0;

    // top-left
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLen), cornerPaint);

    // top-right
    canvas.drawLine(Offset(left + cutOutSize, top), Offset(left + cutOutSize - cornerLen, top), cornerPaint);
    canvas.drawLine(Offset(left + cutOutSize, top), Offset(left + cutOutSize, top + cornerLen), cornerPaint);

    // bottom-left
    canvas.drawLine(Offset(left, top + cutOutSize), Offset(left + cornerLen, top + cutOutSize), cornerPaint);
    canvas.drawLine(Offset(left, top + cutOutSize), Offset(left, top + cutOutSize - cornerLen), cornerPaint);

    // bottom-right
    canvas.drawLine(Offset(left + cutOutSize, top + cutOutSize), Offset(left + cutOutSize - cornerLen, top + cutOutSize), cornerPaint);
    canvas.drawLine(Offset(left + cutOutSize, top + cutOutSize), Offset(left + cutOutSize, top + cutOutSize - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
