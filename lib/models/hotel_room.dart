// lib/models/hotel_room.dart
import 'package:smart_tourism_app/models/hotel.dart';
import 'package:smart_tourism_app/models/hotel_room_type.dart';

class HotelRoom {
  final int id;
  final int? hotelId; // <<< FIX: Made nullable
  final int? roomTypeId; // <<< FIX: Made nullable
  final String? roomNumber; // <<< FIX: Made nullable
  final double? pricePerNight; // <<< FIX: Made nullable
  final double? areaSqm;
  final int? maxOccupancy;
  final String? description;
  final bool? isAvailableForBooking; // <<< FIX: Made nullable
  final DateTime? createdAt; // <<< FIX: Made nullable
  final DateTime? updatedAt; // <<< FIX: Made nullable
  // Relations
  final Hotel? hotel;
  final HotelRoomType? type;

  HotelRoom({
    required this.id,
    this.hotelId, // No longer required in constructor
    this.roomTypeId, // No longer required in constructor
    this.roomNumber, // No longer required in constructor
    this.pricePerNight, // No longer required in constructor
    this.areaSqm,
    this.maxOccupancy,
    this.description,
    this.isAvailableForBooking, // No longer required in constructor
    this.createdAt, // No longer required in constructor
    this.updatedAt, // No longer required in constructor
    this.hotel,
    this.type,
  });

  factory HotelRoom.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse a value into a double.
    double? safeParseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    return HotelRoom(
      id: json['id'] as int,
      hotelId: json['hotel_id'] as int?, // <<< FIX: Read as nullable int
      roomTypeId: json['room_type_id'] as int?, // <<< FIX: Read as nullable int
      roomNumber: json['room_number'] as String?, // <<< FIX: Read as nullable String
      pricePerNight: safeParseDouble(json['price_per_night']), // <<< FIX: Use safe double parsing
      areaSqm: safeParseDouble(json['area_sqm']),
      maxOccupancy: json['max_occupancy'] as int?,
      description: json['description'] as String?,
      isAvailableForBooking: json['is_available_for_booking'] == 1 || json['is_available_for_booking'] == true, // Reads as bool, but is the type bool? in model
      createdAt: parseDate(json['created_at'] as String?), // <<< FIX: Use safe date parsing
      updatedAt: parseDate(json['updated_at'] as String?), // <<< FIX: Use safe date parsing
      hotel: json.containsKey('hotel') && json['hotel'] != null
          ? Hotel.fromJson(json['hotel'] as Map<String, dynamic>)
          : null,
      type: json.containsKey('type') && json['type'] != null
          ? HotelRoomType.fromJson(json['type'] as Map<String, dynamic>)
          : null,
    );
  }
}