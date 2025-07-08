// lib/config/config.dart
import '../env/env.dart';

class Config {
  static const String baseUrl = Env.baseUrl;
  static const String httpUrl = Env.httpUrl; // Needed for full image URLs etc.
  static const String storageUrl = Env.storage; // Needed for storage paths
  static const String appToken = Env.appToken; // Use if your API specifically checks this header

  static Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    // Add app_token if your API requires it for public routes
    // "app_token": appToken,
    // You might also add language headers here if your API supports it
    // "Accept-Language": "ar", // or "en"
  };
}