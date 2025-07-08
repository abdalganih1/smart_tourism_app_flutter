// lib/repositories/tourism_repository.dart
import 'dart:async';
import 'package:intl/intl.dart' as intl; // Added as intl to avoid TextDirection conflict
import 'package:smart_tourism_app/models/article.dart';
import 'package:smart_tourism_app/models/favorite.dart';
import 'package:smart_tourism_app/models/product.dart';
import 'package:smart_tourism_app/models/product_category.dart';

import '../models/tourist_site.dart';
import '../models/site_category.dart';
import '../models/tourist_activity.dart';
// import '../models/hotel.dart'; // <--- Remove this import
// import '../models/hotel_room.dart'; // <--- Remove this import
import '../models/pagination.dart';
import '../services/api_service.dart';

class TourismRepository {
  final ApiService _apiService;

  TourismRepository(this._apiService);

  // --- Tourist Sites ---
  Future<PaginatedResponse<TouristSite>> getTouristSites({int page = 1, String? city, int? categoryId}) async {
    final response = await _apiService.get(
      '/tourist-sites',
      queryParameters: {'page': page.toString(), 'city': city, 'category_id': categoryId?.toString()},
      protected: false, // Public endpoint
    );
    if (response is Map<String, dynamic>) {
        return PaginatedResponse<TouristSite>.fromJson(response, (json) => TouristSite.fromJson(json));
    } else {
        throw FormatException('Expected a paginated response for tourist sites, but received: $response');
    }
  }

 // lib/repositories/tourism_repository.dart

// ...

Future<TouristSite> getTouristSiteDetails(int siteId) async {
  final response = await _apiService.get('/tourist-sites/$siteId', protected: false);
  
  // تحقق من أن الاستجابة هي خريطة وتحتوي على مفتاح 'data'
  if (response is Map<String, dynamic> && response.containsKey('data')) {
      // The Fix! استخرج الكائن من مفتاح 'data'
      return TouristSite.fromJson(response['data'] as Map<String, dynamic>);
  } 
  // كإجراء احتياطي، إذا كانت الـ API لا تغلف البيانات
  else if (response is Map<String, dynamic>) {
      return TouristSite.fromJson(response);
  }
  else {
      throw FormatException('Expected a single tourist site object (map), but received: $response');
  }
}

// ...

