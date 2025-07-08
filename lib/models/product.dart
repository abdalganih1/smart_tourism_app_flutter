// lib/models/product.dart
import 'package:smart_tourism_app/config/config.dart';
import 'package:smart_tourism_app/models/product_category.dart';
import 'package:smart_tourism_app/models/user.dart';

class Product {
  final int id;
  final int? sellerUserId; // <--- قد يكون null إذا كانت العلاقة غير محملة أو البائع محذوفاً
  final String name;
  final String? description;
  final double? price;
  final int? stockQuantity;
  final bool isAvailable;
  final String? mainImageUrl;
  final List<String>? galleryImageUrls;
  final ProductCategory? category;
  final User? seller; // <--- هذا يستدعي User.fromJson

  // حقول التاريخ
  final DateTime createdAt;
  final DateTime? updatedAt; // <--- يمكن أن يكون null في بعض الحالات

  Product({
    required this.id,
    this.sellerUserId, // جعله اختيارياً
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
    this.updatedAt, // جعله اختيارياً
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
    double? safeParseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Product(
      id: json['id'] as int,
      sellerUserId: json['seller_user_id'] as int?, // <--- قراءة كـ int?
      name: json['name'] ?? 'اسم المنتج غير متوفر',
      description: json['description'] as String?,
      price: safeParseDouble(json['price']),
      stockQuantity: json['stock_quantity'] as int?, // <--- قراءة كـ int?
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
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null, // <--- قراءة كـ DateTime?
    );
  }
}