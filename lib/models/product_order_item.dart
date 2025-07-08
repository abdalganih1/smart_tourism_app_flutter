// lib/models/product_order_item.dart
import 'package:smart_tourism_app/models/product.dart'; // Ensure Product model is correctly imported

class ProductOrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double? priceAtPurchase; // <-- يمكن أن يكون String من API، اجعله double?
  final Product? product; // Nullable if not always included

  ProductOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    this.priceAtPurchase, // Nullable
    this.product,
  });

  factory ProductOrderItem.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ProductOrderItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      productId: json['product_id'] as int,
      quantity: json['quantity'] as int,
      priceAtPurchase: parseDouble(json['price_at_purchase']), // Use safe parsing
      product: json['product'] != null ? Product.fromJson(json['product'] as Map<String, dynamic>) : null,
    );
  }
}