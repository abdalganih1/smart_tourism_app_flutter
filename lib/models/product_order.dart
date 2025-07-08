// lib/models/product_order.dart
import 'package:smart_tourism_app/models/product_order_item.dart';
import 'package:smart_tourism_app/models/user.dart'; // Make sure User model is correctly imported

class ProductOrder {
  final int id;
  final int userId;
  final DateTime orderDate;
  final double? totalAmount; // <-- يمكن أن يكون String من API، اجعله double?
  final String orderStatus;
  final String? shippingAddressLine1;
  final String? shippingAddressLine2;
  final String? shippingCity;
  final String? shippingPostalCode;
  final String? shippingCountry;
  final String? paymentTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user; // Nullable if not always included
  final List<ProductOrderItem>? items; // Nullable if not always included

  ProductOrder({
    required this.id,
    required this.userId,
    required this.orderDate,
    this.totalAmount, // Nullable
    required this.orderStatus,
    this.shippingAddressLine1,
    this.shippingAddressLine2,
    this.shippingCity,
    this.shippingPostalCode,
    this.shippingCountry,
    this.paymentTransactionId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.items,
  });

  factory ProductOrder.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ProductOrder(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      orderDate: DateTime.parse(json['order_date']),
      totalAmount: parseDouble(json['total_amount']), // Use safe parsing
      orderStatus: json['order_status'] as String,
      shippingAddressLine1: json['shipping_address_line1'] as String?,
      shippingAddressLine2: json['shipping_address_line2'] as String?,
      shippingCity: json['shipping_city'] as String?,
      shippingPostalCode: json['shipping_postal_code'] as String?,
      shippingCountry: json['shipping_country'] as String?,
      paymentTransactionId: json['payment_transaction_id'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((itemJson) => ProductOrderItem.fromJson(itemJson as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}