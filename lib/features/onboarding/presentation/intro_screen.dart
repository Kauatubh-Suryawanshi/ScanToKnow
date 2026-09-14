import 'package:flutter/material.dart';
import 'intro_page1.dart';
import 'intro_page2.dart';
import 'intro_page3.dart';

/// Drop-in replacement for your existing onboarding host widget.
/// Handles: PageView swipe, dot indicators, Skip button, and CTA.
///
/// Usage:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const IntroScreen()));
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    IntroPage1Content(),
    IntroPage2Content(),
    IntroPage3Content(),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _onFinish();
    }
  }

  void _onFinish() {
    // Onboarding completion routes to the main home screen.
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF8),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: Skip button ────────────────────────────────
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isLast)
                    TextButton(
                      onPressed: _onFinish,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF5A7A72),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    )
                  else
                    const SizedBox(width: 72),
                ],
              ),
            ),

            // ── PageView ────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // ── Bottom: Dots + CTA ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot indicators
                  Row(
                    children: List.generate(_pages.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 7),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.teal.shade600
                              : Colors.teal.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // CTA button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isLast
                        ? _PrimaryButton(
                      key: const ValueKey('start'),
                      label: 'Start Scanning',
                      onTap: _nextPage,
                      wide: true,
                    )
                        : _PrimaryButton(
                      key: const ValueKey('next'),
                      label: 'Next',
                      onTap: _nextPage,
                      showArrow: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool showArrow;
  final bool wide;

  const _PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.showArrow = false,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 32 : 24,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.teal.shade600,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
