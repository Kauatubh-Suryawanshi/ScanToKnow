// // lib/features/scan/presentation/barcode_scan_page.dart
//
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
//
// import '../../../core/network/api_service.dart';
// import '../../../core/app_theme.dart';
// import '../../variants/presentation/variant_detail_page.dart';
// import 'scanner_overlay.dart';
//
// class BarcodeScanPage extends StatefulWidget {
//   const BarcodeScanPage({super.key});
//
//   @override
//   State<BarcodeScanPage> createState() => _BarcodeScanPageState();
// }
//
// class _BarcodeScanPageState extends State<BarcodeScanPage>
//     with TickerProviderStateMixin {
//   CameraController? _cameraController;
//   CameraDescription? _cameraDescription;
//   late final BarcodeScanner _barcodeScanner;
//
//   bool _isProcessing = false;
//   bool _scanLocked = false;
//
//   int _lastProcessTs = 0;
//   static const int _throttleMs = 250;
//
//   late AnimationController _laserController;
//   bool _torchOn = false;
//
//   String? _lastCode;
//   bool _callingApi = false;
//
//   // ── pulse animation for the found-state indicator
//   late AnimationController _pulseController;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);
//     _laserController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//
//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     );
//
//     _initCamera();
//   }
//
//   Future<void> _initCamera() async {
//     try {
//       final cameras = await availableCameras();
//       final back = cameras.firstWhere(
//             (c) => c.lensDirection == CameraLensDirection.back,
//       );
//
//       _cameraDescription = back;
//       _cameraController = CameraController(
//         back,
//         ResolutionPreset.medium,
//         enableAudio: false,
//       );
//
//       await _cameraController!.initialize();
//       await _cameraController!.startImageStream(_processImage);
//
//       if (mounted) setState(() {});
//     } catch (_) {
//       // camera init failure
//     }
//   }
//
//   Future<void> _processImage(CameraImage image) async {
//     final now = DateTime.now().millisecondsSinceEpoch;
//     if (now - _lastProcessTs < _throttleMs) return;
//     _lastProcessTs = now;
//
//     if (_isProcessing || _scanLocked) return;
//     _isProcessing = true;
//
//     try {
//       final input = _toInputImage(image, _cameraDescription);
//       final barcodes = await _barcodeScanner.processImage(input);
//
//       if (barcodes.isNotEmpty) {
//         final raw = barcodes.first.rawValue;
//         if (raw != null && raw.trim().isNotEmpty) {
//           if (mounted) setState(() => _lastCode = raw);
//           await Future.delayed(const Duration(milliseconds: 80));
//           await _handleBarcode(raw);
//         }
//       }
//     } finally {
//       _isProcessing = false;
//     }
//   }
//
//   Future<void> _handleBarcode(String raw) async {
//     if (_scanLocked) return;
//     _scanLocked = true;
//     if (mounted) setState(() => _callingApi = true);
//
//     final cleaned =
//     raw.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '').trim();
//     final encoded = Uri.encodeComponent(cleaned);
//
//     bool success = false;
//     String? variantId;
//
//     try {
//       if (_cameraController?.value.isStreamingImages == true) {
//         await _cameraController!.stopImageStream();
//       }
//
//       final res = await ApiService.get('/v1/scan/$encoded');
//       if (res is Map && res['data'] != null) {
//         variantId = res['data']['id']?.toString();
//         success = variantId != null && variantId.isNotEmpty;
//       }
//     } catch (_) {
//       success = false;
//     }
//
//     if (!mounted) return;
//
//     if (success) {
//       HapticFeedback.mediumImpact();
//       _navigateToVariant(variantId!);
//       return;
//     }
//
//     // Show themed snack
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.search_off_rounded, color: AppTheme.bad, size: 18),
//             const SizedBox(width: 10),
//             Text('Product not found',
//                 style: AppTheme.label.copyWith(color: AppTheme.textPrimary)),
//           ],
//         ),
//         backgroundColor: AppTheme.cardBg,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//           side: BorderSide(color: AppTheme.bad.withValues(alpha: 0.4)),
//         ),
//         margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
//       ),
//     );
//
//     _callingApi = false;
//     _scanLocked = false;
//     setState(() {});
//
//     await Future.delayed(const Duration(milliseconds: 400));
//     if (_cameraController?.value.isStreamingImages == false) {
//       await _cameraController!.startImageStream(_processImage);
//     }
//   }
//
//   void _navigateToVariant(String id) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => VariantDetailPage(variantId: id)),
//     );
//   }
//
//   InputImage _toInputImage(CameraImage image, CameraDescription? desc) {
//     final buffer = WriteBuffer();
//     for (final p in image.planes) {
//       buffer.putUint8List(p.bytes);
//     }
//     final rotation = _rotation(desc?.sensorOrientation ?? 0);
//     final format = Platform.isAndroid
//         ? InputImageFormat.nv21
//         : InputImageFormat.bgra8888;
//
//     return InputImage.fromBytes(
//       bytes: buffer.done().buffer.asUint8List(),
//       metadata: InputImageMetadata(
//         size: Size(image.width.toDouble(), image.height.toDouble()),
//         rotation: rotation,
//         format: format,
//         bytesPerRow: image.planes.first.bytesPerRow,
//       ),
//     );
//   }
//
//   InputImageRotation _rotation(int r) {
//     switch (r) {
//       case 90:
//         return InputImageRotation.rotation90deg;
//       case 180:
//         return InputImageRotation.rotation180deg;
//       case 270:
//         return InputImageRotation.rotation270deg;
//       default:
//         return InputImageRotation.rotation0deg;
//     }
//   }
//
//   Future<void> _toggleTorch() async {
//     if (_cameraController == null) return;
//     try {
//       await _cameraController!
//           .setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
//       if (mounted) setState(() => _torchOn = !_torchOn);
//     } catch (_) {}
//   }
//
//   @override
//   void dispose() {
//     _laserController.dispose();
//     _pulseController.dispose();
//     _cameraController?.dispose();
//     _barcodeScanner.close();
//     super.dispose();
//   }
//
//   // ── BUILD ─────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     if (_cameraController == null ||
//         !_cameraController!.value.isInitialized) {
//       return _buildInitializingScreen();
//     }
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Camera feed
//           Positioned.fill(child: CameraPreview(_cameraController!)),
//
//           // Scanner overlay (existing widget — unchanged)
//           ScannerOverlay(laserAnimation: _laserController),
//
//           // Gradient vignette — top
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             height: 160,
//             child: DecoratedBox(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.black.withValues(alpha: 0.72),
//                     Colors.transparent,
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           // Gradient vignette — bottom
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             height: 220,
//             child: DecoratedBox(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.bottomCenter,
//                   end: Alignment.topCenter,
//                   colors: [
//                     Colors.black.withValues(alpha: 0.80),
//                     Colors.transparent,
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           // ── Top bar ──────────────────────────────────────────────────
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Close
//                   _ScanIconButton(
//                     icon: Icons.close_rounded,
//                     onTap: () => Navigator.pop(context),
//                   ),
//
//                   // Title pill
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withValues(alpha: 0.45),
//                       borderRadius: BorderRadius.circular(50),
//                       border: Border.all(
//                         color: Colors.white.withValues(alpha: 0.15),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.barcode_reader,
//                             size: 14,
//                             color: AppTheme.accent.withValues(alpha: 0.9)),
//                         const SizedBox(width: 6),
//                         Text(
//                           'BARCODE SCAN',
//                           style: AppTheme.eyebrow.copyWith(
//                             color: Colors.white.withValues(alpha: 0.85),
//                             fontSize: 10,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // Torch
//                   _TorchButton(
//                     isOn: _torchOn,
//                     onTap: _toggleTorch,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // ── Bottom status area ────────────────────────────────────────
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Instruction text
//                     if (!_callingApi && _lastCode == null)
//                       _InstructionText(),
//
//                     const SizedBox(height: 12),
//
//                     // Status indicator
//                     if (_callingApi)
//                       _StatusPill(
//                         icon: Icons.sync_rounded,
//                         label: 'Looking up product…',
//                         color: AppTheme.accent,
//                         spinning: true,
//                       )
//                     else if (_lastCode != null)
//                       _StatusPill(
//                         icon: Icons.qr_code_scanner_rounded,
//                         label: _lastCode!,
//                         color: AppTheme.accentLight,
//                         spinning: false,
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInitializingScreen() {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             SizedBox(
//               width: 36,
//               height: 36,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 color: AppTheme.accent,
//                 backgroundColor: AppTheme.cardBorder,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Starting camera…',
//               style: AppTheme.body.copyWith(
//                   color: AppTheme.textSecondary, fontSize: 13),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ── Circular icon button for scanner UI ──────────────────────────────────────
// class _ScanIconButton extends StatefulWidget {
//   final IconData icon;
//   final VoidCallback onTap;
//
//   const _ScanIconButton({required this.icon, required this.onTap});
//
//   @override
//   State<_ScanIconButton> createState() => _ScanIconButtonState();
// }
//
// class _ScanIconButtonState extends State<_ScanIconButton> {
//   bool _pressed = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: (_) => setState(() => _pressed = true),
//       onTapUp: (_) {
//         setState(() => _pressed = false);
//         widget.onTap();
//       },
//       onTapCancel: () => setState(() => _pressed = false),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 100),
//         width: 42,
//         height: 42,
//         decoration: BoxDecoration(
//           color: _pressed
//               ? Colors.white.withValues(alpha: 0.2)
//               : Colors.black.withValues(alpha: 0.45),
//           shape: BoxShape.circle,
//           border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
//         ),
//         child: Icon(widget.icon, color: Colors.white, size: 18),
//       ),
//     );
//   }
// }
//
// // ── Torch button with on/off state ────────────────────────────────────────────
// class _TorchButton extends StatefulWidget {
//   final bool isOn;
//   final VoidCallback onTap;
//
//   const _TorchButton({required this.isOn, required this.onTap});
//
//   @override
//   State<_TorchButton> createState() => _TorchButtonState();
// }
//
// class _TorchButtonState extends State<_TorchButton> {
//   bool _pressed = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: (_) => setState(() => _pressed = true),
//       onTapUp: (_) {
//         setState(() => _pressed = false);
//         widget.onTap();
//       },
//       onTapCancel: () => setState(() => _pressed = false),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 120),
//         width: 42,
//         height: 42,
//         decoration: BoxDecoration(
//           color: widget.isOn
//               ? const Color(0xFFFFC107).withValues(alpha: _pressed ? 0.4 : 0.22)
//               : Colors.black.withValues(alpha: 0.45),
//           shape: BoxShape.circle,
//           border: Border.all(
//             color: widget.isOn
//                 ? const Color(0xFFFFC107).withValues(alpha: 0.6)
//                 : Colors.white.withValues(alpha: 0.2),
//           ),
//         ),
//         child: Icon(
//           widget.isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
//           color: widget.isOn
//               ? const Color(0xFFFFC107)
//               : Colors.white.withValues(alpha: 0.7),
//           size: 20,
//         ),
//       ),
//     );
//   }
// }
//
// // ── Instruction text ──────────────────────────────────────────────────────────
// class _InstructionText extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Icon(Icons.center_focus_strong_rounded,
//             color: Colors.white.withValues(alpha: 0.4), size: 22),
//         const SizedBox(height: 8),
//         Text(
//           'Hold phone so the barcode sits inside the frame.\nRotate if needed.',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 13,
//             height: 1.55,
//             color: Colors.white.withValues(alpha: 0.55),
//             fontFamily: 'DM Sans',
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // ── Status pill ───────────────────────────────────────────────────────────────
// class _StatusPill extends StatefulWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final bool spinning;
//
//   const _StatusPill({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.spinning,
//   });
//
//   @override
//   State<_StatusPill> createState() => _StatusPillState();
// }
//
// class _StatusPillState extends State<_StatusPill>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _spinCtrl;
//
//   @override
//   void initState() {
//     super.initState();
//     _spinCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     );
//     if (widget.spinning) _spinCtrl.repeat();
//   }
//
//   @override
//   void didUpdateWidget(_StatusPill old) {
//     super.didUpdateWidget(old);
//     if (widget.spinning && !_spinCtrl.isAnimating) {
//       _spinCtrl.repeat();
//     } else if (!widget.spinning && _spinCtrl.isAnimating) {
//       _spinCtrl.stop();
//     }
//   }
//
//   @override
//   void dispose() {
//     _spinCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.black.withValues(alpha: 0.65),
//         borderRadius: BorderRadius.circular(50),
//         border: Border.all(color: widget.color.withValues(alpha: 0.45)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           widget.spinning
//               ? RotationTransition(
//             turns: _spinCtrl,
//             child: Icon(widget.icon, color: widget.color, size: 16),
//           )
//               : Icon(widget.icon, color: widget.color, size: 16),
//           const SizedBox(width: 8),
//           Flexible(
//             child: Text(
//               widget.label,
//               style: TextStyle(
//                 fontSize: 12.5,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white.withValues(alpha: 0.85),
//                 fontFamily: 'DM Sans',
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// lib/features/scan/presentation/barcode_scan_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../../../core/network/api_service.dart';
import '../../../core/app_theme.dart';
import '../../variants/presentation/variant_detail_page.dart';
import 'scanner_overlay.dart';

class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  late final BarcodeScanner _barcodeScanner;

  bool _isProcessing = false;
  bool _scanLocked = false;

  int _lastProcessTs = 0;
  static const int _throttleMs = 250;

  late AnimationController _laserController;
  bool _torchOn = false;

  String? _lastCode;
  bool _callingApi = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
      );

      _cameraDescription = back;

      // ✅ FIX 1: high instead of medium — better frame quality for barcode reading
      _cameraController = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // ✅ FIX 2: explicit format
      );

      await _cameraController!.initialize();

      // ✅ FIX 3: enable autofocus — critical for real product barcodes
      await _cameraController!.setFocusMode(FocusMode.auto);

      // ✅ FIX 4: exposure mode auto
      await _cameraController!.setExposureMode(ExposureMode.auto);

      await _cameraController!.startImageStream(_processImage);

      if (mounted) setState(() {});
    } catch (_) {
      // camera init failure
    }
  }

  Future<void> _processImage(CameraImage image) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProcessTs < _throttleMs) return;
    _lastProcessTs = now;

    if (_isProcessing || _scanLocked) return;
    _isProcessing = true;

    try {
      final input = _toInputImage(image, _cameraDescription);
      final barcodes = await _barcodeScanner.processImage(input);

      if (barcodes.isNotEmpty) {
        final raw = barcodes.first.rawValue;
        if (raw != null && raw.trim().isNotEmpty) {
          if (mounted) setState(() => _lastCode = raw);
          await Future.delayed(const Duration(milliseconds: 80));
          await _handleBarcode(raw);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _handleBarcode(String raw) async {
    if (_scanLocked) return;
    _scanLocked = true;
    if (mounted) setState(() => _callingApi = true);

    final cleaned =
    raw.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '').trim();
    final encoded = Uri.encodeComponent(cleaned);

    bool success = false;
    String? variantId;

    try {
      if (_cameraController?.value.isStreamingImages == true) {
        await _cameraController!.stopImageStream();
      }

      final res = await ApiService.get('/v1/scan/$encoded');
      if (res is Map && res['data'] != null) {
        variantId = res['data']['id']?.toString();
        success = variantId != null && variantId.isNotEmpty;
      }
    } catch (_) {
      success = false;
    }

    if (!mounted) return;

    if (success) {
      HapticFeedback.mediumImpact();
      _navigateToVariant(variantId!);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.search_off_rounded, color: AppTheme.bad, size: 18),
            const SizedBox(width: 10),
            Text('Product not found',
                style: AppTheme.label.copyWith(color: AppTheme.textPrimary)),
          ],
        ),
        backgroundColor: AppTheme.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.bad.withValues(alpha: 0.4)),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );

    _callingApi = false;
    _scanLocked = false;
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 400));

    // ✅ FIX 5: re-enable autofocus after stream restart
    if (_cameraController?.value.isStreamingImages == false) {
      await _cameraController!.startImageStream(_processImage);
      await _cameraController!.setFocusMode(FocusMode.auto);
    }
  }

  void _navigateToVariant(String id) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => VariantDetailPage(variantId: id)),
    );
  }

  InputImage _toInputImage(CameraImage image, CameraDescription? desc) {
    // ✅ FIX 6: proper plane handling for yuv420
    final WriteBuffer buffer = WriteBuffer();
    for (final Plane plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    final rotation = _rotation(desc?.sensorOrientation ?? 0);

    // ✅ FIX 7: nv21 on Android (ML Kit's preferred format), bgra on iOS
    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation _rotation(int r) {
    switch (r) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null) return;
    try {
      await _cameraController!
          .setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {}
  }

  @override
  void dispose() {
    _laserController.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return _buildInitializingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_cameraController!)),
          ScannerOverlay(laserAnimation: _laserController),

          // Gradient vignette — top
          Positioned(
            top: 0, left: 0, right: 0, height: 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Gradient vignette — bottom
          Positioned(
            bottom: 0, left: 0, right: 0, height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.80),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ScanIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.barcode_reader,
                            size: 14, color: AppTheme.accent.withValues(alpha: 0.9)),
                        const SizedBox(width: 6),
                        Text(
                          'BARCODE SCAN',
                          style: AppTheme.eyebrow.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TorchButton(isOn: _torchOn, onTap: _toggleTorch),
                ],
              ),
            ),
          ),

          // Bottom status area
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_callingApi && _lastCode == null) _InstructionText(),
                    const SizedBox(height: 12),
                    if (_callingApi)
                      _StatusPill(
                        icon: Icons.sync_rounded,
                        label: 'Looking up product…',
                        color: AppTheme.accent,
                        spinning: true,
                      )
                    else if (_lastCode != null)
                      _StatusPill(
                        icon: Icons.qr_code_scanner_rounded,
                        label: _lastCode!,
                        color: AppTheme.accentLight,
                        spinning: false,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent,
                backgroundColor: AppTheme.cardBorder,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Starting camera…',
              style: AppTheme.body.copyWith(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── rest of the widget classes unchanged below ────────────────────────────────

class _ScanIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ScanIconButton({required this.icon, required this.onTap});
  @override
  State<_ScanIconButton> createState() => _ScanIconButtonState();
}

class _ScanIconButtonState extends State<_ScanIconButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(widget.icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _TorchButton extends StatefulWidget {
  final bool isOn;
  final VoidCallback onTap;
  const _TorchButton({required this.isOn, required this.onTap});
  @override
  State<_TorchButton> createState() => _TorchButtonState();
}

class _TorchButtonState extends State<_TorchButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: widget.isOn
              ? const Color(0xFFFFC107).withValues(alpha: _pressed ? 0.4 : 0.22)
              : Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.isOn
                ? const Color(0xFFFFC107).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          widget.isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          color: widget.isOn
              ? const Color(0xFFFFC107)
              : Colors.white.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }
}

class _InstructionText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.center_focus_strong_rounded,
            color: Colors.white.withValues(alpha: 0.4), size: 22),
        const SizedBox(height: 8),
        Text(
          'Hold phone so the barcode sits inside the frame.\nRotate if needed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13, height: 1.55,
            color: Colors.white.withValues(alpha: 0.55),
            fontFamily: 'DM Sans',
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool spinning;
  const _StatusPill({
    required this.icon, required this.label,
    required this.color, required this.spinning,
  });
  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.spinning) _spinCtrl.repeat();
  }
  @override
  void didUpdateWidget(_StatusPill old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_spinCtrl.isAnimating) {
      _spinCtrl.repeat();
    } else if (!widget.spinning && _spinCtrl.isAnimating) {
      _spinCtrl.stop();
    }
  }
  @override
  void dispose() { _spinCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: widget.color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.spinning
              ? RotationTransition(
              turns: _spinCtrl,
              child: Icon(widget.icon, color: widget.color, size: 16))
              : Icon(widget.icon, color: widget.color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
                fontFamily: 'DM Sans',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}