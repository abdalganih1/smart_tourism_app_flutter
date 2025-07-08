// lib/models/site_category.dart
// Place in lib/models/site_category.dart
class SiteCategory {
  final int? id; // <--- تغيير النوع إلى int? للسماح بـ null
  final String name;
  final String? description;
  final int? parentCategoryId; // <--- تأكد أن هذا أيضاً int?

  SiteCategory({
    required this.id, // <--- يجب أن يكون id من النوع int?
    required this.name,
    this.description,
    this.parentCategoryId, // <--- تأكد أن هذا أيضاً int?
  });

  factory SiteCategory.fromJson(Map<String, dynamic> json) {
    return SiteCategory(
      id: json['id'] as int?, // <--- قراءة id كـ int?
      name: json['name'],
      description: json['description'],
      parentCategoryId: json['parent_category_id'] as int?, // <--- قراءة parentCategoryId كـ int?
    );
  }
}