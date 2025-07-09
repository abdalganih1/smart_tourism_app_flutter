// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config.dart';
import '../utils/api_exceptions.dart'; // Import your custom exceptions

class ApiService {
  static const String _tokenKey = 'sanctum_token'; // Key for SharedPreferences

  // --- Token Management ---
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // --- Helper for Protected Headers ---
  Future<Map<String, String>> _getProtectedHeaders() async {
    final token = await getToken();
    if (token == null) {
      throw UnauthorizedException("Authentication token not found.");
    }
    return {
      ...Config.headers, // Include default headers
      "Authorization": "Bearer $token", // Add Authorization header
    };
  }

  // --- Request Execution Helper ---
  Future<dynamic> _handleResponse(http.Response response) {
    // حاول فك تشفير الجسم فقط إذا لم يكن 204 (No Content)
    // لتجنب خطأ فك التشفير لجسم فارغ
    dynamic responseBody;
    try {
      if (response.statusCode != 204 && response.bodyBytes.isNotEmpty) {
        responseBody = json.decode(response.body);
      }
    } catch (e) {
      // التعامل مع حالة عدم القدرة على فك تشفير JSON (مثلاً، استجابة HTML أو نص عادي)
      print('Warning: Could not decode JSON response body. Raw body: ${response.body}');
      // يمكنك هنا إما رمي خطأ أو التعامل معها كـ ServerErrorException
      throw ServerErrorException('Could not decode API response: ${response.body}');
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return Future.value(responseBody);
      case 204: // No Content
        return Future.value(null);
      case 400:
        throw BadRequestException(responseBody?['message'] ?? 'Bad Request');
      case 401:
        throw UnauthorizedException(responseBody?['message'] ?? 'Unauthorized', errors: responseBody?['errors']); // Sanctum returns errors key for failed login
      case 403:
        throw ForbiddenException(responseBody?['message'] ?? 'Forbidden');
      case 404:
        throw NotFoundException(responseBody?['message'] ?? 'Not Found');
      case 409:
        throw ConflictException(responseBody?['message'] ?? 'Conflict');
      case 422:
        throw ValidationException(responseBody?['message'] ?? 'Validation Failed', responseBody?['errors']);
      case 500:
      default:
        throw ServerErrorException(responseBody?['message'] ?? 'Server Error');
    }
  }

  // --- HTTP Methods ---

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, bool protected = false}) async {
    final uri = Uri.parse(Config.baseUrl + path).replace(queryParameters: queryParameters);
    final headers = protected ? await _getProtectedHeaders() : Config.headers;

    try {
      final response = await http.get(uri, headers: headers);
      // طباعة نص الاستجابة (JSON) بدلاً من الكائن نفسه
      print('GET $path | Status: ${response.statusCode} | Body: ${response.body}'); 
      return _handleResponse(response);
    } catch (e) {
      // Catch http package errors (e.g., no internet connection)
      throw NetworkException("Failed to connect to the server: ${e.toString()}");
    }
  }

  Future<dynamic> post(String path, dynamic body, {bool protected = false}) async {
    final uri = Uri.parse(Config.baseUrl + path);
    final headers = protected ? await _getProtectedHeaders() : Config.headers;

    // Modify headers for form-urlencoded content type
    headers['Content-Type'] = 'application/x-www-form-urlencoded';

    try {
      // The body should be a Map<String, String> for this content type
      final response = await http.post(
        uri,
        headers: headers,
        body: body, // Send body directly without json.encode
      );
      // طباعة نص الاستجابة (JSON)
      print('POST $path | Status: ${response.statusCode} | Body: ${response.body}');
      
      // Revert Content-Type to default for subsequent requests that might expect JSON
      headers['Content-Type'] = 'application/json'; 

      return _handleResponse(response);
    } catch (e) {
      // Revert Content-Type in case of error too
      headers['Content-Type'] = 'application/json';
      throw NetworkException("Failed to connect to the server: ${e.toString()}");
    }
  }

  Future<dynamic> put(String path, dynamic body, {bool protected = false}) async {
    final uri = Uri.parse(Config.baseUrl + path);
    final headers = protected ? await _getProtectedHeaders() : Config.headers;

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(body),
      );
      // طباعة نص الاستجابة (JSON)
      print('PUT $path | Status: ${response.statusCode} | Body: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      throw NetworkException("Failed to connect to the server: ${e.toString()}");
    }
  }

  Future<dynamic> delete(String path, {bool protected = false}) async {
     final uri = Uri.parse(Config.baseUrl + path);
     final headers = protected ? await _getProtectedHeaders() : Config.headers;

     try {
       final response = await http.delete(uri, headers: headers);
       // طباعة نص الاستجابة (JSON)
       print('DELETE $path | Status: ${response.statusCode} | Body: ${response.body}');
       return _handleResponse(response);
     } catch (e) {
       throw NetworkException("Failed to connect to the server: ${e.toString()}");
     }
   }

   // --- File Upload (Multipart Request) Example ---
   Future<dynamic> postMultipart(String path, Map<String, String> fields, {http.MultipartFile? file, bool protected = false}) async {
     final uri = Uri.parse(Config.baseUrl + path);
     final headers = protected ? await _getProtectedHeaders() : Config.headers;

     try {
       var request = http.MultipartRequest('POST', uri);

       request.fields.addAll(fields);
       if (file != null) {
         request.files.add(file);
       }
       request.headers.addAll(headers);

       final streamedResponse = await request.send();
       final response = await http.Response.fromStream(streamedResponse);

       // طباعة نص الاستجابة (JSON) لطلبات Multipart
       print('MULTIPART POST $path | Status: ${response.statusCode} | Body: ${response.body}');
       return _handleResponse(response);

     } catch (e) {
       throw NetworkException("Failed to upload file: ${e.toString()}");
     }
   }

   // Helper for PUT/PATCH with file upload (requires _method field)
   Future<dynamic> postMultipartForUpdate(String path, Map<String, String> fields, {http.MultipartFile? file, bool protected = false}) async {
      fields['_method'] = 'PUT'; // Or 'PATCH' depending on your API route
      return postMultipart(path, fields, file: file, protected: protected);
   }
}