// lib/models/site_experience.dart
import 'package:smart_tourism_app/config/config.dart'; // تأكد من هذا الاستيراد

import 'tourist_site.dart';
import 'user.dart';
import 'package:intl/intl.dart';

class SiteExperience {
  final int id;
  final int userId;
  final int siteId;
  final String? title;
  final String content;
  final String? photoUrl;
  final DateTime? visitDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Relations
  final User? user;
  final TouristSite? site;

  SiteExperience({
    required this.id,
    required this.userId,
    required this.siteId,
    this.title,
    required this.content,
    this.photoUrl,
    this.visitDate,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.site,
  });

  // Getter for full image URL, handling nulls and partial paths
  String? get imageUrl {
    if (photoUrl == null || photoUrl!.isEmpty) return null;
    if (photoUrl!.startsWith('http://') || photoUrl!.startsWith('https://')) {
      return photoUrl;
    }
    // Assumes photoUrl is something like 'profile_pictures/filename.jpg' or '/storage/path/filename.jpg'
    // Adjust if your API returns different paths
    return '${Config.httpUrl}/storage/${photoUrl!.startsWith('/') ? photoUrl!.substring(1) : photoUrl!}';
  }

  String? get formattedVisitDate {
    if (visitDate != null) {
      return DateFormat('yyyy-MM-dd').format(visitDate!);
    }
    return null;
  }

  factory SiteExperience.fromJson(Map<String, dynamic> json) {
    return SiteExperience(
      id: json['id'] as int, // يجب أن يكون موجوداً وغير null
      userId: json['user_id'] as int, // يجب أن يكون موجوداً وغير null
      siteId: json['site_id'] as int, // يجب أن يكون موجوداً وغير null
      title: json['title'] as String?, // قابل لـ null
      content: json['content'] as String, // غير قابل لـ null
      photoUrl: json['photo_url'] as String?, // قابل لـ null
      visitDate: json['visit_date'] != null ? DateTime.parse(json['visit_date']) : null, // قابل لـ null
      createdAt: DateTime.parse(json['created_at']), // غير قابل لـ null
      updatedAt: DateTime.parse(json['updated_at']), // غير قابل لـ null
      // التعامل مع العلاقات القابلة لـ null
      user: json.containsKey('user') && json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      site: json.containsKey('site') && json['site'] != null ? TouristSite.fromJson(json['site'] as Map<String, dynamic>) : null,
    );
  }
}