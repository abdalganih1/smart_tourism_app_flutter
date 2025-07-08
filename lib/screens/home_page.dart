import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'
    as intl; // لإدارة التواريخ - استخدام اسم مستعار لتجنب تضارب TextDirection
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // لتصنيف الفنادق

import 'package:smart_tourism_app/repositories/auth_repository.dart';
import 'package:smart_tourism_app/models/user.dart';

// استيراد الشاشات التي قد تنتقل إليها
import 'package:smart_tourism_app/screens/TouristSiteDetailsPage.dart'; // TouristSiteDetailsPage موجودة هنا
import 'package:smart_tourism_app/screens/HotelsPage.dart';
import 'package:smart_tourism_app/screens/hotel_details_page.dart';
import 'package:smart_tourism_app/screens/products_page.dart';
import 'package:smart_tourism_app/screens/product_details_page.dart';
import 'package:smart_tourism_app/screens/all_tourist_sites_page.dart'; // صفحة عرض جميع المواقع
import 'package:smart_tourism_app/screens/tourist_sites_list_page.dart'; // <-- استيراد صفحة قائمة المواقع السياحية

// استيراد المستودعات والموديلات
import '../repositories/tourism_repository.dart';
import '../repositories/interaction_repository.dart';
import '../repositories/hotel_repository.dart';
import '../utils/api_exceptions.dart';
import '../models/tourist_site.dart';
import '../models/hotel.dart';
import '../models/product.dart';
import '../models/pagination.dart';
import '../models/site_category.dart';
import '../utils/constants.dart'; // For TargetTypes

