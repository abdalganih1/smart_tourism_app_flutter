// lib/repositories/shopping_cart_repository.dart
import 'dart:async';
import '../models/shopping_cart_item.dart';
import '../services/api_service.dart';

class ShoppingCartRepository {
  final ApiService _apiService;

  ShoppingCartRepository(this._apiService);

  Future<List<ShoppingCartItem>> getMyCartItems() async {
    final response = await _apiService.get('/cart', protected: true); // Protected endpoint
    return (response as List).map((item) => ShoppingCartItem.fromJson(item)).toList();
  }

  Future<ShoppingCartItem> addItemToCart(int productId, int quantity) async {
     // API endpoint /cart/add expects product_id and quantity
    final response = await _apiService.post('/cart/add', {'product_id': productId, 'quantity': quantity}, protected: true); // Protected endpoint
    return ShoppingCartItem.fromJson(response);
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