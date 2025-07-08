// lib/models/comment.dart
// Place in lib/models/comment.dart
import 'package:smart_tourism_app/utils/constants.dart';

import 'user.dart';
import 'article.dart';
import 'product.dart';
import 'tourist_site.dart';
import 'hotel.dart';
import 'site_experience.dart';

class Comment {
  final int id;
  final int userId;
  final String targetType;
  final int targetId;
  final int? parentCommentId; // Nullable FK for replies
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Relations
  final User? user; // User who wrote the comment
  final dynamic target; // Polymorphic Relation to the Commented Item
  final Comment? parent; // Parent comment (self-referencing)
  final List<Comment>? replies; // Replies to this comment


  Comment({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.target,
    this.parent,
    this.replies,
  });

   // Helper to get the target as a specific type
  T? getTargetAs<T>() {
    if (target is T) {
      return target as T;
    }
    return null;
  }


  factory Comment.fromJson(Map<String, dynamic> json) {
     // Parse the polymorphic 'target' based on 'target_type'
    dynamic parsedTarget;
    // Check if 'target' key exists and is not null before parsing
    if (json.containsKey('target') && json['target'] != null) {
      switch (json['target_type']) {
        case TargetTypes.article:
          parsedTarget = Article.fromJson(json['target']);
          break;
        case TargetTypes.product:
          parsedTarget = Product.fromJson(json['target']);
          break;
        case TargetTypes.touristSite:
          parsedTarget = TouristSite.fromJson(json['target']);
          break;
        case TargetTypes.hotel:
          parsedTarget = Hotel.fromJson(json['target']);
          break;
        case TargetTypes.siteExperience:
          parsedTarget = SiteExperience.fromJson(json['target']);
          break;
        default:
          print('Unknown target_type for Comment: ${json['target_type']}');
          parsedTarget = json['target'];
      }
    }


    return Comment(
      id: json['id'],
      userId: json['user_id'],
      targetType: json['target_type'],
      targetId: json['target_id'],
      parentCommentId: json['parent_comment_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      // Handle nullable relations
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      target: parsedTarget,
      parent: json['parent'] != null ? Comment.fromJson(json['parent']) : null, // Recursive call for parent
      replies: (json['replies'] as List?)
          ?.map((item) => Comment.fromJson(item))
          .toList(), // Recursive call for replies
    );
  }
}