  Future<List<SiteCategory>> getSiteCategories() async {
    final response = await _apiService.get('/site-categories', protected: false); // Public endpoint

    // افتراض أن الاستجابة هي PaginatedResponse (Map يحتوي على 'data')
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return (response['data'] as List)
          .map((item) => SiteCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response is List) {
      // هذا المسار يكون إذا كانت الاستجابة مباشرة عبارة عن قائمة
      return response
          .map((item) => SiteCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw const FormatException('Expected a list or a map with "data" key for Site Categories response.');
    }
  }

  // --- Tourist Activities ---
  Future<PaginatedResponse<TouristActivity>> getTouristActivities({int page = 1, int? siteId, DateTime? dateFrom}) async {
     final response = await _apiService.get(
      '/tourist-activities',
      queryParameters: {
        'page': page.toString(),
        'site_id': siteId?.toString(),
        'date_from': dateFrom != null ? intl.DateFormat('yyyy-MM-dd').format(dateFrom) : null, // Use intl.DateFormat
      },
      protected: false, // Public endpoint
    );
    if (response is Map<String, dynamic>) {
        return PaginatedResponse<TouristActivity>.fromJson(response, (json) => TouristActivity.fromJson(json));
    } else {
        throw FormatException('Expected a paginated response for tourist activities, but received: $response');
    }
  }

  Future<TouristActivity> getTouristActivityDetails(int activityId) async {
    final response = await _apiService.get('/tourist-activities/$activityId', protected: false); // Public endpoint
    if (response is Map<String, dynamic>) {
        return TouristActivity.fromJson(response);
    } else {
        throw FormatException('Expected a single tourist activity object, but received: $response');
    }
  }


  // --- Hotels --- <--- REMOVE OR COMMENT OUT THIS ENTIRE SECTION
  // Future<PaginatedResponse<Hotel>> getHotels({int page = 1, String? city, int? starRating}) async {
  //    final response = await _apiService.get(
  //     '/hotels',
  //     queryParameters: {'page': page.toString(), 'city': city, 'star_rating': starRating?.toString()},
  //     protected: false,
  //   );
  //   return PaginatedResponse<Hotel>.fromJson(response, (json) => Hotel.fromJson(json));
  // }

  // Future<Hotel> getHotelDetails(int hotelId) async {
  //   final response = await _apiService.get('/hotels/$hotelId', protected: false);
  //   return Hotel.fromJson(response);
  // }

  // Future<List<HotelRoom>> getHotelRooms(int hotelId) async {
  //    // Assuming an endpoint like /hotels/{hotel}/rooms
  //   final response = await _apiService.get('/hotels/$hotelId/rooms', protected: false);
  //   return (response as List).map((item) => HotelRoom.fromJson(item)).toList();
  // }


  // --- Products (Crafts) ---
   Future<PaginatedResponse<Product>> getProducts({int page = 1, int? categoryId, String? query}) async {
     final response = await _apiService.get(
      '/products',
      queryParameters: {'page': page.toString(), 'category_id': categoryId?.toString(), 'query': query},
      protected: false, // Public endpoint
    );
    if (response is Map<String, dynamic>) {
        return PaginatedResponse<Product>.fromJson(response, (json) => Product.fromJson(json));
    } else {
        throw FormatException('Expected a paginated response for products, but received: $response');
    }
  }

// lib/repositories/tourism_repository.dart

// ... other methods

Future<Product> getProductDetails(int productId) async {
  final response = await _apiService.get('/products/$productId', protected: false);
  
  // The API likely wraps the single product in a "data" key.
  if (response is Map<String, dynamic> && response.containsKey('data')) {
      return Product.fromJson(response['data'] as Map<String, dynamic>);
  } 
  // Fallback if the API returns the object directly
  else if (response is Map<String, dynamic>) {
      return Product.fromJson(response);
  }
  else {
      throw FormatException('Expected a single product object (map), but received: $response');
  }
}

// ... other methods

   Future<List<ProductCategory>> getProductCategories() async {
    final response = await _apiService.get('/product-categories', protected: false); // Public endpoint
    // Assuming this also returns a paginated response based on API structure
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return (response['data'] as List)
          .map((item) => ProductCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response is List) {
      return response
          .map((item) => ProductCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw const FormatException('Expected a list or a map with "data" key for Product Categories response.');
    }
  }

  // --- Articles (Blog) ---
  Future<PaginatedResponse<Article>> getArticles({int page = 1}) async {
    final response = await _apiService.get(
      '/articles',
      queryParameters: {'page': page.toString()},
      protected: false, // Public endpoint
    );
    if (response is Map<String, dynamic>) {
        return PaginatedResponse<Article>.fromJson(response, (json) => Article.fromJson(json));
    } else {
        throw FormatException('Expected a paginated response for articles, but received: $response');
    }
  }
  Future<Article> getArticleDetails(int articleId) async {
    final response = await _apiService.get('/articles/$articleId', protected: false);
    // The API likely wraps the single article in a "data" key.
    if (response is Map<String, dynamic> && response.containsKey('data')) {
        return Article.fromJson(response['data'] as Map<String, dynamic>);
    }
    // Fallback if the API returns the object directly
    else if (response is Map<String, dynamic>) {
        return Article.fromJson(response);
    }
    else {
        throw FormatException('Expected a single article object (map), but received: $response');
    }
  }
 
   // --- Favorites ---
  Future<PaginatedResponse<Favorite>> getMyFavorites({int page = 1}) async {
    final response = await _apiService.get(
      '/my-favorites',
      queryParameters: {'page': page.toString()},
      protected: true, // Protected endpoint
    );
    if (response is Map<String, dynamic>) {
        return PaginatedResponse<Favorite>.fromJson(response, (json) => Favorite.fromJson(json));
    } else {
        throw FormatException('Expected a paginated response for favorites, but received: $response');
    }
  }

  // يمكنك إضافة دالة للتبديل (إضافة/إزالة) المفضلة عبر API
  Future<Map<String, dynamic>> toggleFavorite({required String targetType, required int targetId}) async {
    final response = await _apiService.post(
      '/favorites/toggle',
      {'target_type': targetType, 'target_id': targetId}, // Passing body as positional argument
      protected: true,
    );
    if (response is Map<String, dynamic>) {
        return response; // Returns message and is_favorited status
    } else {
        throw FormatException('Expected a map response for toggleFavorite, but received: $response');
    }
  }
}