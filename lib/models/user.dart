// lib/models/user.dart
import 'package:smart_tourism_app/models/user_phone_number.dart';
import 'package:smart_tourism_app/models/user_profile.dart';

import '../utils/constants.dart'; // Assuming UserTypes is defined here

class User {
  final int id;
  final String username;
  final String email;
  final String userType;
  final bool? isActive; // <<< FIX: Made nullable
  final DateTime? createdAt; // <<< FIX: Made nullable
  final DateTime? updatedAt; // <<< FIX: Made nullable
  final UserProfile? profile;
  final List<UserPhoneNumber>? phoneNumbers;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.userType,
    this.isActive, // No longer required in constructor
    this.createdAt, // No longer required in constructor
    this.updatedAt, // No longer required in constructor
    this.profile,
    this.phoneNumbers,
  });

  // Helper methods for role checking
  bool isAdmin() => userType == UserTypes.admin;
  bool isVendor() => userType == UserTypes.vendor;
  bool isTourist() => userType == UserTypes.tourist;
  bool isHotelBookingManager() => userType == UserTypes.hotelBookingManager;
  bool isArticleWriter() => userType == UserTypes.articleWriter;
  bool isEmployee() => userType == UserTypes.employee;

  String translatedAccountType() {
    switch (userType) {
      case UserTypes.admin:
        return 'مدير النظام';
      case UserTypes.employee:
        return 'موظف';
      case UserTypes.hotelBookingManager:
        return 'مدير فندق';
      case UserTypes.articleWriter:
        return 'كاتب مقالات';
      case UserTypes.vendor:
        return 'بائع';
      case UserTypes.tourist:
      default:
        return 'سائح';
    }
  }

  // Factory constructor to create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // Helper for safe integer parsing (from int, double, or string)
    int? safeParseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper for safe boolean parsing (from bool, 0/1 int, or "true"/"false" string)
    bool? safeParseBool(dynamic value) {
      if (value == null) return null; // <<< FIX: Return null if value is null
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return null; // <<< FIX: Return null for unhandled types
    }

    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    return User(
      id: safeParseInt(json['id']) ?? 0, // Assume ID is always present, default to 0
      username: (json['username'] as String?) ?? 'مستخدم غير معروف', // <<< FIX: Default if null
      email: (json['email'] as String?) ?? 'unknown@example.com', // <<< FIX: Default if null
      userType: (json['user_type'] as String?) ?? UserTypes.tourist, // <<< FIX: Default if null
      isActive: safeParseBool(json['is_active']), // <<< FIX: Use safeParseBool (returns bool?)
      createdAt: parseDate(json['created_at'] as String?), // <<< FIX: Use safe date parsing
      updatedAt: parseDate(json['updated_at'] as String?), // <<< FIX: Use safe date parsing
      profile: json['profile'] != null ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>) : null,
      phoneNumbers: (json['phone_numbers'] as List?)
          ?.map((item) => UserPhoneNumber.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}