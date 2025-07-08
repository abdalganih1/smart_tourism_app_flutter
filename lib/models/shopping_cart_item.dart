// lib/models/shopping_cart_item.dart
// Place in lib/models/shopping_cart_item.dart
import 'product.dart';
import 'user.dart';

class ShoppingCartItem {
  final int id;
  final int userId;
  final int productId;
  final int quantity;
  final DateTime addedAt;
  // Relations
  final User? user;
  final Product? product;

  ShoppingCartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.addedAt,
    this.user,
    this.product,
  });

  factory ShoppingCartItem.fromJson(Map<String, dynamic> json) {
    return ShoppingCartItem(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      addedAt: DateTime.parse(json['added_at']),
      // Handle nullable relations
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
}