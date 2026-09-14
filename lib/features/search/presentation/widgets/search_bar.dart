// lib/features/search/presentation/widgets/search_bar.dart

import 'package:flutter/material.dart';

class SearchBarSmall extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SearchBarSmall({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search for products, ingredients or brands',
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClear,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
