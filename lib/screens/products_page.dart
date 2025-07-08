// lib/screens/products_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/screens/product_details_page.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/product.dart';
import 'package:smart_tourism_app/models/product_category.dart';
import 'package:smart_tourism_app/models/pagination.dart';

// تأكد من أن هذه الألوان معرفة ومتاحة (يفضل استيرادها من ملف ثوابت مشترك)
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kDividerColor = Color(0xFFEAEAEA);
const Color kSuccessColor = Color(0xFF2ECC71);
const Color kErrorColor = Color(0xFFE74C3C);

class ProductsPage extends StatefulWidget {
  // يمكن أن تستقبل ProductsPage categoryId افتراضي للفلترة المسبقة
  final int? initialCategoryId;
  final String? initialSearchQuery;

  const ProductsPage({super.key, this.initialCategoryId, this.initialSearchQuery});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final List<Product> _products = [];
  List<ProductCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();

  int? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _searchController.text = widget.initialSearchQuery ?? '';
    _currentSearchQuery = widget.initialSearchQuery ?? '';

    _fetchCategories(); // Fetch categories first
    _fetchProducts(isRefresh: true); // Then fetch products
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _canLoadMore && !_isLoading) {
      _currentPage++;
      _fetchProducts(page: _currentPage);
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      // Don't set _isLoading here, as it's primarily for products loading
      _errorMessage = null; // Clear error for categories specifically
    });
    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      _categories = await tourismRepo.getProductCategories();
      // Add an "All Categories" option at the beginning
      _categories.insert(0, ProductCategory(id: 0, name: 'جميع الفئات', description: null, parentCategoryId: null));
    } on ApiException catch (e) {
      print('API Error fetching categories: ${e.statusCode} - ${e.message}');
      setState(() {
        _errorMessage = 'خطأ في جلب الفئات: ${e.message}';
      });
    } on NetworkException catch (e) {
      print('Network Error fetching categories: ${e.message}');
      setState(() {
        _errorMessage = 'خطأ في الشبكة (فئات): ${e.message}';
      });
    } catch (e) {
      print('Unexpected Error fetching categories: ${e.toString()}');
      setState(() {
        _errorMessage = 'فشل في تحميل الفئات.';
      });
    } finally {
      setState(() {
        // Categories loading state is usually independent or part of overall products loading
      });
    }
  }

  Future<void> _fetchProducts({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _products.clear();
      _canLoadMore = true;
    }

    if (!_canLoadMore && !isRefresh) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) _errorMessage = null;
    });

    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      final response = await tourismRepo.getProducts(
        page: _currentPage,
        categoryId: _selectedCategoryId == 0 ? null : _selectedCategoryId, // 0 means all categories
        query: _currentSearchQuery.isEmpty ? null : _currentSearchQuery,
      );

      setState(() {
        _products.addAll(response.data);
        _canLoadMore = response.meta.currentPage < response.meta.lastPage;
      });
    } on ApiException catch (e) {
      print('API Error fetching products: ${e.statusCode} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      print('Network Error fetching products: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('Unexpected Error fetching products: ${e.toString()}');
      setState(() {
        _errorMessage = 'فشل في تحميل المنتجات.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    // This method is called when search or category changes
    _fetchProducts(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('منتجات يدوية'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search and Filter Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن منتج...',
                        prefixIcon: const Icon(Icons.search_outlined),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _currentSearchQuery = '';
                                  });
                                  _applyFilters();
                                },
                              )
                            : null,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      onSubmitted: (value) {
                        setState(() {
                          _currentSearchQuery = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category Filter Button/Dropdown
                  _categories.isEmpty && _isLoading
                      ? const SizedBox(
                          width: 48, height: 48,
                          child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 2),
                        )
                      : (_categories.isEmpty && !_isLoading)
                          ? const IconButton(
                              onPressed: null,
                              icon: Icon(Icons.filter_list_off, color: kSecondaryTextColor),
                              tooltip: 'لا توجد فئات',
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedCategoryId ?? _categories.first.id, // Default to 'All Categories'
                                icon: const Icon(Icons.filter_list_outlined, color: kPrimaryColor, size: 28),
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedCategoryId = newValue;
                                    });
                                    _applyFilters();
                                  }
                                },
                                items: _categories.map<DropdownMenuItem<int>>((ProductCategory category) {
                                  return DropdownMenuItem<int>(
                                    value: category.id,
                                    child: Text(category.name, style: textTheme.bodyLarge?.copyWith(color: kTextColor)),
                                  );
                                }).toList(),
                                dropdownColor: kSurfaceColor, // Background for dropdown menu
                              ),
                            ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _fetchProducts(isRefresh: true),
                color: kPrimaryColor,
                backgroundColor: Colors.white,
                child: _isLoading && _products.isEmpty && _errorMessage == null
                    ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 60, color: kErrorColor),
                                  const SizedBox(height: 15),
                                  Text(_errorMessage!, textAlign: TextAlign.center, style: textTheme.titleMedium?.copyWith(color: kErrorColor)),
                                  const SizedBox(height: 20),
                                  ElevatedButton(onPressed: () => _fetchProducts(isRefresh: true), child: const Text('إعادة المحاولة')),
                                ],
                              ),
                            ),
                          )
                        : _products.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(30.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.category_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                                      const SizedBox(height: 20),
                                      Text(
                                        'لا توجد منتجات مطابقة للبحث أو الفلتر.',
                                        style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'حاول تغيير الفلاتر أو البحث بكلمات مفتاحية مختلفة.',
                                        style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GridView.builder( // Using GridView for a better product display
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16.0),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, // Two items per row
                                    crossAxisSpacing: 16.0,
                                    mainAxisSpacing: 16.0,
                                    childAspectRatio: 0.7, // Adjust as needed
                                ),
                                itemCount: _products.length + (_canLoadMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index < _products.length) {
                                    final product = _products[index];
                                    return _buildProductCard(context, product);
                                  } else {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                                    );
                                  }
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Product Card Widget (for GridView) ---
 // --- Product Card Widget (for GridView) ---
Widget _buildProductCard(BuildContext context, Product product) {
  final textTheme = Theme.of(context).textTheme;

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 4,
    child: InkWell(
      onTap: () {
        // THE FIX: Navigate to Product Details Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(productId: product.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: product.mainImageUrl != null && product.mainImageUrl!.isNotEmpty
                ? Image.network(
                    product.mainImageUrl!,
                    height: 150, // Fixed height for image
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150, width: double.infinity, color: kSurfaceColor,
                      child: const Icon(Icons.image_not_supported, color: kSecondaryTextColor, size: 50),
                    ),
                  )
                : Container(
                    height: 150, width: double.infinity, color: kSurfaceColor,
                    child: const Icon(Icons.photo_outlined, color: kSecondaryTextColor, size: 50),
                  ),
          ),
          Expanded( // Use Expanded to handle overflow
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
                children: [
                  // Product Name
                  Text(
                    product.name, // Now safe because it's non-nullable
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Product Price
                  Text(
                    product.price != null
                        ? '${product.price!.toStringAsFixed(2)} SYP'
                        : 'السعر غير محدد',
                    style: textTheme.titleLarge?.copyWith(color: kAccentColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}