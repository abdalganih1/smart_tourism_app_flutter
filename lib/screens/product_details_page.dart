// lib/screens/product_details_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourism_app/main.dart';

import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/repositories/shopping_cart_repository.dart'; // <-- Import cart repo
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/product.dart';

// Use your app's constant colors
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kErrorColor = Color(0xFFE74C3C);
const Color kSuccessColor = Color(0xFF2ECC71);

class ProductDetailsPage extends StatefulWidget {
  final int productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Product? _product;
  bool _isLoading = false;
  String? _errorMessage;
  int _quantity = 1;
  bool _isAddingToCart = false; // <-- State for add to cart button

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      final product = await tourismRepo.getProductDetails(widget.productId);
      setState(() {
        _product = product;
      });
    } on ApiException catch (e) {
      setState(() { _errorMessage = e.message; });
    } on NetworkException catch (e) {
      setState(() { _errorMessage = e.message; });
    } catch (e) {
      setState(() { _errorMessage = 'فشل في تحميل تفاصيل المنتج.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _incrementQuantity() {
    if (_product != null && _quantity < (_product!.stockQuantity ?? 10)) {
      setState(() { _quantity++; });
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() { _quantity--; });
    }
  }

  Future<void> _addToCart() async {
    if (_product == null) return;

    setState(() { _isAddingToCart = true; });

    try {
      final cartRepo = Provider.of<ShoppingCartRepository>(context, listen: false);
      await cartRepo.addItemToCart(_product!.id, _quantity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة $_quantity من "${_product!.name}" إلى السلة.'),
            backgroundColor: kSuccessColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إضافة المنتج: ${e.toString()}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isAddingToCart = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_product?.name ?? 'تفاصيل المنتج'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: _isLoading && _product == null
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _errorMessage != null
                ? _buildErrorWidget(textTheme)
                : _product == null
                    ? _buildErrorWidget(textTheme, message: 'لم يتم العثور على المنتج.')
                    : _buildProductContent(textTheme),
        bottomNavigationBar: _product != null ? _buildBottomBar(textTheme) : null,
      ),
    );
  }

  Widget _buildProductContent(TextTheme textTheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Product Image
          Image.network(
            _product!.mainImageUrl ?? 'https://via.placeholder.com/600x400?text=Product+Image',
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 300, color: kSurfaceColor,
              child: const Icon(Icons.broken_image, size: 80, color: kSecondaryTextColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category and Seller
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _product!.category?.name ?? 'فئة غير محددة',
                      style: textTheme.bodyLarge?.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                    ),
                    if (_product!.seller != null)
                      Text(
                        'البائع: ${_product!.seller!.username}',
                        style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Product Name
                Text(
                  _product!.name,
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                ),
                const SizedBox(height: 12),
                // Price
                Text(
                  _product!.price != null
                      ? '${_product!.price!.toStringAsFixed(2)} SYP'
                      : 'السعر غير محدد',
                  style: textTheme.headlineSmall?.copyWith(color: kAccentColor, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 32, thickness: 0.5),
                // Description
                Text('الوصف', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  _product!.description ?? 'لا يوجد وصف متاح لهذا المنتج.',
                  style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 24),
                // Quantity Selector
                if (_product!.isAvailable)
                  _buildQuantitySelector(textTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(TextTheme textTheme) {
    return Row(
      children: [
        Text('الكمية:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kDividerColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.remove, color: kTextColor), onPressed: _decrementQuantity),
              Text('$_quantity', style: textTheme.titleMedium),
              IconButton(icon: const Icon(Icons.add, color: kTextColor), onPressed: _incrementQuantity),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'متاح: ${_product!.stockQuantity ?? 'غير محدود'}',
          style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor),
        ),
      ],
    );
  }

  Widget _buildBottomBar(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _product!.isAvailable && !_isAddingToCart ? _addToCart : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isAddingToCart
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _product!.isAvailable ? 'أضف إلى السلة' : 'غير متوفر حالياً',
                style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildErrorWidget(TextTheme textTheme, {String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: kErrorColor),
            const SizedBox(height: 15),
            Text(
              message ?? _errorMessage ?? 'حدث خطأ غير متوقع.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: kErrorColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _fetchProductDetails, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
