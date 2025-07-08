// lib/models/favorite.dart
// (تأكد من استيراد جميع المودلات اللازمة هنا)
import 'package:smart_tourism_app/models/article.dart';
import 'package:smart_tourism_app/models/hotel.dart';
import 'package:smart_tourism_app/models/product.dart';
import 'package:smart_tourism_app/models/site_experience.dart';
import 'package:smart_tourism_app/models/tourist_site.dart';
import 'package:smart_tourism_app/models/user.dart';

class Favorite {
  final int? id; // <<--- جعلته قابلًا لـ null لأن API يرجعه null
  final int userId;
  final String targetType;
  final int targetId;
  final dynamic target;
  final DateTime addedAt; // <<--- FIX: غيرت الاسم ليتطابق مع API
  final User? user; // (إذا كان API يرجعه)

  Favorite({
    this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    this.target,
    required this.addedAt, // <<--- FIX: غيرت الاسم في الـ constructor
    this.user,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    // Helper to parse the polymorphic 'target' object based on 'target_type'
    dynamic parseTarget(Map<String, dynamic> targetJson, String type) {
      switch (type) {
        case 'TouristSite':
          return TouristSite.fromJson(targetJson);
        case 'Product':
          return Product.fromJson(targetJson);
        case 'Article':
          return Article.fromJson(targetJson);
        case 'Hotel':
          return Hotel.fromJson(targetJson);
        case 'SiteExperience':
          return SiteExperience.fromJson(targetJson);
        default:
          return targetJson; // Fallback to raw JSON if type is unknown
      }
    }

    // FIXES HERE: Safely parse all fields
    final int? parsedId = (json['id'] as int?); // Allow null
    final int parsedUserId = (json['user_id'] as int?) ?? 0; // Default if null
    final String parsedTargetType = (json['target_type'] as String?) ?? 'unknown_type';
    final int parsedTargetId = (json['target_id'] as int?) ?? 0;
    // FIX: Parse 'added_at' and provide a fallback if it's null
    final DateTime parsedAddedAt = json['added_at'] != null 
        ? DateTime.parse(json['added_at']) 
        : DateTime.now(); // Fallback to current time if 'added_at' is null

    return Favorite(
      id: parsedId,
      userId: parsedUserId,
      targetType: parsedTargetType,
      targetId: parsedTargetId,
      addedAt: parsedAddedAt, // <<--- FIX: استخدام الحقل الجديد
      user: json.containsKey('user') && json['user'] != null ? User.fromJson(json['user']) : null,
      target: json.containsKey('target') && json['target'] != null
          ? parseTarget(json['target'] as Map<String, dynamic>, parsedTargetType)
          : null,
    );
  }
}