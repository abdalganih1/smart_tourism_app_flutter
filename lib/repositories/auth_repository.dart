// lib/repositories/auth_repository.dart
import 'dart:async';
import 'package:smart_tourism_app/utils/api_exceptions.dart'; // تأكد من هذا الاستيراد

import '../models/user.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<User> login(String login, String password, {String? deviceName}) async {
    final response = await _apiService.post(
      '/login',
      {'login': login, 'password': password, 'device_name': deviceName},
      protected: false,
    );
    if (response is Map<String, dynamic> && response.containsKey('token') && response.containsKey('user')) {
      await _apiService.saveToken(response['token'] as String);
      return User.fromJson(response['user'] as Map<String, dynamic>);
    } else {
      // FIX: استخدام بناء ApiException الصحيح
      throw ApiException(400, 'Invalid login response format.');
    }
  }

  Future<User> register(Map<String, dynamic> userData) async {
    final response = await _apiService.post(
      '/register',
      userData,
      protected: false,
    );
    if (response is Map<String, dynamic> && response.containsKey('token') && response.containsKey('user')) {
      await _apiService.saveToken(response['token'] as String);
      return User.fromJson(response['user'] as Map<String, dynamic>);
    } else {
      // FIX: استخدام بناء ApiException الصحيح
      throw ApiException(400, 'Invalid registration response format.');
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/logout', {}, protected: true);
    } catch (e) {
      print('Logout API call failed: $e');
    } finally {
      await _apiService.removeToken();
    }
  }

  // This method should get the core user object, maybe without full relations.
  Future<User?> getAuthenticatedUser() async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        return null; // No token, no authenticated user
      }
      final response = await _apiService.get('/user', protected: true);
      
      // Based on your previous logs, /user wraps the object in a 'data' key
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        return User.fromJson(response['data'] as Map<String, dynamic>);
      }
      // It's also possible /user returns the user object directly (less common with resources)
      else if (response is Map<String, dynamic>) {
        return User.fromJson(response);
      }
      else {
        throw UnauthorizedException('Invalid user data format from /user endpoint.');
      }
    } catch (e) {
      if (e is UnauthorizedException) {
        await _apiService.removeToken();
        return null;
      }
      rethrow;
    }
  }

  // NOTE: changePassword function has been MOVED to UserRepository as per your Backend structure.
}