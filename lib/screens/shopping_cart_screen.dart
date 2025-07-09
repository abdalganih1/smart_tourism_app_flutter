import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourism_app/models/shopping_cart_item.dart';
import 'package:smart_tourism_app/repositories/shopping_cart_repository.dart';
import 'package:smart_tourism_app/widgets/cart_item_widget.dart';

class ShoppingCartScreen extends StatefulWidget {
  static const routeName = '/cart';

  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  late Future<List<ShoppingCartItem>> _cartItemsFuture;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  void _loadCartItems() {
    final cartRepo = Provider.of<ShoppingCartRepository>(context, listen: false);
    setState(() {
      _cartItemsFuture = cartRepo.getMyCartItems();
    });
  }

  void _updateItemQuantity(int cartItemId, int newQuantity) async {
    try {
      final cartRepo = Provider.of<ShoppingCartRepository>(context, listen: false);
      await cartRepo.updateCartItemQuantity(cartItemId, newQuantity);
      _loadCartItems(); // Refresh the cart
    } catch (e) {
      _showErrorSnackBar('Failed to update quantity: ${e.toString()}');
    }
  }

  void _removeItem(int cartItemId) async {
    try {
      final cartRepo = Provider.of<ShoppingCartRepository>(context, listen: false);
      await cartRepo.removeCartItem(cartItemId);
      _loadCartItems(); // Refresh the cart
    } catch (e) {
      _showErrorSnackBar('Failed to remove item: ${e.toString()}');
    }
  }

  void _clearCart() async {
    try {
      final cartRepo = Provider.of<ShoppingCartRepository>(context, listen: false);
      await cartRepo.clearMyCart();
      _loadCartItems(); // Refresh the cart
    } catch (e) {
      _showErrorSnackBar('Failed to clear cart: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  double _calculateTotalPrice(List<ShoppingCartItem> items) {
    return items.fold(0.0, (sum, item) {
      final price = item.product?.price ?? 0.0;
      return sum + (price * item.quantity!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              // Show confirmation dialog before clearing
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Cart?'),
                  content: const Text('Are you sure you want to remove all items from your cart?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text('Clear'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _clearCart();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ShoppingCartItem>>(
        future: _cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty.', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!;
          final totalPrice = _calculateTotalPrice(cartItems);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (ctx, i) => CartItemWidget(
                    cartItem: cartItems[i],
                    onQuantityChanged: (newQuantity) {
                      _updateItemQuantity(cartItems[i].id, newQuantity);
                    },
                    onRemove: () {
                      _removeItem(cartItems[i].id);
                    },
                  ),
                ),
              ),
              _buildTotalSection(totalPrice),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalSection(double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to checkout screen
              },
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }
}
