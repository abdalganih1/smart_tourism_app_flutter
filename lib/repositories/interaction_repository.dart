// lib/repositories/interaction_repository.dart
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/favorite.dart';
import '../models/rating.dart';
import '../models/comment.dart';
import '../models/site_experience.dart';
import '../models/pagination.dart';
import '../services/api_service.dart';
import '../utils/constants.dart'; // For TargetTypes

class InteractionRepository {
  final ApiService _apiService;

  InteractionRepository(this._apiService);

  // Helper function to convert TargetType enum value string to API path format
  // e.g., 'TouristSite' -> 'tourist-sites'
  // This assumes the API paths are lowercase and hyphen-separated (kebab-case)
  String _mapTargetTypeToApiPath(String targetType) {
    switch (targetType) {
      case TargetTypes.touristSite:
        return 'tourist-sites';
      case TargetTypes.product:
        return 'products';
      case TargetTypes.article:
        return 'articles';
      case TargetTypes.hotel:
        return 'hotels';
      case TargetTypes.siteExperience: // If you fetch experiences of experiences (unlikely)
        return 'site-experiences';
      default:
        // Fallback for unknown types, or throw an error if an unknown type is critical
        return targetType.toLowerCase(); // Basic lowercase conversion
    }
  }

  // --- Favorites ---
  Future<Map<String, dynamic>> toggleFavorite(String targetType, int targetId) async {
    final response = await _apiService.post('/favorites/toggle', {'target_type': targetType, 'target_id': targetId}, protected: true);
    return response as Map<String, dynamic>;
  }

  Future<PaginatedResponse<Favorite>> getMyFavorites({int page = 1}) async {
    final response = await _apiService.get('/my-favorites', queryParameters: {'page': page.toString()}, protected: true);
    return PaginatedResponse<Favorite>.fromJson(response, (json) => Favorite.fromJson(json));
  }

  Future<Map<String, dynamic>> checkFavoriteStatus(String targetType, int targetId) async {
    // FIX: استخدم الدالة المساعدة لتحويل targetType إلى مسار API صحيح
    final apiPath = _mapTargetTypeToApiPath(targetType);
    final response = await _apiService.get('/$apiPath/$targetId/is-favorited', protected: true);
    return response as Map<String, dynamic>;
  }

  // --- Ratings ---
  Future<dynamic> addRating(Map<String, dynamic> data) async {
    return await _apiService.post('/ratings', data, protected: true);
  }

  Future<Rating> updateRating(int ratingId, Map<String, dynamic> ratingData) async {
    final response = await _apiService.put('/ratings/$ratingId', ratingData, protected: true);
    return Rating.fromJson(response);
  }

  Future<void> deleteRating(int ratingId) async {
    await _apiService.delete('/ratings/$ratingId', protected: true);
  }

  Future<PaginatedResponse<Rating>> getRatingsForTarget(String targetType, int targetId, {int page = 1}) async {
    // FIX: استخدم الدالة المساعدة لتحويل targetType إلى مسار API صحيح
    final apiPath = _mapTargetTypeToApiPath(targetType);
    final response = await _apiService.get('/$apiPath/$targetId/ratings', queryParameters: {'page': page.toString()}, protected: false);
    return PaginatedResponse<Rating>.fromJson(response, (json) => Rating.fromJson(json));
  }

  // --- Comments ---
  Future<dynamic> addComment(Map<String, dynamic> data) async {
    return await _apiService.post('/comments', data, protected: true);
  }

  Future<Comment> updateComment(int commentId, Map<String, dynamic> commentData) async {
    final response = await _apiService.put('/comments/$commentId', commentData, protected: true);
    return Comment.fromJson(response);
  }

  Future<void> deleteComment(int commentId) async {
    await _apiService.delete('/comments/$commentId', protected: true);
  }

  Future<PaginatedResponse<Comment>> getCommentsForTarget(String targetType, int targetId, {int page = 1}) async {
    // FIX: استخدم الدالة المساعدة لتحويل targetType إلى مسار API صحيح
    final apiPath = _mapTargetTypeToApiPath(targetType);
    final response = await _apiService.get('/$apiPath/$targetId/comments', queryParameters: {'page': page.toString()}, protected: false);
    return PaginatedResponse<Comment>.fromJson(response, (json) => Comment.fromJson(json));
  }

  Future<PaginatedResponse<Comment>> getCommentReplies(int commentId, {int page = 1}) async {
    final response = await _apiService.get('/comments/$commentId/replies', queryParameters: {'page': page.toString()}, protected: false);
    return PaginatedResponse<Comment>.fromJson(response, (json) => Comment.fromJson(json));
  }

  // --- Site Experiences ---
  Future<PaginatedResponse<SiteExperience>> getExperiencesForTarget(String targetType, int targetId, {int page = 1}) async {
    // FIX: استخدم الدالة المساعدة لتحويل targetType إلى مسار API صحيح
    final apiPath = _mapTargetTypeToApiPath(targetType);
    final response = await _apiService.get('/$apiPath/$targetId/experiences', queryParameters: {'page': page.toString()}, protected: false);
    return PaginatedResponse<SiteExperience>.fromJson(response, (json) => SiteExperience.fromJson(json));
  }

  Future<dynamic> addExperience(Map<String, dynamic> data, {File? photoFile}) async {
    if (photoFile != null) {
      final stringFields = data.map((key, value) => MapEntry(key, value.toString()));
      final response = await _apiService.postMultipart(
        '/experiences',
        stringFields,
        file: http.MultipartFile.fromBytes(
          'photo',
          photoFile.readAsBytesSync(),
          filename: photoFile.path.split('/').last,
        ),
        protected: true,
      );
      return response;
    } else {
      final response = await _apiService.post('/experiences', data, protected: true);
      return response;
    }
  }
}