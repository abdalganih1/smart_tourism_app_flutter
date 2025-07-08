// lib/models/hotel_booking.dart
import 'package:smart_tourism_app/models/hotel_room.dart';
import 'package:smart_tourism_app/models/user.dart';

class HotelBooking {
  final int id; // <--- يمكن تركه int (غير قابل للـ null)
  final int? userId;
  final int? roomId;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int? numAdults;
  final int? numChildren;
  final double? totalAmount;
  final String? bookingStatus;
  final String? paymentStatus;
  final String? paymentTransactionId;
  final DateTime? bookedAt;
  final String? specialRequests;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user;
  final HotelRoom? room;

  HotelBooking({
    required this.id, // ID لا يزال مطلوباً في الكونستركتور
    this.userId,
    this.roomId,
    this.checkInDate,
    this.checkOutDate,
    this.numAdults,
    this.numChildren,
    this.totalAmount,
    this.bookingStatus,
    this.paymentStatus,
    this.paymentTransactionId,
    this.bookedAt,
    this.specialRequests,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.room,
  });

  factory HotelBooking.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
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

    return HotelBooking(
      // <<< FIX: Use null-aware cast and provide a default value (e.g., 0)
      id: json['id'] as int? ?? 0, // إذا كان json['id'] هو null، فسيتم تعيين 0
      userId: json['user_id'] as int?,
      roomId: json['room_id'] as int?,
      checkInDate: parseDate(json['check_in_date'] as String?),
      checkOutDate: parseDate(json['check_out_date'] as String?),
      numAdults: json['num_adults'] as int?,
      numChildren: json['num_children'] as int?,
      totalAmount: parseDouble(json['total_amount']),
      bookingStatus: json['booking_status'] as String?,
      paymentStatus: json['payment_status'] as String?,
      paymentTransactionId: json['payment_transaction_id'] as String?,
      bookedAt: parseDate(json['booked_at'] as String?),
      specialRequests: json['special_requests'] as String?,
      createdAt: parseDate(json['created_at'] as String?),
      updatedAt: parseDate(json['updated_at'] as String?),
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      room: json['room'] != null ? HotelRoom.fromJson(json['room'] as Map<String, dynamic>) : null,
    );
  }
}