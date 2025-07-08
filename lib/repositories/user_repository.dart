// lib/repositories/user_repository.dart
import 'dart:async';
import 'package:smart_tourism_app/models/user_phone_number.dart';
import '../models/user.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http; // Required for MultipartFile
import 'dart:io'; // Required for File
import '../utils/api_exceptions.dart'; // تأكد من هذا الاستيراد

class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  // Get authenticated user's full profile (user + profile)
  // Calls GET /api/profile
  Future<User> getMyFullProfile() async { 
    final response = await _apiService.get('/profile', protected: true);
    // UserResource in Laravel wraps data in a "data" key.
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return User.fromJson(response['data'] as Map<String, dynamic>);
    } else {
      throw FormatException('Expected user profile data to be wrapped in "data" key.');
    }
  }

  // Update authenticated user's textual profile information
  // Calls PUT /api/profile
  Future<User> updateMyProfile(Map<String, dynamic> profileData) async {
    final response = await _apiService.put('/profile', profileData, protected: true);
     
    // Assuming API returns the updated User object on success, wrapped in 'data'
    if (response is Map<String, dynamic> && response.containsKey('data')) {
       return User.fromJson(response['data'] as Map<String, dynamic>);
    } else {
       throw FormatException('Expected updated user data to be wrapped in "data" key.');
    }
  }

  // Upload a new profile picture.
  // Calls POST /api/profile/picture
  Future<Map<String, dynamic>> updateProfilePicture(File profilePicture) async {
    final response = await _apiService.postMultipart(
       '/profile/picture', // API endpoint for updating profile picture
       {}, // No additional fields are needed, only the file
       file: http.MultipartFile.fromBytes(
         'profile_picture', // Field name for file upload matching Laravel request
         profilePicture.readAsBytesSync(),
         filename: profilePicture.path.split('/').last,
       ),
       protected: true,
    );
    // The API returns a JSON object with 'message' and 'profile_picture_url'
    return response as Map<String, dynamic>;
  }

  // Remove the current profile picture.
  // Calls DELETE /api/profile/picture
  Future<void> removeProfilePicture() async {
    await _apiService.delete('/profile/picture', protected: true);
  }

  // Update the user's password
  // Calls PUT /api/profile/password
  Future<void> updatePassword(String currentPassword, String newPassword, String newPasswordConfirmation) async {
    try {
      await _apiService.put(
        '/profile/password',
        {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPasswordConfirmation,
        },
        protected: true,
      );
      // Success is indicated by 200 or 204 status code, handled by ApiService.
    } on ApiException catch (e) {
      throw e;
    } catch (e) {
      throw NetworkException("Failed to connect to server to update password: ${e.toString()}");
    }
  }

   // Fetch user's phone numbers (if needed separately)
   Future<List<UserPhoneNumber>> getMyPhoneNumbers() async {
      // Assuming an endpoint like /profile/phone-numbers returns a list directly or wrapped in 'data'
      final response = await _apiService.get('/profile/phone-numbers', protected: true);
      if (response is List) {
          return response.map((item) => UserPhoneNumber.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response is Map<String, dynamic> && response.containsKey('data')) {
          return (response['data'] as List).map((item) => UserPhoneNumber.fromJson(item as Map<String, dynamic>)).toList();
      }
      else {
          throw FormatException('Expected a list of phone numbers, but received: $response');
      }
   }
}