// // ocr_scan_page.dart
// // No functional changes — scan page is already correct.
// // The preprocessImage, capture flow, and camera setup all remain the same.
// // Only the OCRResultPage import stays; nutriments/CPHS are gone from result page.
//
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image/image.dart' as img;
//
// import '../data/ocr_api_service.dart';
// import 'ocr_result_page.dart';
//
// class _T {
//   static const Color bg       = Color(0xFF0F1E1B);
//   static const Color card     = Color(0xFF162320);
//   static const Color border   = Color(0xFF1F3530);
//   static const Color accent   = Color(0xFF0D9E7A);
//   static const Color accentLt = Color(0xFF1DB890);
//   static const Color textPri  = Color(0xFFE8F5F1);
//   static const Color textSec  = Color(0xFF7AB5A6);
//   static const Color bad      = Color(0xFFE74C3C);
//
//   static TextStyle eyebrow() => GoogleFonts.dmSans(
//     fontSize: 10, fontWeight: FontWeight.w600,
//     letterSpacing: 1.4, color: accent,
//   );
//   static TextStyle label({Color? color}) => GoogleFonts.dmSans(
//     fontSize: 12, fontWeight: FontWeight.w600, color: color ?? textPri,
//   );
//   static TextStyle body({Color? color}) => GoogleFonts.dmSans(
//     fontSize: 15, height: 1.65, color: color ?? textSec,
//   );
// }
//
// class OCRScanPage extends StatefulWidget {
//   const OCRScanPage({super.key});
//
//   @override
//   State<OCRScanPage> createState() => _OCRScanPageState();
// }
//
// class _OCRScanPageState extends State<OCRScanPage>
//     with TickerProviderStateMixin {
//   CameraController? _camera;
//
//   bool _loading           = false;
//   bool _cameraReady       = false;
//   bool _captureInProgress = false;
//   bool _torchOn           = false;
//
//   late AnimationController _pulseController;
//   late AnimationController _scanLineController;
//   late AnimationController _cornerController;
//
//   late Animation<double> _pulseAnim;
//   late Animation<double> _scanLineAnim;
//   late Animation<double> _cornerAnim;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _pulseController = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 1800))
//       ..repeat(reverse: true);
//
//     _scanLineController = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 2200))
//       ..repeat();
//
//     _cornerController = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 900))
//       ..forward();
//
//     _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
//         CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
//
//     _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
//         CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut));
//
//     _cornerAnim = Tween<double>(begin: 0, end: 1).animate(
//         CurvedAnimation(parent: _cornerController, curve: Curves.easeOutCubic));
//
//     _initCamera();
//   }
//
//   Future<void> _initCamera() async {
//     final cameras = await availableCameras();
//     final back = cameras.firstWhere(
//             (c) => c.lensDirection == CameraLensDirection.back);
//
//     _camera = CameraController(
//       back,
//       ResolutionPreset.high,
//       enableAudio: false,
//       imageFormatGroup: ImageFormatGroup.jpeg,
//     );
//
//     await _camera!.initialize();
//     await _camera!.setFocusMode(FocusMode.auto);
//     await _camera!.setExposureMode(ExposureMode.auto);
//
//     if (!mounted) return;
//     setState(() => _cameraReady = true);
//   }
//
//   Future<void> _toggleTorch() async {
//     if (_camera == null) return;
//     try {
//       await _camera!.setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
//       if (mounted) setState(() => _torchOn = !_torchOn);
//     } catch (_) {}
//   }
//
//   Future<void> _capture() async {
//     if (!_cameraReady || _camera == null || _loading || _captureInProgress) return;
//
//     _captureInProgress = true;
//     setState(() => _loading = true);
//
//     try {
//       await _camera!.setFocusMode(FocusMode.locked);
//       final imageFile = await _camera!.takePicture();
//       await _camera!.setFocusMode(FocusMode.auto);
//
//       final rawBytes       = await File(imageFile.path).readAsBytes();
//       final processedBytes = await _preprocessImage(rawBytes);
//
//       // Backend returns { status: "ok", data: { ingredients, additives, unresolved_terms, raw_text } }
//       final response = await OCRApiService.scanImageBytes(processedBytes);
//       final data     = response['data'] as Map<String, dynamic>? ?? response;
//
//       if (!mounted) return;
//
//       await Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => OCRResultPage(data: data)),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: _T.card,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//             side: const BorderSide(color: _T.bad),
//           ),
//           content: Row(children: [
//             const Icon(Icons.error_outline, color: _T.bad, size: 18),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text('Scan failed. Please try again.', style: _T.label()),
//             ),
//           ]),
//         ),
//       );
//     } finally {
//       _captureInProgress = false;
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   Future<Uint8List> _preprocessImage(Uint8List rawBytes) async {
//     img.Image? image = img.decodeImage(rawBytes);
//     if (image == null) return rawBytes;
//
//     final srcW  = image.width;
//     final srcH  = image.height;
//     final cropW = (srcW * 0.92).toInt();
//     final cropH = (cropW * 1.05).toInt();
//     final cropX = ((srcW - cropW) / 2).toInt();
//     final cropY = ((srcH * 0.44) - cropH / 2).toInt().clamp(0, srcH - cropH);
//
//     image = img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH);
//     image = img.adjustColor(image, contrast: 1.2, brightness: 1.05);
//     if (image.width > 1600) image = img.copyResize(image, width: 1600);
//
//     return Uint8List.fromList(img.encodeJpg(image, quality: 88));
//   }
//
//   @override
//   void dispose() {
//     _pulseController.dispose();
//     _scanLineController.dispose();
//     _cornerController.dispose();
//     _camera?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_cameraReady || _camera == null) {
//       return Scaffold(
//         backgroundColor: _T.bg,
//         body: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(
//                 width: 48, height: 48,
//                 child: CircularProgressIndicator(strokeWidth: 2, color: _T.accent),
//               ),
//               const SizedBox(height: 20),
//               Text('Initialising camera…', style: _T.body()),
//             ],
//           ),
//         ),
//       );
//     }
//
//     final size = MediaQuery.of(context).size;
//     final vfW  = size.width * 0.92;
//     final vfH  = vfW * 1.05;
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           CameraPreview(_camera!),
//
//           // Torch button top-right
//           SafeArea(
//             child: Align(
//               alignment: Alignment.topRight,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: GestureDetector(
//                   onTap: _toggleTorch,
//                   child: Container(
//                     width: 40, height: 40,
//                     decoration: BoxDecoration(
//                       color: _T.card.withValues(alpha: 0.8),
//                       shape: BoxShape.circle,
//                       border: Border.all(color: _T.border),
//                     ),
//                     child: Icon(
//                       _torchOn ? Icons.flash_on : Icons.flash_off,
//                       color: _torchOn ? _T.accent : _T.textSec,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//
//           // Scan viewfinder
//           Align(
//             alignment: const Alignment(0, -0.12),
//             child: SizedBox(
//               width: vfW,
//               height: vfH,
//               child: Stack(
//                 children: [
//                   AnimatedBuilder(
//                     animation: _scanLineAnim,
//                     builder: (_, __) => Positioned(
//                       top: _scanLineAnim.value * vfH,
//                       left: 0, right: 0,
//                       child: Container(
//                         height: 2,
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(colors: [
//                             Colors.transparent, _T.accent, Colors.transparent,
//                           ]),
//                           boxShadow: [
//                             BoxShadow(color: _T.accent.withValues(alpha: 0.6), blurRadius: 8),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   AnimatedBuilder(
//                     animation: _cornerAnim,
//                     builder: (_, __) => CustomPaint(
//                       size: Size(vfW, vfH),
//                       painter: _CornerPainter(progress: _cornerAnim.value),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Capture button
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 32),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       'Point at ingredients label',
//                       style: GoogleFonts.dmSans(
//                         fontSize: 12, color: _T.textSec.withValues(alpha: 0.8),
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     GestureDetector(
//                       onTap: _loading ? null : _capture,
//                       child: Container(
//                         width: 80, height: 80,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: _T.accent,
//                           boxShadow: [
//                             BoxShadow(
//                               color: _T.accent.withValues(alpha: 0.4),
//                               blurRadius: 20, spreadRadius: 4,
//                             ),
//                           ],
//                         ),
//                         child: _loading
//                             ? const Padding(
//                           padding: EdgeInsets.all(20),
//                           child: CircularProgressIndicator(
//                             color: Colors.white, strokeWidth: 2,
//                           ),
//                         )
//                             : const Icon(Icons.document_scanner_outlined,
//                             color: Colors.white, size: 32),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _CornerPainter extends CustomPainter {
//   final double progress;
//   const _CornerPainter({required this.progress});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     const len = 28.0;
//     const r   = 6.0;
//
//     final col = Color.lerp(Colors.transparent, _T.accent, progress) ?? _T.accent;
//
//     final paint = Paint()
//       ..color       = col
//       ..style       = PaintingStyle.stroke
//       ..strokeWidth = 2.5
//       ..strokeCap   = StrokeCap.round;
//
//     void draw(Offset o, bool fx, bool fy) {
//       final sx = fx ? -1.0 : 1.0;
//       final sy = fy ? -1.0 : 1.0;
//
//       final path = Path()
//         ..moveTo(o.dx + sx * len, o.dy)
//         ..lineTo(o.dx + sx * r, o.dy)
//         ..arcToPoint(
//           Offset(o.dx, o.dy + sy * r),
//           radius: const Radius.circular(r),
//           clockwise: !(fx ^ fy),
//         )
//         ..lineTo(o.dx, o.dy + sy * len);
//
//       canvas.drawPath(path, paint);
//     }
//
//     draw(Offset.zero, false, false);
//     draw(Offset(size.width, 0), true, false);
//     draw(Offset(0, size.height), false, true);
//     draw(Offset(size.width, size.height), true, true);
//   }
//
//   @override
//   bool shouldRepaint(_CornerPainter old) => old.progress != progress;
// }

// lib/features/ocr/presentation/ocr_scan_page.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

import '../data/ocr_api_service.dart';
import 'ocr_result_page.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
class _T {
  static const Color bg      = Color(0xFF0F1E1B);
  static const Color card    = Color(0xFF162320);
  static const Color border  = Color(0xFF1F3530);
  static const Color accent  = Color(0xFF0D9E7A);
  static const Color accentLt= Color(0xFF1DB890);
  static const Color textPri = Color(0xFFE8F5F1);
  static const Color textSec = Color(0xFF7AB5A6);
  static const Color bad     = Color(0xFFE74C3C);

  static TextStyle eyebrow() => GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w600,
    letterSpacing: 1.4, color: accent,
  );
  static TextStyle label({Color? color}) => GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w600, color: color ?? textPri,
  );
  static TextStyle body({Color? color}) => GoogleFonts.dmSans(
    fontSize: 14, height: 1.65, color: color ?? textSec,
  );
}

// ── Processing step data ──────────────────────────────────────────────────────
const _processingSteps = [
  (icon: Icons.camera_alt_outlined,    label: 'Capturing image…'),
  (icon: Icons.document_scanner_outlined, label: 'Reading label…'),
  (icon: Icons.biotech_outlined,       label: 'Analysing ingredients…'),
  (icon: Icons.verified_outlined,      label: 'Matching database…'),
];

class OCRScanPage extends StatefulWidget {
  const OCRScanPage({super.key});

  @override
  State<OCRScanPage> createState() => _OCRScanPageState();
}

class _OCRScanPageState extends State<OCRScanPage>
    with TickerProviderStateMixin {
  CameraController? _camera;

  bool _loading           = false;
  bool _cameraReady       = false;
  bool _captureInProgress = false;
  bool _torchOn           = false;

  // Processing step state
  int  _processingStep    = 0;

  // Animations
  late AnimationController _pulseCtrl;
  late AnimationController _scanLineCtrl;
  late AnimationController _cornerCtrl;
  late AnimationController _shutterRippleCtrl;
  late AnimationController _processingCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _scanLineAnim;
  late Animation<double> _cornerAnim;
  late Animation<double> _shutterRippleAnim;
  late Animation<double> _processingFadeAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _scanLineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();

    _cornerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();

    // Ripple burst on shutter tap
    _shutterRippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shutterRippleAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shutterRippleCtrl, curve: Curves.easeOut));

    // Processing overlay fade
    _processingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _processingFadeAnim = CurvedAnimation(
        parent: _processingCtrl, curve: Curves.easeOut);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));
    _cornerAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _cornerCtrl, curve: Curves.easeOutCubic));

    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back);

    _camera = CameraController(
      back, ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _camera!.initialize();
    await _camera!.setFocusMode(FocusMode.auto);
    await _camera!.setExposureMode(ExposureMode.auto);

    if (!mounted) return;
    setState(() => _cameraReady = true);
  }

  Future<void> _toggleTorch() async {
    if (_camera == null) return;
    try {
      await _camera!.setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {}
  }

  // Advance processing step every ~900ms
  void _startProcessingSteps() {
    _processingStep = 0;
    _processingCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || !_loading) return;
      setState(() => _processingStep = 1);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted || !_loading) return;
        setState(() => _processingStep = 2);
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted || !_loading) return;
          setState(() => _processingStep = 3);
        });
      });
    });
  }

  Future<void> _capture() async {
    if (!_cameraReady || _camera == null || _loading || _captureInProgress) {
      return;
    }

    _captureInProgress = true;

    // Ripple burst
    _shutterRippleCtrl.forward(from: 0);

    setState(() {
      _loading = true;
      _processingStep = 0;
    });
    _startProcessingSteps();

    try {
      await _camera!.setFocusMode(FocusMode.locked);
      final imageFile = await _camera!.takePicture();
      await _camera!.setFocusMode(FocusMode.auto);

      final rawBytes       = await File(imageFile.path).readAsBytes();
      final processedBytes = await _preprocessImage(rawBytes);

      final response = await OCRApiService.scanImageBytes(processedBytes);
      final data     = response['data'] as Map<String, dynamic>? ?? response;

      if (!mounted) return;

      // Fade out processing overlay before navigating
      await _processingCtrl.reverse();
      if (!mounted) return;

      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => OCRResultPage(data: data),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await _processingCtrl.reverse();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _T.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _T.bad),
          ),
          content: Row(children: [
            const Icon(Icons.error_outline, color: _T.bad, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Scan failed. Please try again.',
                  style: _T.label()),
            ),
          ]),
        ),
      );
    } finally {
      _captureInProgress = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Uint8List> _preprocessImage(Uint8List rawBytes) async {
    img.Image? image = img.decodeImage(rawBytes);
    if (image == null) return rawBytes;

    final srcW  = image.width;
    final srcH  = image.height;
    final cropW = (srcW * 0.92).toInt();
    final cropH = (cropW * 1.05).toInt();
    final cropX = ((srcW - cropW) / 2).toInt();
    final cropY = ((srcH * 0.44) - cropH / 2).toInt().clamp(0, srcH - cropH);

    image = img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH);
    image = img.adjustColor(image, contrast: 1.2, brightness: 1.05);
    if (image.width > 1600) image = img.copyResize(image, width: 1600);

    return Uint8List.fromList(img.encodeJpg(image, quality: 88));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanLineCtrl.dispose();
    _cornerCtrl.dispose();
    _shutterRippleCtrl.dispose();
    _processingCtrl.dispose();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraReady || _camera == null) {
      return Scaffold(
        backgroundColor: _T.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48, height: 48,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _T.accent),
              ),
              const SizedBox(height: 20),
              Text('Initialising camera…', style: _T.body()),
            ],
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final vfW  = size.width * 0.92;
    final vfH  = vfW * 1.05;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera feed ────────────────────────────────
          CameraPreview(_camera!),

          // ── Top vignette ───────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0, height: 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom vignette ────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0, height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Top bar ────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Row(children: [
                _GlassButton(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: _T.textPri, size: 16),
                ),
                const Spacer(),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('SMART READ', style: _T.eyebrow()),
                  Text('Ingredient Scanner',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: _T.textPri,
                      )),
                ]),
                const Spacer(),
                _GlassButton(
                  onTap: _toggleTorch,
                  child: Icon(
                    _torchOn ? Icons.flash_on : Icons.flash_off,
                    color: _torchOn ? _T.accentLt : _T.textSec,
                    size: 18,
                  ),
                ),
              ]),
            ),
          ),

          // ── Viewfinder ─────────────────────────────────
          Align(
            alignment: const Alignment(0, -0.12),
            child: SizedBox(
              width: vfW, height: vfH,
              child: Stack(children: [
                // Scan line
                AnimatedBuilder(
                  animation: _scanLineAnim,
                  builder: (_, __) => Positioned(
                    top: _scanLineAnim.value * vfH,
                    left: 0, right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Colors.transparent,
                          _T.accent,
                          Colors.transparent,
                        ]),
                        boxShadow: [
                          BoxShadow(
                            color: _T.accent.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Corner brackets
                AnimatedBuilder(
                  animation: _cornerAnim,
                  builder: (_, __) => CustomPaint(
                    size: Size(vfW, vfH),
                    painter: _CornerPainter(progress: _cornerAnim.value),
                  ),
                ),
              ]),
            ),
          ),

          // ── Hint pill ──────────────────────────────────
          if (!_loading)
            Align(
              alignment: const Alignment(0, 0.55),
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) =>
                    Opacity(opacity: _pulseAnim.value, child: child),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: _T.card.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _T.border.withValues(alpha: 0.8)),
                  ),
                  child: Text('Point at the ingredients list',
                      style: _T.label(color: _T.textSec)
                          .copyWith(fontSize: 13)),
                ),
              ),
            ),

          // ── Shutter button + ripple ────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_loading)
                      Text('Tap to Scan',
                          style: _T.eyebrow().copyWith(
                              color: _T.textSec, letterSpacing: 1.2)),
                    const SizedBox(height: 14),
                    // Ripple wrapper
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated ripple ring
                        AnimatedBuilder(
                          animation: _shutterRippleAnim,
                          builder: (_, __) {
                            final v = _shutterRippleAnim.value;
                            return Opacity(
                              opacity: (1 - v).clamp(0, 1),
                              child: Container(
                                width:  80 + v * 60,
                                height: 80 + v * 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _T.accent
                                        .withValues(alpha: 1 - v),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Shutter button
                        GestureDetector(
                          onTap: _loading ? null : _capture,
                          child: AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, __) => Transform.scale(
                              scale: _loading
                                  ? 1.0
                                  : _pulseAnim.value * 0.04 + 0.96,
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _loading
                                      ? _T.accent.withValues(alpha: 0.7)
                                      : _T.accent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _T.accent.withValues(alpha: 0.4),
                                      blurRadius: 28,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.document_scanner_outlined,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Processing overlay ─────────────────────────
          if (_loading)
            FadeTransition(
              opacity: _processingFadeAnim,
              child: Container(
                color: Colors.black.withValues(alpha: 0.72),
                child: Center(
                  child: _ProcessingOverlay(
                    step: _processingStep,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Processing overlay widget ─────────────────────────────────────────────────
class _ProcessingOverlay extends StatefulWidget {
  final int step;
  const _ProcessingOverlay({required this.step});

  @override
  State<_ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<_ProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotCtrl;
  late Animation<double> _dotAnim;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    _dotAnim = CurvedAnimation(parent: _dotCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _processingSteps[widget.step.clamp(0, _processingSteps.length - 1)];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated icon container
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim, child: FadeTransition(opacity: anim, child: child),
          ),
          child: Container(
            key: ValueKey(widget.step),
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _T.card,
              shape: BoxShape.circle,
              border: Border.all(
                  color: _T.accent.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _T.accent.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(step.icon, color: _T.accent, size: 30),
          ),
        ),
        const SizedBox(height: 20),
        // Step label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            step.label,
            key: ValueKey(widget.step),
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _T.textPri,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Animated dots
        AnimatedBuilder(
          animation: _dotAnim,
          builder: (_, __) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i / 3.0;
                final v = (((_dotAnim.value + delay) % 1.0));
                final opacity = (v < 0.5 ? v * 2 : (1 - v) * 2)
                    .clamp(0.2, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 5, height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.accent.withValues(alpha: opacity),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 24),
        // Step progress pills
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_processingSteps.length, (i) {
            final active = i <= widget.step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? _T.accent
                    : _T.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Glass button ──────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Center(child: child),
    ),
  );
}

// ── Corner bracket painter ────────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final double progress;
  const _CornerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const len = 28.0;
    const r   = 6.0;
    final col = Color.lerp(Colors.transparent, _T.accent, progress) ?? _T.accent;

    final paint = Paint()
      ..color       = col
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap   = StrokeCap.round;

    final glow = Paint()
      ..color       = col.withValues(alpha: 0.3)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap   = StrokeCap.round
      ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 4);

    void draw(Offset o, bool fx, bool fy) {
      final sx = fx ? -1.0 : 1.0;
      final sy = fy ? -1.0 : 1.0;
      final path = Path()
        ..moveTo(o.dx + sx * len, o.dy)
        ..lineTo(o.dx + sx * r, o.dy)
        ..arcToPoint(Offset(o.dx, o.dy + sy * r),
            radius: const Radius.circular(r), clockwise: !(fx ^ fy))
        ..lineTo(o.dx, o.dy + sy * len);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, paint);
    }

    draw(Offset.zero, false, false);
    draw(Offset(size.width, 0), true, false);
    draw(Offset(0, size.height), false, true);
    draw(Offset(size.width, size.height), true, true);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.progress != progress;
}