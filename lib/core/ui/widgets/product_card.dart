// lib/core/ui/widgets/product_card.dart
import 'package:flutter/material.dart';

/// Lightweight summary model for product cards.
/// Map your ProductDTO/VariantDTO to this shape before passing it in.
class ProductSummary {
  final String id;
  final String name;
  final String? imageUrl;
  final String? nutriScore; // "A".."E"
  final int? novaGroup;

  const ProductSummary({
    required this.id,
    required this.name,
    this.imageUrl,
    this.nutriScore,
    this.novaGroup,
  });
}

class ProductCard extends StatelessWidget {
  final ProductSummary product;
  final VoidCallback? onTap;
  final bool isSkeleton;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.isSkeleton = false,
  });

  Color _nutriColor(String? nutri) {
    switch (nutri?.toLowerCase()) {
      case "a":
        return Colors.green.shade700;
      case "b":
        return Colors.green.shade500;
      case "c":
        return Colors.orange.shade600;
      case "d":
        return Colors.orange.shade800;
      case "e":
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isSkeleton) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(height: 100, color: Colors.grey.shade200),
            const SizedBox(height: 8),
            Container(height: 14, color: Colors.grey.shade200),
            const SizedBox(height: 8),
            Container(height: 14, width: 60, color: Colors.grey.shade200),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                product.imageUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey.shade200),
              )
                  : Container(
                height: 100,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported, size: 32),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              product.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            Row(
              children: [
                if (product.nutriScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _nutriColor(product.nutriScore),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.nutriScore!.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 6),
                if (product.novaGroup != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blueGrey.shade700, borderRadius: BorderRadius.circular(6)),
                    child: Text("NOVA ${product.novaGroup}", style: const TextStyle(fontSize: 11, color: Colors.white)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
