// lib/screens/favorites_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourism_app/repositories/interaction_repository.dart'; // Make sure this is imported
import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/favorite.dart';
import 'package:smart_tourism_app/models/pagination.dart';
import 'package:smart_tourism_app/models/tourist_site.dart'; // For type checking
import 'package:smart_tourism_app/models/product.dart'; // For type checking
import 'package:smart_tourism_app/models/article.dart'; // For type checking
import 'package:smart_tourism_app/models/hotel.dart'; // For type checking
import 'package:smart_tourism_app/models/site_experience.dart'; // For type checking

// تأكد من أن هذه الألوان معرفة ومتاحة، يفضل أن تكون في ملف ثوابت مشترك
// مثال: lib/constants/app_colors.dart
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kDividerColor = Color(0xFFEAEAEA);
const Color kSuccessColor = Color(0xFF2ECC71);
const Color kErrorColor = Color(0xFFE74C3C);

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  PaginatedResponse<Favorite>? _favoritesResponse;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchFavorites(isRefresh: true); // اجلب البيانات الأولى عند التهيئة
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _canLoadMore && !_isLoading) {
      _currentPage++;
      _fetchFavorites(page: _currentPage);
    }
  }

  Future<void> _fetchFavorites({int page = 1, bool isRefresh = false}) async {
    // Return early if no more data can be loaded and it's not a refresh of the first page
    if (!isRefresh && !_canLoadMore && page != 1) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _errorMessage = null; // Clear previous errors on refresh
        _favoritesResponse = null; // Clear existing data to show fresh results
        _currentPage = 1; // Reset current page for a new fetch
      }
    });

    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      final newResponse = await tourismRepo.getMyFavorites(page: page); // Use the provided page number

      // Ensure the widget is still mounted before updating state
      if (mounted) {
        setState(() {
          if (isRefresh || _favoritesResponse == null) {
            // For first load or refresh, just set the new response
            _favoritesResponse = newResponse;
          } else {
            // For loading more, append new data and create a new PaginatedResponse
            // This is crucial because PaginatedResponse fields are final.
            _favoritesResponse!.data.addAll(newResponse.data);
            _favoritesResponse = PaginatedResponse<Favorite>(
              data: _favoritesResponse!.data, // Use the updated data list
              meta: newResponse.meta,       // Take the meta from the latest response
              extra: newResponse.extra,      // Carry over any extra data
            );
          }
          // Determine if there are more pages to load
          _canLoadMore = newResponse.meta.currentPage < newResponse.meta.lastPage;
        });
      }
    } on ApiException catch (e) {
      print('API Error fetching favorites: ${e.statusCode} - ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _canLoadMore = false; // Stop trying to load more on API error
        });
      }
    } on NetworkException catch (e) {
      print('Network Error fetching favorites: ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _canLoadMore = false; // Stop trying to load more on network error
        });
      }
    } catch (e) {
      print('Unexpected Error fetching favorites: ${e.toString()}');
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحميل المفضلة: ${e.toString()}';
          _canLoadMore = false; // Stop trying to load more on unexpected error
        });
      }
    } finally {
      // Ensure loading state is false after operation completes
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFavorite(Favorite favoriteItem) async {
    setState(() {
      _isLoading = true; // Activate loading indicator for the removal process
    });
    try {
      // Use InteractionRepository for toggleFavorite
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      await interactionRepo.toggleFavorite( favoriteItem.targetType, favoriteItem.targetId);

      // After successful removal, refresh the list to reflect the change
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${getItemDisplayDetails(favoriteItem.target, favoriteItem.targetType).title} تم إزالته من المفضلة'),
            backgroundColor: kSuccessColor,
          ),
        );
        _fetchFavorites(isRefresh: true); // Re-fetch all favorites to update the list
      }
    } on ApiException catch (e) {
      print('API Error removing favorite: ${e.statusCode} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإزالة: ${e.message}'), backgroundColor: kErrorColor),
        );
      }
    } on NetworkException catch (e) {
      print('Network Error removing favorite: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإزالة (شبكة): ${e.message}'), backgroundColor: kErrorColor),
        );
      }
    } catch (e) {
      print('Unexpected Error removing favorite: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ غير متوقع أثناء الإزالة.'), backgroundColor: kErrorColor),
        );
      }
    } finally {
      // Deactivate loading indicator
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المفضلة'),
          centerTitle: true,
          backgroundColor: kBackgroundColor, // Use background color for consistent theme
          foregroundColor: kTextColor, // Text and icon color for AppBar
          elevation: 0, // Remove shadow
        ),
        body: _buildBodyContent(), // Delegating body content to a helper method
      ),
    );
  }

  // Helper to build the main body content based on state
  Widget _buildBodyContent() {
    // Show initial loading indicator
    if (_isLoading && (_favoritesResponse == null || _favoritesResponse!.data.isEmpty)) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    // Show error message if an error occurred
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: kErrorColor),
              const SizedBox(height: 15),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kErrorColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _fetchFavorites(isRefresh: true), // Retry fetching favorites
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    // Show empty state if no favorites are loaded
    if (_favoritesResponse == null || _favoritesResponse!.data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline_rounded, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
              const SizedBox(height: 20),
              Text(
                'قائمة المفضلة فارغة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                'أضف وجهات وجولات ومنتجات رائعة بالنقر على أيقونة القلب أو الحفظ لزيارتها لاحقاً.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
              ),
            ],
          ),
        ),
      );
    }

    // Display the list of favorite items
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      // Add 1 to itemCount if more data can be loaded to show a loading indicator at the bottom
      itemCount: _favoritesResponse!.data.length + (_canLoadMore && !_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _favoritesResponse!.data.length) {
          final favorite = _favoritesResponse!.data[index];
          return FavoriteItemCard(
            favoriteItem: favorite,
            onRemove: () => _removeFavorite(favorite),
          );
        } else {
          // Show circular progress indicator when loading more data
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
          );
        }
      },
    );
  }
}

