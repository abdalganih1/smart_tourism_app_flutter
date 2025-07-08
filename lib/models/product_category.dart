// lib/models/product_category.dart
// Place in lib/models/product_category.dart
class ProductCategory {
  final int id;
  final String name;
  final String? description;
  final int? parentCategoryId;

  ProductCategory({
    required this.id,
    required this.name,
    this.description,
    this.parentCategoryId,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      parentCategoryId: json['parent_category_id'],
    );
  }
}