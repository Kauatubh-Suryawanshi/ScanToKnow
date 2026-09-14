// lib/core/ui/widgets/food_tile.dart
import 'package:flutter/material.dart';

class FoodTile extends StatelessWidget {
  final String name;
  final String? imageAssetOrUrl;
  final String? health;
  final String? nutriScore;
  final int? novaScore;
  final VoidCallback? onTap;

  const FoodTile(
      this.name, {
        super.key,
        this.imageAssetOrUrl,
        this.health,
        this.nutriScore,
        this.novaScore,
        this.onTap,
      });

  Color _getHealthColor(String? health) {
    switch (health) {
      case "Green":
        return Colors.green;
      case "Yellow":
        return Colors.amber;
      case "Red":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getNutriColor(String? score) {
    switch (score?.toUpperCase()) {
      case "A":
        return Colors.green;
      case "B":
        return Colors.lightGreen;
      case "C":
        return Colors.yellow;
      case "D":
        return Colors.orange;
      case "E":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getNovaColor(int? score) {
    switch (score) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orangeAccent, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAssetOrUrl != null && imageAssetOrUrl!.isNotEmpty)
            // try URL first, fallback to asset usage will be handled by Image.network errorBuilder
              Image.network(imageAssetOrUrl!, height: 90, fit: BoxFit.contain, errorBuilder: (_, __, ___) {
                return Image.asset('images/home_page_images/drinks.png', height: 90, fit: BoxFit.contain);
              })
            else
              Image.asset('images/home_page_images/drinks.png', height: 90, fit: BoxFit.contain),

            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            if (health != null) Text("Health: $health", style: TextStyle(color: _getHealthColor(health), fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            if (nutriScore != null) _buildBadge("NutriScore: $nutriScore", _getNutriColor(nutriScore)),
            const SizedBox(height: 6),
            if (novaScore != null) _buildBadge("Nova: $novaScore", _getNovaColor(novaScore)),
          ],
        ),
      ),
    );
  }
}