// تأكد من أن هذه الألوان معرفة ومتاحة (يفضل في ملف ثوابت مشترك)
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kDividerColor = Color(0xFFEAEAEA);
const Color kSuccessColor = Color(0xFF2ECC71);
const Color kErrorColor = Color(0xFFE74C3C);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String? _errorMessage;

  // Data for the sections
  List<TouristSite> _featuredDestinations = [];
  List<Hotel> _popularHotels = [];
  List<Product> _specialOffersProducts = [];
  List<SiteCategory> _siteCategories = [];

  // State for favorite buttons, fetched from API
  final Set<int> _favoriteDestinationIds = {};
  final Set<int> _favoriteHotelIds = {};

  @override
  void initState() {
    super.initState();
    _fetchAllHomePageData();
  }

  Future<void> _fetchAllHomePageData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tourismRepo = Provider.of<TourismRepository>(
        context,
        listen: false,
      );
      final interactionRepo = Provider.of<InteractionRepository>(
        context,
        listen: false,
      );
      final hotelRepo = Provider.of<HotelRepository>(
        context,
        listen: false,
      );

      // Fetch Tourist Sites (for Featured Destinations)
      final sitesResponse = await tourismRepo.getTouristSites(page: 1);
      _featuredDestinations =
          sitesResponse.data.where((site) => site != null).toList().cast<TouristSite>();

      // Fetch Hotels (for Popular Hotels)
      final hotelsResponse = await hotelRepo.getHotels(page: 1);
      _popularHotels = hotelsResponse.data.where((hotel) => hotel != null).toList().cast<Hotel>();

      // Fetch Products (for "Special Offers")
      final productsResponse = await tourismRepo.getProducts(page: 1);
      _specialOffersProducts =
          productsResponse.data.where((product) => product != null).toList().cast<Product>();

      // Fetch Site Categories
      _siteCategories = await tourismRepo.getSiteCategories();

      // Fetch user's current favorites for initial UI state
      await _fetchUserFavorites(interactionRepo);
    } on ApiException catch (e) {
      print('API Error: ${e.statusCode} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      print('Network Error: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('Unexpected Error: ${e.toString()}');
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch user's favorite IDs to correctly display favorite buttons
  Future<void> _fetchUserFavorites(
    InteractionRepository interactionRepo,
  ) async {
    try {
      final favoriteResponse = await interactionRepo.getMyFavorites(page: 1);
      setState(() {
        _favoriteDestinationIds.clear();
        _favoriteHotelIds.clear();
        for (var fav in favoriteResponse.data) {
          if (fav.targetType == TargetTypes.touristSite &&
              fav.targetId != null) {
            _favoriteDestinationIds.add(fav.targetId!);
          } else if (fav.targetType == TargetTypes.hotel &&
              fav.targetId != null) {
            _favoriteHotelIds.add(fav.targetId!);
          }
        }
      });
    } catch (e) {
      print('Error fetching user favorites: $e');
    }
  }

  // Toggle favorite status on API and update UI
  void _toggleFavoriteItem(
    String targetType,
    int targetId,
    Set<int> favoriteSet,
  ) async {
    final bool isCurrentlyFavorited = favoriteSet.contains(targetId);
    setState(() {
      if (isCurrentlyFavorited) {
        favoriteSet.remove(targetId);
      } else {
        favoriteSet.add(targetId);
      }
    });

    try {
      final interactionRepo = Provider.of<InteractionRepository>(
        context,
        listen: false,
      );
      await interactionRepo.toggleFavorite(targetType, targetId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyFavorited
                ? 'تمت الإزالة من المفضلة'
                : 'تمت الإضافة إلى المفضلة',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        if (isCurrentlyFavorited) {
          favoriteSet.add(targetId);
        } else {
          favoriteSet.remove(targetId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تحديث المفضلة: ${e.message}'),
          backgroundColor: kErrorColor,
        ),
      );
    } on NetworkException catch (e) {
      setState(() {
        if (isCurrentlyFavorited) {
          favoriteSet.add(targetId);
        } else {
          favoriteSet.remove(targetId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الشبكة: ${e.message}'),
          backgroundColor: kErrorColor,
        ),
      );
    } catch (e) {
      setState(() {
        if (isCurrentlyFavorited) {
          favoriteSet.add(targetId);
        } else {
          favoriteSet.remove(targetId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ غير متوقع: ${e.toString()}'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchAllHomePageData,
        color: kPrimaryColor,
        backgroundColor: Colors.white,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              )
            : _errorMessage != null
                ? Center(
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
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(color: kErrorColor),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _fetchAllHomePageData,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // --- 1. Header Section (Welcome + Search) ---
                      _buildHomeHeader(context),
                      const SizedBox(height: 24), // Space after header
                      // --- 2. Categories Section (Visually Enhanced) ---
                      _buildSectionHeader(context, 'استكشف حسب الفئة'),
                      const SizedBox(height: 16),
                      _buildCategoriesList(
                        context,
                        _siteCategories,
                      ), // Pass fetched categories
                      const SizedBox(height: 30),

                      // --- 3. Featured Destinations Section (Redesigned Carousel) ---
                      _buildSectionHeader(
                        context,
                        'وجهات مميزة',
                        onSeeAllTap: () {
                          print('See all destinations tapped!');
                          // Navigate to AllTouristSitesPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllTouristSitesPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildFeaturedCarousel(
                        context,
                        _featuredDestinations,
                        _favoriteDestinationIds,
                        (id) => _toggleFavoriteItem(
                          TargetTypes.touristSite,
                          id,
                          _favoriteDestinationIds,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- 4. Special Offers Section (NEW) ---
                      _buildSectionHeader(
                        context,
                        'عروض حصرية',
                        onSeeAllTap: () {
                          print('See all offers tapped!');
                          // Navigate to ProductsPage when "عرض الكل" is tapped
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductsPage(), // Navigate to ProductsPage
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildOffersList(
                        context,
                        _specialOffersProducts,
                      ), // Pass fetched products as offers
                      const SizedBox(height: 30),

                      // --- 5. Popular Hotels Section (Redesigned List - GridView) ---
                      _buildSectionHeader(
                        context,
                        'أشهر الفنادق',
                        onSeeAllTap: () {
                          print('See all hotels tapped!');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HotelsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPopularHotelsList(
                        context,
                        _popularHotels,
                        _favoriteHotelIds,
                        (id) => _toggleFavoriteItem(
                          TargetTypes.hotel,
                          id,
                          _favoriteHotelIds,
                        ),
                      ),
                      const SizedBox(height: 30), // Bottom padding
                    ],
                  ),
      ),
    );
  }

  // --- NEW Home Header Widget ---
  Widget _buildHomeHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final User? user = authRepo.currentUser;
    final String userName = user?.profile?.firstName ?? user?.username ?? 'Guest';

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أهلاً بك، $userName!',
            style: textTheme.headlineMedium?.copyWith(color: kTextColor),
          ),
          const SizedBox(height: 6),
          Text(
            'إلى أين تود الذهاب اليوم؟',
            style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              hintText: 'ابحث عن وجهة، فندق، معلم...',
              prefixIcon: Padding(
                padding: EdgeInsetsDirectional.only(start: 12.0, end: 8.0),
                child: Icon(Icons.search, color: kSecondaryTextColor, size: 22),
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              /* Handle search */
              print('Searching for: $value');
            },
          ),
        ],
      ),
    );
  }

  // --- Reusable Section Header (Slightly refined) ---
  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAllTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: textTheme.headlineSmall),
          if (onSeeAllTap != null)
            TextButton(onPressed: onSeeAllTap, child: const Text('عرض الكل')),
        ],
      ),
    );
  }

  // --- REDESIGNED Categories Horizontal List (Using fetched SiteCategories) ---
  Widget _buildCategoriesList(
    BuildContext context,
    List<SiteCategory> categories,
  ) {
    final textTheme = Theme.of(context).textTheme;

    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Center(
          child: Text(
            'لا توجد فئات حالياً.',
            style: TextStyle(color: kSecondaryTextColor),
          ),
        ),
      );
    }

    IconData _getCategoryIcon(String categoryName) {
      switch (categoryName.toLowerCase()) {
        case 'historical':
          return Icons.account_balance_outlined;
        case 'natural':
          return Icons.hiking_rounded;
        case 'religious':
          return Icons.mosque_outlined;
        case 'museums':
          return Icons.museum_outlined;
        case 'beaches':
          return Icons.beach_access_outlined;
        case 'markets':
          return Icons.shopping_bag_outlined;
        case 'hotels':
          return Icons.king_bed_outlined;
        case 'restaurants':
          return Icons.restaurant_menu_outlined;
        case 'cultural': // Add cultural icon if applicable
          return Icons.color_lens_outlined;
        default:
          return Icons.category_outlined;
      }
    }

    return SizedBox(
      height: 115,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemBuilder: (context, index) {
          final category = categories[index];
          // تأكد من أن ID الفئة ليس null قبل تمريره
          if (category.id == null) {
            return const SizedBox.shrink(); // تجاهل الفئات بدون ID صالح
          }
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: InkWell(
              onTap: () {
                // الانتقال إلى TouristSitesListPage وتمرير ID الفئة للفلترة
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('فتح قسم ${category.name}')),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TouristSitesListPage(
                      initialCategoryId: category.id, // <-- تمرير ID الفئة
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                width: 90,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: kDividerColor, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kPrimaryColor.withOpacity(0.1),
                            kPrimaryColor.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(category.name),
                        size: 28,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      category.name,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- REDESIGNED Featured Destinations Carousel (Using fetched TouristSite data) ---
  Widget _buildFeaturedCarousel(
    BuildContext context,
    List<TouristSite> destinations,
    Set<int> favorites,
    Function(int) onToggleFavorite,
  ) {
    if (destinations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Center(
          child: Text(
            'لا توجد وجهات مميزة حالياً.',
            style: TextStyle(color: kSecondaryTextColor),
          ),
        ),
      );
    }

    return CarouselSlider.builder(
      itemCount: destinations.length,
      itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
        final destination = destinations[itemIndex];
        if (destination.id == null || destination.name == null) {
          return const SizedBox.shrink();
        }

        final bool isFavorite = favorites.contains(destination.id!);
        return _buildDestinationCard(
          context: context,
          id: destination.id!,
          imageUrl: destination.imageUrl,
          title: destination.name!,
          location: destination.locationText ?? destination.city ?? 'سوريا',
          rating: 4.5, // Placeholder for rating, as it's not directly in TouristSite schema
          isFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
          onTap: () {
            print('Tapped on destination: ${destination.name!}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TouristSiteDetailsPage(siteId: destination.id!),
              ),
            );
          },
        );
      },
      options: CarouselOptions(
        height: 280.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 6),
        autoPlayAnimationDuration: const Duration(milliseconds: 1000),
        autoPlayCurve: Curves.easeInOutCubic,
        enlargeCenterPage: true,
        viewportFraction: 0.85,
        enlargeFactor: 0.25,
        initialPage: 0,
      ),
    );
  }

  // --- REDESIGNED Destination Card Widget ---
  Widget _buildDestinationCard({
    required BuildContext context,
    required int id,
    required String? imageUrl,
    required String title,
    required String location,
    required double rating,
    required bool isFavorite,
    required Function(int) onToggleFavorite,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        height: 280,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 280,
                          width: double.infinity,
                          color: kSurfaceColor,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: kSecondaryTextColor,
                              size: 50,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        height: 280,
                        width: double.infinity,
                        color: kSurfaceColor,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: kSecondaryTextColor,
                            size: 50,
                          ),
                        ),
                      ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 0.7, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 16.0,
                left: 16.0,
                right: 16.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withOpacity(0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            location,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Icon(Icons.star_rounded, color: kAccentColor, size: 18),
                        const SizedBox(width: 4.0),
                        Text(
                          rating.toStringAsFixed(1),
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12.0,
                right: 12.0,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => onToggleFavorite(id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.redAccent : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW Offers List (Using fetched Product data) ---
  Widget _buildOffersList(BuildContext context, List<Product> offers) {
    if (offers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Center(
          child: Text(
            'لا توجد عروض خاصة حالياً.',
            style: TextStyle(color: kSecondaryTextColor),
          ),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: offers.length,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemBuilder: (context, index) {
          final offer = offers[index];
          if (offer.id == null || offer.name == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: _buildOfferCard(
              context: context,
              imageUrl: offer.imageUrl,
              title: offer.name!,
              description: offer.description ?? 'منتج مميز بأسعار رائعة!',
              tag: offer.category?.name ?? 'منتجات',
              onTap: () {
                print("Tapped product offer: ${offer.name!}");
                // Navigate to Product Details Screen
                if (offer.id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsPage(productId: offer.id!),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  // --- NEW Offer Card Widget ---
  Widget _buildOfferCard({
    required BuildContext context,
    required String? imageUrl,
    required String title,
    required String description,
    required String tag,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    const double cardWidth = 280;

    return SizedBox(
      width: cardWidth,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        height: 150,
                        width: 100,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          width: 100,
                          color: kSurfaceColor,
                          child: const Center(
                            child: Icon(
                              Icons.local_offer_outlined,
                              color: kSecondaryTextColor,
                              size: 40,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        height: 150,
                        width: 100,
                        color: kSurfaceColor,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: kSecondaryTextColor,
                            size: 40,
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kAccentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: textTheme.labelSmall?.copyWith(
                            color: kAccentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW Popular Hotels List (Using GridView and fetched Hotel data) ---
  Widget _buildPopularHotelsList(
    BuildContext context,
    List<Hotel> hotels,
    Set<int> favorites,
    Function(int) onToggleFavorite,
  ) {
    if (hotels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Center(
          child: Text(
            'لا توجد فنادق متاحة حالياً.',
            style: TextStyle(color: kSecondaryTextColor),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.8,
      ),
      itemCount: hotels.length,
      itemBuilder: (context, index) {
        final hotel = hotels[index];
        if (hotel.id == null || hotel.name == null) {
          return const SizedBox.shrink();
        }
        final bool isFavorite = favorites.contains(hotel.id!);

        final double? minPrice = hotel.rooms != null && hotel.rooms!.isNotEmpty
            ? hotel.rooms!.map((room) => room.pricePerNight).reduce((a, b) => a! < b! ? a : b)
            : null;
        final String priceText = minPrice != null
            ? '${minPrice.toStringAsFixed(0)} SYP / ليلة'
            : 'غير متوفر';

        return _buildHotelCard(
          context: context,
          hotel: hotel,
          isFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
          onTap: () {
            print("Tapped on hotel: ${hotel.name!}");
            if (hotel.id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HotelDetailsPage(hotelId: hotel.id!),
                ),
              );
            }
          },
        );
      },
    );
  }

  // --- NEW Individual Hotel Card Widget (for GridView) ---
  Widget _buildHotelCard({
    required BuildContext context,
    required Hotel hotel,
    required bool isFavorite,
    required Function(int) onToggleFavorite,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    final double? minPrice = hotel.rooms != null && hotel.rooms!.isNotEmpty
        ? hotel.rooms!.map((room) => room.pricePerNight).reduce((a, b) => a! < b! ? a : b)
        : null;
    final String priceText = minPrice != null
        ? '${minPrice.toStringAsFixed(0)} SYP / ليلة'
        : 'غير متوفر';

    final String? imageUrl = hotel.imageUrl;
    final String title = hotel.name!;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20.0),
                  ),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                          imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 130,
                            width: double.infinity,
                            color: kSurfaceColor,
                            child: const Center(
                              child: Icon(
                                Icons.hotel_outlined,
                                color: kSecondaryTextColor,
                                size: 40,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 130,
                          width: double.infinity,
                          color: kSurfaceColor,
                          child: const Center(
                            child: Icon(
                              Icons.hotel,
                              color: kSecondaryTextColor,
                              size: 40,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () => onToggleFavorite(hotel.id!),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  left: 12,
                  right: 12,
                  bottom: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: kSecondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(hotel.city ?? 'غير محدد', style: textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (hotel.starRating != null && hotel.starRating! > 0)
                          RatingBarIndicator(
                            rating: hotel.starRating!.toDouble(),
                            itemBuilder: (context, index) => const Icon(
                              Icons.star_rounded,
                              color: kAccentColor,
                            ),
                            itemCount: 5,
                            itemSize: 16.0,
                            direction: Axis.horizontal,
                          )
                        else
                          Text('لا يوجد تقييم', style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor)),
                        const SizedBox(height: 6),
                        Text(
                          priceText,
                          style: textTheme.titleMedium?.copyWith(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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