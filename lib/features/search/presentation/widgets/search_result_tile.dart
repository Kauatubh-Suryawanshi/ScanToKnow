// lib/features/search/presentation/widgets/search_result_tile.dart

import 'package:flutter/material.dart';
import '../../domain/search_item.dart';

class SearchResultTile extends StatelessWidget {
  final VariantCard item;
  final VoidCallback? onTap;

  const SearchResultTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String quantity = [
      if (item.quantityValue != null) item.quantityValue.toString(),
      if (item.quantityUnit != null) item.quantityUnit,
    ].join(' ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        onTap: onTap,
        leading: item.image != null && item.image!.isNotEmpty
            ? Image.network(
          item.image!,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.image, size: 40),
        )
            : const Icon(Icons.image, size: 40),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: quantity.isNotEmpty ? Text(quantity) : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.nutriScore ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (item.healthLabel != null)
              Text(
                item.healthLabel!,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
