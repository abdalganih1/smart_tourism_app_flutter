// lib/repositories/shopping_cart_repository.dart
import 'dart:async';
import '../models/shopping_cart_item.dart';
import '../services/api_service.dart';

class ShoppingCartRepository {
  final ApiService _apiService;

  ShoppingCartRepository(this._apiService);

  Future<List<ShoppingCartItem>> getMyCartItems() async {
    final response = await _apiService.get('/cart', protected: true); // Protected endpoint
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      final data = response['data'] as List;
      return data.map((item) => ShoppingCartItem.fromJson(item)).toList();
    } else {
      // Handle cases where the response is not in the expected format
      throw Exception('Invalid response format for cart items.');
    }
  }

  Future<ShoppingCartItem> addItemToCart(int productId, int quantity) async {
    // API endpoint /cart/add expects product_id and quantity
    // Let's send data as String values to be safe for form-urlencoded content type
    final body = {
      'product_id': productId.toString(),
      'quantity': quantity.toString(),
    };
    final response = await _apiService.post('/cart/add', body, protected: true); // Protected endpoint
    
    // The response from a successful add might be the new item or a success message.
    // Assuming it returns the newly created cart item.
    if (response is Map<String, dynamic>) {
      // If the new item is nested under a 'data' key
      if (response.containsKey('data')) {
        return ShoppingCartItem.fromJson(response['data']);
      }
      return ShoppingCartItem.fromJson(response);
    }
    throw Exception('Failed to parse response after adding item to cart.');
  }

  Future<ShoppingCartItem> updateCartItemQuantity(int cartItemId, int quantity) async {
    // API endpoint /cart/{cartItem} (PUT) expects quantity
    final response = await _apiService.put('/cart/$cartItemId', {'quantity': quantity}, protected: true); // Protected endpoint
    return ShoppingCartItem.fromJson(response);
  }

  Future<void> removeCartItem(int cartItemId) async {
    // API endpoint /cart/{cartItem} (DELETE)
    await _apiService.delete('/cart/$cartItemId', protected: true); // Protected endpoint (returns 204 No Content)
  }

  Future<void> clearMyCart() async {
    // API endpoint /cart/clear (POST)
    await _apiService.post('/cart/clear', {}, protected: true); // Protected endpoint
  }
}