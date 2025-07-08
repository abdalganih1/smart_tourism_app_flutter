// lib/repositories/hotel_repository.dart
import 'dart:async';
import '../models/hotel.dart';
import '../models/hotel_room.dart';
import '../models/hotel_room_type.dart';
import '../models/pagination.dart';
import '../services/api_service.dart';
import 'dart:developer'; // Import for log function for better logging

class HotelRepository {
  final ApiService _apiService;

  HotelRepository(this._apiService);

  // --- Hotels ---
  /// Fetches a paginated list of hotels.
  ///
  /// Filters can be applied by `city` and `starRating`.
  Future<PaginatedResponse<Hotel>> getHotels({int page = 1, String? city, int? starRating}) async {
    final response = await _apiService.get(
      '/hotels',
      queryParameters: {
        'page': page.toString(),
        'city': city,
        'star_rating': starRating?.toString(),
      },
      protected: false, // Public endpoint according to OpenAPI
    );

    log('API Response for /hotels: $response');

    // Ensure response is handled as a PaginatedResponse
    if (response is Map<String, dynamic>) {
        return PaginatedResponse<Hotel>.fromJson(response, (json) => Hotel.fromJson(json));
    } else {
        throw FormatException('Expected a paginated response for hotels, but received: $response');
    }
  }

  /// Fetches details for a specific hotel by its ID.
  Future<Hotel> getHotelDetails(int hotelId) async {
    final response = await _apiService.get('/hotels/$hotelId', protected: false); // Public endpoint
    log('API Response for /hotels/$hotelId: $response'); // Log individual hotel response

    // --- FIX APPLIED HERE ---
    if (response is Map<String, dynamic> && response.containsKey('data')) {
        // Access the 'data' key which contains the actual hotel object
        return Hotel.fromJson(response['data'] as Map<String, dynamic>);
    } else if (response is Map<String, dynamic>) {
        // Fallback for cases where 'data' key might be absent for single resources (less common but possible)
        return Hotel.fromJson(response);
    } else {
        throw FormatException('Expected a map response for hotel details, but received: $response');
    }
  }

  /// Fetches a list of rooms available in a specific hotel.
  ///
  /// Optional filters like `room_type_id` can be added if your API supports it.
  Future<List<HotelRoom>> getHotelRooms(int hotelId, {int? roomTypeId}) async {
    final response = await _apiService.get(
      '/hotels/$hotelId/rooms',
      queryParameters: {
        'room_type_id': roomTypeId?.toString(),
      },
      protected: false, // Public endpoint
    );
    log('API Response for /hotels/$hotelId/rooms: $response');

    // Ensure response is handled as a List of HotelRoom objects
    // If /hotels/{hotel}/rooms also returns a {data: [...]}, then you'd need to adjust here as well.
    // Based on OpenAPI it suggests a direct array for /hotels/{hotel}/rooms
    if (response is List) {
        return response.map((item) => HotelRoom.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is Map<String, dynamic> && response.containsKey('data')) {
        // If it returns { data: [...] } for rooms
        return (response['data'] as List).map((item) => HotelRoom.fromJson(item as Map<String, dynamic>)).toList();
    }
    else {
        throw FormatException('Expected a list of hotel rooms, but received: $response');
    }
  }

  /// Fetches a list of all available hotel room types.
  /// (Assuming a separate endpoint for this if needed globally, not just per hotel)
  /// Note: This endpoint is not explicitly in your provided OpenAPI,
  /// but often useful if you need to filter by room type.
  /// If it exists, it might be /hotel-room-types.
  Future<List<HotelRoomType>> getHotelRoomTypes() async {
    final response = await _apiService.get('/hotel-room-types', protected: false);
    log('API Response for /hotel-room-types: $response');

    // Assuming this might also be wrapped in 'data'
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return (response['data'] as List).map((item) => HotelRoomType.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response is List) {
      return response.map((item) => HotelRoomType.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw FormatException('Expected a list of hotel room types, but received: $response');
    }
  }
}