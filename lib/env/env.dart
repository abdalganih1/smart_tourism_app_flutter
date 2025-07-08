// lib/env/env.dart
// This file should ideally NOT be committed to version control in a real project
// and sensitive data should be managed securely.
// For example purposes, hardcoded values are used.
class Env {
  // Replace with your actual API URL
  // Example for local development: const String baseUrl = "http://10.0.2.2:8000/api"; // Use 10.0.2.2 for Android emulator
  // const String httpUrl = "http://10.0.2.2:8000"; // For full URLs like /storage/...
  // const String storage = "http://10.0.2.2:8000/storage"; // For storage URLs

  // Example with the URL from your Hostinger site
  static const String baseUrl = "https://lightyellow-porcupine-230777.hostingersite.com/api";
  static const String httpUrl = "https://lightyellow-porcupine-230777.hostingersite.com";
  static const String storage = "https://lightyellow-porcupine-230777.hostingersite.com/public/storage";

  // App token from your Sanctum config (if used for specific API features beyond authentication)
  // Usually, this is not needed for Sanctum token authentication itself.
  static const String appToken = "NKY5vcXiv"; // Example, use if your API specifically checks this header

  static const String version = "1.0";
}