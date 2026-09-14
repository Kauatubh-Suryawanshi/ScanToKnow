// lib/core/ui/widgets/top_header.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final String avatarAsset;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSearchTap;

  const TopHeader({
    super.key,
    this.greeting = 'Hi there,',
    this.subtitle = 'Ready to eat smarter today?',
    required this.avatarAsset,
    this.onAvatarTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1612),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1F3530), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(22, top + 16, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCAN2KNOW',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8,
                        color: const Color(0xFF0D9E7A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE8F5F1),
                          height: 1.2,
                        ),
                        children: [
                          TextSpan(
                              text: greeting.replaceAll(',', '').trim()),
                          const TextSpan(text: ' 👋'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: const Color(0xFF7AB5A6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: const Color(0xFF0D9E7A), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF162320),
                    child: ClipOval(
                      child: Image.asset(
                        avatarAsset,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          size: 26,
                          color: Color(0xFF0D9E7A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFF162320),
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: const Color(0xFF1F3530), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      size: 20, color: Color(0xFF0D9E7A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search products, ingredients, brands…',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: const Color(0xFF4A7A70),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9E7A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⌘ K',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D9E7A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
