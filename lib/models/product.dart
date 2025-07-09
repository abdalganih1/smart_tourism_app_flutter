// lib/models/product.dart

// 1. أضف استيراد لملف الإعدادات الخاص بك للوصول إلى الرابط الأساسي
import 'package:smart_tourism_app/config/config.dart';
import 'package:smart_tourism_app/models/product_category.dart';
import 'package:smart_tourism_app/models/user.dart';

class Product {
  final int id;
  final int? sellerUserId; // <--- قد يكون null إذا كانت العلاقة غير محملة أو البائع محذوفاً
  final String name;
  final String? description;
  final double? price; // يمكن أن يكون null إذا لم يتم تحويله
  final int? stockQuantity;
  final bool isAvailable; // يمكن أن يكون null في JSON، لكن يتم تحويله لـ bool
  final String? mainImageUrl;
  final List<String>? galleryImageUrls;
  final ProductCategory? category;
  final User? seller;

  final DateTime createdAt;
  final DateTime? updatedAt; // يمكن أن يكون null في بعض الحالات

  Product({
    required this.id,
    this.sellerUserId,
    required this.name,
    this.description,
    this.price,
    this.stockQuantity,
    required this.isAvailable,
    this.mainImageUrl,
    this.galleryImageUrls,
    this.category,
    this.seller,
    required this.createdAt,
    this.updatedAt,
  });

  String? get imageUrl {
    if (mainImageUrl == null) {
      return null;
    }
    if (mainImageUrl!.startsWith('http')) {
      return mainImageUrl;
    }
    return Config.httpUrl + mainImageUrl!;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse a value into a double.
    // Handles int, double, and string representations.
    double? safeParseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // <<< FIX: Remove commas from the string before parsing
        final cleanedString = value.replaceAll(',', '');
        return double.tryParse(cleanedString);
      }
      return null;
    }
    
    // Helper to safely parse DateTime
    DateTime? parseDate(dynamic dateStr) {
      if (dateStr == null) return null;
      if (dateStr is String) {
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          return null;
        }
      }
      return null;
    }


    return Product(
      id: json['id'] as int,
      sellerUserId: json['seller_user_id'] as int?,
      name: json['name'] as String? ?? 'اسم المنتج غير متوفر', // Default value for name if null
      description: json['description'] as String?,
      price: safeParseDouble(json['price']), // <<< FIX: safeParseDouble will now handle commas
      stockQuantity: json['stock_quantity'] as int?,
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      mainImageUrl: json['main_image_url'] as String?,
      galleryImageUrls: json['gallery_image_urls'] != null
          ? List<String>.from(json['gallery_image_urls'])
          : null,
      category: json.containsKey('category') && json['category'] != null
          ? ProductCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      seller: json.containsKey('seller') && json['seller'] != null
          ? User.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      createdAt: parseDate(json['created_at'])!, // <<< FIX: Use parseDate helper
      updatedAt: parseDate(json['updated_at']), // <<< FIX: Use parseDate helper
    );
  }
}