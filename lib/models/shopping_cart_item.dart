// lib/models/shopping_cart_item.dart
// Place in lib/models/shopping_cart_item.dart
import 'product.dart';
import 'user.dart';

class ShoppingCartItem {
  final int id; // <--- يمكن تركه int (غير قابل للـ null)
  final int? userId; // <<< FIX: Made nullable
  final int? productId; // <<< FIX: Made nullable
  final int? quantity; // <<< FIX: Made nullable
  final DateTime? addedAt; // <<< FIX: Made nullable
  // Relations
  final User? user;
  final Product? product;

  ShoppingCartItem({
    required this.id, // لا يزال مطلوباً في الكونستركتور
    this.userId, // لم يعد مطلوباً في الكونستركتور
    this.productId, // لم يعد مطلوباً في الكونستركتور
    this.quantity, // لم يعد مطلوباً في الكونستركتور
    this.addedAt, // لم يعد مطلوباً في الكونستركتور
    this.user,
    this.product,
  });

  factory ShoppingCartItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    return ShoppingCartItem(
      // <<< FIX: Use null-aware cast and provide a default value (e.g., 0)
      id: json['id'] as int? ?? 0, // إذا كان json['id'] هو null، فسيتم تعيين 0
      userId: json['user_id'] as int?, // <<< FIX: Read as nullable int
      productId: json['product_id'] as int?, // <<< FIX: Read as nullable int
      quantity: json['quantity'] as int?, // <<< FIX: Read as nullable int
      addedAt: parseDate(
        json['added_at'] as String?,
      ), // <<< FIX: Use safe date parsing
      // Handle nullable relations
      user:
          json['user'] != null
              ? User.fromJson(json['user'] as Map<String, dynamic>)
              : null,
      product:
          json['product'] != null
              ? Product.fromJson(json['product'] as Map<String, dynamic>)
              : null,
    );
  }
}
