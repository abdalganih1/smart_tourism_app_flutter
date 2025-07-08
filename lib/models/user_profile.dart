// lib/models/user_profile.dart
import 'package:smart_tourism_app/config/config.dart';

class UserProfile {
  final int? id;
  final int userId;
  final String? firstName;
  final String? lastName;
  final String? fatherName;
  final String? motherName;
  final String? passportImageUrl;
  final String? bio;
  final String? profilePictureUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.fatherName,
    this.motherName,
    this.passportImageUrl,
    this.bio,
    this.profilePictureUrl,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName {
    // If both names are null, return empty string or "User"
    if (firstName == null && lastName == null) return '';
    // If one is null, return the other
    if (firstName == null) return lastName!;
    if (lastName == null) return firstName!;
    // Both are present
    return '$firstName $lastName';
  }

  String? get imageUrl {
    if (profilePictureUrl == null || profilePictureUrl!.isEmpty) return null;
    if (profilePictureUrl!.startsWith('http://') || profilePictureUrl!.startsWith('https://')) {
      return profilePictureUrl;
    }
    // Handle cases where API returns /storage/path/to/file.jpg
    if (profilePictureUrl!.startsWith('/')) {
       return Config.httpUrl + profilePictureUrl!;
    }
    // Assume it's a file name under /storage
    return '${Config.httpUrl}/storage/$profilePictureUrl';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Helper for safe integer parsing (from int, double, or string)
    int? safeParseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return UserProfile(
      id: safeParseInt(json['id']), // Use safeParseInt
      userId: safeParseInt(json['user_id']) ?? 0, // Use safeParseInt, default to 0 if null
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      passportImageUrl: json['passport_image_url'] as String?,
      bio: json['bio'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}