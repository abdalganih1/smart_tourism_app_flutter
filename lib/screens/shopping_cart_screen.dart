import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _loadSavedAddress();
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _addressLine1Controller.text = prefs.getString('shipping_address_line1') ?? '';
      _addressLine2Controller.text = prefs.getString('shipping_address_line2') ?? '';
      _cityController.text = prefs.getString('shipping_city') ?? '';
      _countryController.text = prefs.getString('shipping_country') ?? '';
    });
  }

  Future<void> _saveAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shipping_address_line1', _addressLine1Controller.text);
    await prefs.setString('shipping_address_line2', _addressLine2Controller.text);
    await prefs.setString('shipping_city', _cityController.text);
    await prefs.setString('shipping_country', _countryController.text);
  }

  void _loadCartItems() {
    final cartRepo = Provider.of<ShoppingCartRepository>(context, listen: false);
    setState(() {
      _cartItemsFuture = cartRepo.getMyCartItems();
    });
  }

  void _updateItemQuantity(int cartItemId, int newQuantity) async {
    try {
      final cartRepo =
          Provider.of<ShoppingCartRepository>(context, listen: false);
      await cartRepo.updateCartItemQuantity(cartItemId, newQuantity);
      _loadCartItems(); // Refresh the cart
    } catch (e) {
      _showErrorSnackBar('فشل تحديث الكمية: ${e.toString()}');
    }
  }

  void _removeItem(int cartItemId) async {
    try {
      final cartRepo =
          Provider.of<ShoppingCartRepository>(context, listen: false);
      await cartRepo.removeCartItem(cartItemId);
      _loadCartItems(); // Refresh the cart
    } catch (e) {
      _showErrorSnackBar('فشل إزالة العنصر: ${e.toString()}');
    }
  }

  void _clearCart() async {
    try {
      final cartRepo =
          Provider.of<ShoppingCartRepository>(context, listen: false);
      await cartRepo.clearMyCart();
      _loadCartItems(); // Refresh the cart
    } catch (e) {
      _showErrorSnackBar('فشل تفريغ السلة: ${e.toString()}');
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Save address for next time
    await _saveAddress();

    final shippingAddress = {
      'shipping_address_line1': _addressLine1Controller.text,
      'shipping_address_line2': _addressLine2Controller.text,
      'shipping_city': _cityController.text,
      'shipping_country': _countryController.text,
      'shipping_postal_code': '12341', // Hardcoded postal code
    };

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final cartRepo =
          Provider.of<ShoppingCartRepository>(context, listen: false);
      await cartRepo.placeOrder(shippingAddress);

      Navigator.of(context).pop(); // Close loading indicator
      Navigator.of(context).pop(); // Close checkout dialog

      _showSuccessSnackBar('تم إرسال الطلب بنجاح!');
      _loadCartItems(); // Refresh cart, which should be empty now
    } catch (e) {
      Navigator.of(context).pop(); // Close loading indicator
      _showErrorSnackBar('فشل إرسال الطلب: ${e.toString()}');
    }
  }

  void _showCheckoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('عنوان الشحن'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _addressLine1Controller,
                  decoration:
                      const InputDecoration(labelText: 'العنوان الأول'),
                  // Validator is removed to make it optional
                ),
                TextFormField(
                  controller: _addressLine2Controller,
                  decoration:
                      const InputDecoration(labelText: 'العنوان الثاني (اختياري)'),
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'المدينة'),
                   // Validator is removed to make it optional
                ),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'البلد'),
                   // Validator is removed to make it optional
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            onPressed: _placeOrder,
            child: const Text('إتمام الطلب'),
          ),
        ],
      ),
    );
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

    void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
        title: const Text('سلة التسوق'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'تفريغ السلة',
            onPressed: () {
              // Show confirmation dialog before clearing
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('تفريغ السلة؟'),
                  content: const Text(
                      'هل أنت متأكد أنك تريد إزالة جميع العناصر من سلتك؟'),
                  actions: [
                    TextButton(
                      child: const Text('إلغاء'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text('تفريغ'),
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
            return Center(child: Text('خطأ: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('سلتك فارغة.', style: TextStyle(fontSize: 18)),
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
              if (cartItems.isNotEmpty) _buildTotalSection(totalPrice),
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
              const Text('الإجمالي:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(
                '${totalPrice.toStringAsFixed(2)} ل.س',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showCheckoutDialog,
              child: const Text('المتابعة لإتمام الشراء'),
            ),
          ),
        ],
      ),
    );
  }
}