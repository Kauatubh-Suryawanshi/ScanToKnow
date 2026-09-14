// // lib/features/search/data/search_repository.dart

import '../../../core/network/api_service.dart';
import '../domain/search_item.dart';

class SearchRepository {
  // ---------------- AUTOCOMPLETE ----------------
  static Future<List<ProductSuggestion>> autocomplete(
      String q, {
        int limit = 7,
      }) async {
    final query = q.trim();
    if (query.isEmpty) return [];

    final encodedQ = Uri.encodeComponent(query);
    final res = await ApiService.get(
      '/v1/search/autocomplete?q=$encodedQ&limit=$limit',
    );

    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .map((e) => ProductSuggestion.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .toList();
    }
    return [];
  }

  // ---------------- FREE TEXT SEARCH ----------------
  static Future<List<VariantCard>> searchByQuery(
      String q, {
        int page = 1,
        int limit = 24,
      }) async {
    final query = q.trim();
    if (query.isEmpty) return [];

    final encodedQ = Uri.encodeComponent(query);
    final res = await ApiService.get(
      '/v1/search?q=$encodedQ&page=$page&limit=$limit',
    );

    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .map((e) => VariantCard.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .toList();
    }
    return [];
  }

  // ---------------- PRODUCT → VARIANTS ----------------
  static Future<List<VariantCard>> searchByProductId(
      String productId, {
        int page = 1,
        int limit = 24,
      }) async {
    final id = productId.trim();
    if (id.isEmpty) return [];

    final res = await ApiService.get(
      '/v1/search?product_id=$id&page=$page&limit=$limit',
    );

    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .map((e) => VariantCard.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .toList();
    }
    return [];
  }
}
