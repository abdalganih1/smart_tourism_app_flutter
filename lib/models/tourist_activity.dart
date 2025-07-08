// lib/models/tourist_activity.dart
import 'package:smart_tourism_app/models/tourist_site.dart';
import 'package:smart_tourism_app/models/user.dart';

class TouristActivity {
  final int? id;
  final String? name;
  final String? description;
  final int? siteId;
  final String? locationText;
  final DateTime? startDatetime;
  final int? durationMinutes;
  final int? organizerUserId;
  final double? price; // يمكن أن يأتي كـ String
  final int? maxParticipants;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TouristSite? site;
  final User? organizer;
  final String? mainImageUrl; // Add this if activity has its own image

  TouristActivity({
    this.id,
    this.name,
    this.description,
    this.siteId,
    this.locationText,
    this.startDatetime,
    this.durationMinutes,
    this.organizerUserId,
    this.price,
    this.maxParticipants,
    this.createdAt,
    this.updatedAt,
    this.site,
    this.organizer,
    this.mainImageUrl,
  });

  factory TouristActivity.fromJson(Map<String, dynamic> json) {
    return TouristActivity(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null, // <--- تحويل آمن
      name: (json['name'] as String?) ?? 'نشاط',
      description: (json['description'] as String?),
      siteId: json['site_id'] != null ? int.tryParse(json['site_id'].toString()) : null, // <--- تحويل آمن
      locationText: (json['location_text'] as String?),
      startDatetime: json['start_datetime'] != null ? DateTime.parse(json['start_datetime'] as String) : null,
      durationMinutes: json['duration_minutes'] != null ? int.tryParse(json['duration_minutes'].toString()) : null, // <--- تحويل آمن
      organizerUserId: json['organizer_user_id'] != null ? int.tryParse(json['organizer_user_id'].toString()) : null, // <--- تحويل آمن
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null, // <--- تحويل آمن (الأكثر احتمالاً للمشكلة)
      maxParticipants: json['max_participants'] != null ? int.tryParse(json['max_participants'].toString()) : null, // <--- تحويل آمن
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      site: json['site'] != null ? TouristSite.fromJson(json['site'] as Map<String, dynamic>) : null,
      organizer: json['organizer'] != null ? User.fromJson(json['organizer'] as Map<String, dynamic>) : null,
      mainImageUrl: (json['main_image_url'] as String?), // Assuming this field might exist
    );
  }
}