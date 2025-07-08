// lib/models/user_phone_number.dart
// Place in lib/models/user_phone_number.dart
import 'user.dart';

class UserPhoneNumber {
  final int id;
  final int userId;
  final String phoneNumber;
  final bool isPrimary;
  final String? description;

  UserPhoneNumber({
    required this.id,
    required this.userId,
    required this.phoneNumber,
    required this.isPrimary,
    this.description,
  });

  factory UserPhoneNumber.fromJson(Map<String, dynamic> json) {
    return UserPhoneNumber(
      id: json['id'],
      userId: json['user_id'],
      phoneNumber: json['phone_number'],
      isPrimary: json['is_primary'],
      description: json['description'],
    );
  }
}

