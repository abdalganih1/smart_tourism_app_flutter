// lib/models/hotel.dart
import 'package:smart_tourism_app/config/config.dart';
import 'package:smart_tourism_app/models/hotel_room.dart';
import 'package:smart_tourism_app/models/user.dart'; // استيراد موديل User

class Hotel {
  final int id;
  final String? name; // <<< FIX: Made nullable (from previous fixes)
  final int? starRating;
  final String? description;
  final String? addressLine1;
  final String? city; // <<< FIX: Made nullable (from previous fixes)
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? contactPhone;
  final String? contactEmail;
  final String? mainImageUrl;
  final int? managedByUserId;
  final DateTime? createdAt; // <<< FIX: Made nullable
  final DateTime? updatedAt;
  final User? managedBy;
  final List<HotelRoom>? rooms;

  Hotel({
    required this.id,
    this.name, // No longer required in constructor
    this.starRating,
    this.description,
    this.addressLine1,
    this.city, // No longer required in constructor
    this.country,
    this.latitude,
    this.longitude,
    this.contactPhone,
    this.contactEmail,
    this.mainImageUrl,
    this.managedByUserId,
    this.createdAt, // No longer required in constructor
    this.updatedAt,
    this.managedBy,
    this.rooms,
  });

  String? get imageUrl {
    if (mainImageUrl == null) return null;
    if (mainImageUrl!.startsWith('http')) {
      return mainImageUrl;
    }
    return '${Config.httpUrl}/storage/$mainImageUrl';
  }

  factory Hotel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // <<< FIX: Helper to safely parse DateTime
    DateTime? parseDate(dynamic dateStr) {
      if (dateStr == null) return null;
      if (dateStr is String) {
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          return null; // Return null if parsing fails
        }
      }
      return null; // Return null if not a string
    }

    return Hotel(
      id: json['id'] as int,
      name: json['name'] as String?, // <<< FIX: Read as nullable String
      starRating: json['star_rating'] as int?,
      description: json['description'] as String?,
      addressLine1: json['address_line1'] as String?,
      city: json['city'] as String?, // <<< FIX: Read as nullable String
      country: json['country'] as String?,
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      mainImageUrl: json['main_image_url'] as String?,
      managedByUserId: json['managed_by_user_id'] as int?,
      createdAt: parseDate(json['created_at']), // <<< FIX: Use safe date parsing
      updatedAt: parseDate(json['updated_at']), // already using safe parsing here
      managedBy: json['managed_by'] != null ? User.fromJson(json['managed_by'] as Map<String, dynamic>) : null,
      rooms: json.containsKey('rooms') && json['rooms'] != null
          ? (json['rooms'] as List).map((roomJson) => HotelRoom.fromJson(roomJson as Map<String, dynamic>)).toList()
          : null,
    );
  }
}