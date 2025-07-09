import 'package:flutter/material.dart';
import 'package:smart_tourism_app/models/shopping_cart_item.dart';

class CartItemWidget extends StatelessWidget {
  final ShoppingCartItem cartItem;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.cartItem,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Provide default values for potentially null product data
    final productName = cartItem.product?.name ?? 'Unnamed Product';
    final productPrice = cartItem.product?.price ?? 0.0;
    final imageUrl = cartItem.product?.mainImageUrl ?? 'https://via.placeholder.com/150';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: Image.network(
            imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.broken_image, size: 50),
          ),
          title: Text(productName),
          subtitle: Text('\${productPrice.toStringAsFixed(2)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: cartItem.quantity! > 1 ? () => onQuantityChanged(cartItem.quantity! - 1) : null,
              ),
              Text(cartItem.quantity.toString()),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => onQuantityChanged(cartItem.quantity! + 1),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
