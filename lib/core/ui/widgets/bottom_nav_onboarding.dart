// lib/core/ui/widgets/bottom_nav_onboarding.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BottomNavOnboarding extends StatefulWidget {
  final List<GlobalKey> navKeys;
  final VoidCallback? onFinish;

  const BottomNavOnboarding({
    super.key,
    required this.navKeys,
    this.onFinish,
  });

  @override
  State<BottomNavOnboarding> createState() => _BottomNavOnboardingState();
}

class _BottomNavOnboardingState extends State<BottomNavOnboarding>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isVisible = false;
  bool _isFadingOut = false;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _fade =
  CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

  // 5 messages — Upload removed
  final List<String> _messages = const [
    "This is your Home — see top categories and quick actions here.",
    "Use Search to find any food product instantly.",
    "Scan a barcode for an instant health breakdown.",
    "Browse Categories to explore foods by type.",
    "Smart Read scans ingredient lists for a full health verdict.",
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('bottom_nav_onboarding_seen') ?? false;
    if (kDebugMode) seen = false;
    if (!seen) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() => _isVisible = true);
        _ctrl.forward();
      }
    }
  }

  Future<void> _finish() async {
    if (_isFadingOut) return;
    _isFadingOut = true;
    await _ctrl.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bottom_nav_onboarding_seen', true);
    if (mounted) setState(() => _isVisible = false);
    widget.onFinish?.call();
  }

  Future<void> _next() async {
    if (_isFadingOut) return;
    if (_currentStep < widget.navKeys.length - 1) {
      _isFadingOut = true;
      await _ctrl.reverse();
      if (!mounted) return;
      setState(() {
        _currentStep++;
        _isFadingOut = false;
      });
      _ctrl.forward();
    } else {
      _finish();
    }
  }

  RenderBox? _box() {
    final ctx = widget.navKeys[_currentStep].currentContext;
    if (ctx == null) return null;
    final rb = ctx.findRenderObject();
    if (rb == null || !rb.attached) return null;
    return rb as RenderBox;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || widget.navKeys.isEmpty) return const SizedBox.shrink();

    final rb = _box();
    if (rb == null) return const SizedBox.shrink();

    final pos = rb.localToGlobal(Offset.zero);
    final sz = rb.size;
    final screenH = MediaQuery.of(context).size.height;

    const pad = 10.0;
    final hole = Rect.fromLTWH(
      pos.dx - pad, pos.dy - pad,
      sz.width + pad * 2, sz.height + pad * 2,
    );

    final bubbleBottomFromScreen = screenH - pos.dy + 18.0;

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // Overlay
            GestureDetector(
              onTap: _next,
              child: CustomPaint(
                size: Size.infinite,
                painter: _OverlayPainter(hole: hole),
              ),
            ),

            // Green ring
            Positioned(
              left: pos.dx - pad,
              top: pos.dy - pad,
              child: IgnorePointer(
                child: Container(
                  width: sz.width + pad * 2,
                  height: sz.height + pad * 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF1DB890),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1DB890).withValues(alpha: 0.28),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bubble
            Positioned(
              left: 16,
              right: 16,
              bottom: bubbleBottomFromScreen,
              child: _Bubble(
                step: _currentStep,
                total: widget.navKeys.length,
                message: _messages[_currentStep],
                isLast: _currentStep == widget.navKeys.length - 1,
                onSkip: _finish,
                onNext: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final int step;
  final int total;
  final String message;
  final bool isLast;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _Bubble({
    required this.step,
    required this.total,
    required this.message,
    required this.isLast,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1C3A34),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF1DB890).withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'App Tour',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFE8F5F1),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB890).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                        color: const Color(0xFF1DB890).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${step + 1} / $total',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF1DB890),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              message,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFADD4CB),
                fontSize: 13,
                height: 1.6,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 7,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(total, (i) {
                  final active = i == step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(right: 5),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF1DB890)
                          : const Color(0xFF1DB890).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7AB5A6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Skip tour',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onNext,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9E7A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(
                    isLast ? 'Done' : 'Next',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect hole;
  const _OverlayPainter({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()
        ..addRRect(
            RRect.fromRectAndRadius(hole, const Radius.circular(14))),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.62)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => old.hole != hole;
}