// Helper class to encapsulate dynamic item details
// No underscore, so it's public (library-private if in same file)
class ItemDetails {
  final String title;
  final String? imageUrl;
  final String typeDisplay;
  final String? subtitle;

  ItemDetails({
    required this.title,
    this.imageUrl,
    required this.typeDisplay,
    this.subtitle,
  });
}

// Helper function to extract display details from polymorphic 'target'
// No underscore, so it's public (library-private if in same file)
ItemDetails getItemDisplayDetails(dynamic target, String targetType) {
  String title = 'غير معروف';
  String? imageUrl;
  String typeDisplay = 'غير معروف';
  String? subtitle;

  if (target == null) {
    return ItemDetails(title: 'عنصر محذوف/غير موجود', typeDisplay: 'غير معروف');
  }

  switch (targetType) {
    case 'TouristSite':
      final site = target as TouristSite;
      title = site.name ?? 'موقع سياحي غير معروف'; // FIX: Handle nullable name
      imageUrl = site.mainImageUrl;
      typeDisplay = 'موقع سياحي';
      subtitle = site.city != null && site.country != null
          ? '${site.city}, ${site.country}'
          : site.locationText;
      break;
    case 'Product':
      final product = target as Product;
      title = product.name ?? 'منتج غير معروف'; // FIX: Handle nullable name
      imageUrl = product.imageUrl; // Using the getter here
      typeDisplay = 'منتج';
      subtitle = 'السعر: ${product.price?.toStringAsFixed(2) ?? 'غير محدد'} SYP';
      break;
    case 'Article':
      final article = target as Article;
      title = article.title ?? 'مقالة غير معروفة'; // FIX: Handle nullable title
      imageUrl = article.imageUrl; // Using the getter here
      typeDisplay = 'مقالة';
      subtitle = article.excerpt;
      break;
    case 'Hotel':
      final hotel = target as Hotel;
      title = hotel.name ?? 'فندق غير معروف'; // FIX: Handle nullable name
      imageUrl = hotel.imageUrl; // Using the getter here
      typeDisplay = 'فندق';
      subtitle = hotel.city != null && hotel.country != null
          ? '${hotel.city}, ${hotel.country}'
          : hotel.addressLine1;
      break;
    case 'SiteExperience':
      final experience = target as SiteExperience;
      title = experience.title ?? 'تجربة في موقع سياحي';
      imageUrl = experience.photoUrl;
      typeDisplay = 'تجربة سياحية';
      subtitle = experience.site?.name != null
          ? 'في: ${experience.site!.name}'
          : null;
      break;
    default:
      title = 'عنصر مفضل';
      typeDisplay = 'غير معروف';
  }
  return ItemDetails(title: title, imageUrl: imageUrl, typeDisplay: typeDisplay, subtitle: subtitle);
}

// FavoriteItemCard StatelessWidget
// This class is already public as it doesn't start with an underscore.
class FavoriteItemCard extends StatelessWidget {
  final Favorite favoriteItem;
  final VoidCallback onRemove;

  const FavoriteItemCard({
    super.key,
    required this.favoriteItem,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Use the now public helper function
    final itemDetails = getItemDisplayDetails(favoriteItem.target, favoriteItem.targetType);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to the details page of the specific item type
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فتح تفاصيل: ${itemDetails.title}')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                itemDetails.imageUrl != null && itemDetails.imageUrl!.isNotEmpty
                    ? Image.network(
                        itemDetails.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 200,
                          color: kSurfaceColor,
                          child: const Center(child: Icon(Icons.broken_image_outlined, color: kSecondaryTextColor, size: 50)),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: kSurfaceColor,
                        child: const Center(child: Icon(Icons.image_not_supported, color: kSecondaryTextColor, size: 70)),
                      ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black.withOpacity(0.4),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                      onPressed: onRemove,
                      tooltip: 'إزالة من المفضلة',
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      itemDetails.typeDisplay,
                      style: textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
              child: Text(
                itemDetails.title,
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (itemDetails.subtitle != null && itemDetails.subtitle!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  itemDetails.subtitle!,
                  style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('عرض تفاصيل: ${itemDetails.title}')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    elevation: 2,
                  ),
                  child: Text(
                    'عرض التفاصيل',
                    style: textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}