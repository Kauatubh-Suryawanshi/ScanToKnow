// lib/core/ui/widgets/top_categories.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../category_image_resolver.dart';

/// Same public API — no changes to CategoryItem or TopCategories constructor.
class CategoryItem {
  final String id;
  final String slug;
  final String title;
  final String? imageUrl;
  final int? productCount;

  const CategoryItem({
    required this.id,
    required this.slug,
    required this.title,
    this.imageUrl,
    this.productCount,
  });
}

class TopCategories extends StatelessWidget {
  final List<CategoryItem>? categories;
  final int visibleCount;
  final void Function(CategoryItem category)? onCategoryTap;
  final VoidCallback? onViewAll;

  const TopCategories({
    super.key,
    this.categories,
    this.visibleCount = 6,
    this.onCategoryTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final items = categories ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPLORE',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                        color: const Color(0xFF0D9E7A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Top Categories',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2E2A),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9E7A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xFF0D9E7A).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    'View all',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D9E7A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Horizontal scroll ───────────────────────────────────────
        SizedBox(
          height: 118,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: visibleCount,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index < items.length) {
                final item = items[index];
                return _CategoryCard(
                  title: item.title,
                  slug: item.slug,
                  imageUrl: item.imageUrl,
                  badgeCount: item.productCount,
                  onTap: () => onCategoryTap?.call(item),
                );
              }
              return const _PlaceholderCategoryCard();
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String slug;
  final String? imageUrl;
  final int? badgeCount;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.title,
    required this.slug,
    this.imageUrl,
    this.badgeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String? localAsset = assetForCategorySlug(slug);
    final bool useNetwork = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9E7A).withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image container with teal-tinted bg
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9E7A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: useNetwork
                    ? Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                )
                    : (localAsset != null
                    ? Image.asset(
                  localAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                )
                    : Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.grey.shade400,
                  size: 22,
                )),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A2E2A),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (badgeCount != null) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9E7A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D9E7A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCategoryCard extends StatelessWidget {
  const _PlaceholderCategoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF0D9E7A).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF4FAF8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.add_rounded,
              color: Colors.grey.shade300,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming\nSoon',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Colors.grey.shade400,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
