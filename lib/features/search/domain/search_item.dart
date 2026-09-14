// lib/features/search/domain/search_item.dart

class ProductSuggestion {
  final String id;
  final String label;
  final String? brand;

  ProductSuggestion({
    required this.id,
    required this.label,
    this.brand,
  });

  factory ProductSuggestion.fromJson(Map<String, dynamic> j) {
    return ProductSuggestion(
      id: j['id'].toString(),
      label: j['label'].toString(),
      brand: j['brand']?.toString(),
    );
  }
}

class VariantCard {
  final String id;
  final String title;
  final String? image;
  final int? quantityValue;
  final String? quantityUnit;
  final String? nutriScore;
  final int? novaGroup;
  final String? healthLabel;

  VariantCard({
    required this.id,
    required this.title,
    this.image,
    this.quantityValue,
    this.quantityUnit,
    this.nutriScore,
    this.novaGroup,
    this.healthLabel,
  });

  factory VariantCard.fromJson(Map<String, dynamic> j) {
    return VariantCard(
      id: j['id'].toString(),
      title: j['title'].toString(),
      image: j['image']?.toString(),
      quantityValue: j['quantity_value'],
      quantityUnit: j['quantity_unit']?.toString(),
      nutriScore: j['nutri_score']?.toString(),
      novaGroup: j['nova_group'],
      healthLabel: j['health_label']?.toString(),
    );
  }
}
