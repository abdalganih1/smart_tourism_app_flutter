// lib/models/tourist_site.dart
import 'package:smart_tourism_app/config/config.dart';

import 'site_category.dart';
import 'user.dart';

class TouristSite {
  final int? id;
  final String? name;
  final String? description;
  final String? locationText;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? country;
  final int? categoryId;
  final String? mainImageUrl;
  final String? videoUrl;
  final int? addedByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Relations
  final SiteCategory? category;
  final User? addedBy;

  TouristSite({
    this.id,
    this.name,
    this.description,
    this.locationText,
    this.latitude,
    this.longitude,
    this.city,
    this.country,
    this.categoryId,
    this.mainImageUrl,
    this.videoUrl,
    this.addedByUserId,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.addedBy,
  });

  String? get imageUrl {
     // تأكد من أن mainImageUrl غير null قبل استخدام startsWith
     if (mainImageUrl != null && mainImageUrl!.startsWith('/storage')) {
      return Config.httpUrl + mainImageUrl!;
    }
    return mainImageUrl;
  }

  factory TouristSite.fromJson(Map<String, dynamic> json) {
    return TouristSite(
      // التحويل الآمن لـ ID و NAME باستخدام tryParse أو cast ثم ??
      id: json['id'] != null ? (json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id'].toString())) : null,
      name: (json['name'] as String?) ?? 'غير معروف', // آمن، إذا null تصبح 'غير معروف'
      description: (json['description'] as String?),
      locationText: (json['location_text'] as String?),
      latitude: json['latitude'] != null ? (json['latitude'] is num ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude'].toString())) : null,
      longitude: json['longitude'] != null ? (json['longitude'] is num ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude'].toString())) : null,
      city: (json['city'] as String?),
      country: (json['country'] as String?) ?? 'Syria',
      categoryId: json['category_id'] != null ? (json['category_id'] is num ? (json['category_id'] as num).toInt() : int.tryParse(json['category_id'].toString())) : null,
      mainImageUrl: (json['main_image_url'] as String?),
      videoUrl: (json['video_url'] as String?),
      addedByUserId: json['added_by_user_id'] != null ? (json['added_by_user_id'] is num ? (json['added_by_user_id'] as num).toInt() : int.tryParse(json['added_by_user_id'].toString())) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null, // استخدام tryParse للتواريخ أيضاً
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null, // استخدام tryParse للتواريخ أيضاً
      category: json['category'] != null ? SiteCategory.fromJson(json['category'] as Map<String, dynamic>) : null,
      addedBy: json['added_by'] != null ? User.fromJson(json['added_by'] as Map<String, dynamic>) : null,
    );
  }
}