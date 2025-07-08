// lib/models/rating.dart
// Place in lib/models/rating.dart
import 'package:smart_tourism_app/utils/constants.dart';

import 'user.dart';
import 'polymorphic_target.dart';
import 'tourist_site.dart';
import 'product.dart';
import 'hotel.dart';
import 'article.dart';
import 'site_experience.dart';

class Rating {
  final int id;
  final int userId;
  final String targetType;
  final int targetId;
  final int ratingValue;
  final String? reviewTitle;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Relations
  final User? user; // User who wrote the rating
  final dynamic target; // Polymorphic Relation to the Rated Item


  Rating({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.ratingValue,
    this.reviewTitle,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.target,
  });

   // Helper to get the target as a specific type
  T? getTargetAs<T>() {
    if (target is T) {
      return target as T;
    }
    return null;
  }


  factory Rating.fromJson(Map<String, dynamic> json) {
     // Parse the polymorphic 'target' based on 'target_type'
    dynamic parsedTarget;
    if (json['target'] != null) {
      switch (json['target_type']) {
        case TargetTypes.touristSite:
          parsedTarget = TouristSite.fromJson(json['target']);
          break;
        case TargetTypes.product:
          parsedTarget = Product.fromJson(json['target']);
          break;
        case TargetTypes.hotel:
          parsedTarget = Hotel.fromJson(json['target']);
          break;
        case TargetTypes.article:
          parsedTarget = Article.fromJson(json['target']);
          break;
         case TargetTypes.siteExperience: // Added if SiteExperience can be rated
          parsedTarget = SiteExperience.fromJson(json['target']);
          break;
        default:
          print('Unknown target_type for Rating: ${json['target_type']}');
          parsedTarget = json['target'];
      }
    }


    return Rating(
      id: json['id'],
      userId: json['user_id'],
      targetType: json['target_type'],
      targetId: json['target_id'],
      ratingValue: json['rating_value'],
      reviewTitle: json['review_title'],
      reviewText: json['review_text'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      // Handle nullable relations
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      target: parsedTarget,
    );
  }
}
