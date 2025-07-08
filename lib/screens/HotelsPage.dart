// lib/screens/HotelsPage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // لعرض التقييمات

import 'package:smart_tourism_app/repositories/hotel_repository.dart';
import 'package:smart_tourism_app/screens/hotel_details_page.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/hotel.dart'; // Hotel model
import 'package:smart_tourism_app/models/pagination.dart'; // Pagination model
import 'package:smart_tourism_app/config/config.dart'; // For httpUrl for images

// تأكد من أن هذه الألوان معرفة ومتاحة، يفضل أن تكون في ملف ثوابت مشترك
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kDividerColor = Color(0xFFEAEAEA);
const Color kSuccessColor = Color(0xFF2ECC71);
const Color kErrorColor = Color(0xFFE74C3C);

// Placeholders for your BookingPage or HotelDetailsPage
// You would replace this with your actual HotelDetailsPage class.


class HotelsPage extends StatefulWidget {
  const HotelsPage({super.key});

  @override
  _HotelsPageState createState() => _HotelsPageState();
}

class _HotelsPageState extends State<HotelsPage> {
  List<Hotel> _hotels = []; // Stores all fetched hotels (before local search filter)
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = ''; // Text in the search bar
  String? _selectedCityFilter; // City filter from dialog
  int? _selectedStarRatingFilter; // Star rating filter from dialog
  String _selectedSortBy = 'default'; // Sort order from dialog

  final List<String> _cities = ['جميع المدن', 'دمشق', 'حلب', 'حمص', 'اللاذقية', 'طرطوس', 'السويداء']; // Example cities
  final List<int> _starRatings = [0, 1, 2, 3, 4, 5]; // 0 for "All" or "Any" stars


  @override
  void initState() {
    super.initState();
    _fetchHotels(isRefresh: true); // Initial fetch when page loads
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if scrolled to bottom and more data can be loaded
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _canLoadMore && !_isLoading) {
      _currentPage++;
      _fetchHotels(page: _currentPage);
    }
  }

  Future<void> _fetchHotels({int page = 1, bool isRefresh = false}) async {
    // If it's a refresh, reset pagination and clear existing data
    if (isRefresh) {
      _currentPage = 1;
      _hotels.clear();
      _canLoadMore = true; // Assume there's more data on refresh
    }

    // If no more pages can be loaded, and it's not a refresh, just return
    if (!_canLoadMore && !isRefresh) return;

    // Set loading state
    setState(() {
      _isLoading = true;
      if (isRefresh) _errorMessage = null; // Clear previous errors on refresh
    });

    try {
      final hotelRepo = Provider.of<HotelRepository>(context, listen: false);

      final response = await hotelRepo.getHotels(
        page: _currentPage,
        city: _selectedCityFilter, // Pass filter directly, null for "All Cities"
        starRating: _selectedStarRatingFilter, // Pass filter directly, null for "All Stars"
      );

      // Add new data and update pagination info
      setState(() {
        _hotels.addAll(response.data);
        _canLoadMore = response.meta.currentPage < response.meta.lastPage;
        // Apply local sort if API doesn't handle it
        _applyLocalSort(_hotels);
      });
    } on ApiException catch (e) {
      print('API Error fetching hotels: ${e.statusCode} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
        _canLoadMore = false; // Stop trying to load more on API error
      });
    } on NetworkException catch (e) {
      print('Network Error fetching hotels: ${e.message}');
      setState(() {
        _errorMessage = e.message;
        _canLoadMore = false; // Stop trying to load more on network error
      });
    } catch (e) {
      print('Unexpected Error fetching hotels: ${e.toString()}');
      setState(() {
        _errorMessage = 'فشل في تحميل الفنادق: ${e.toString()}';
        _canLoadMore = false; // Stop trying to load more on unexpected error
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Local sorting function on the fetched list
  void _applyLocalSort(List<Hotel> list) {
    list.sort((a, b) {
      switch (_selectedSortBy) {
        case 'price_asc':
          final priceA = a.rooms != null && a.rooms!.isNotEmpty ? a.rooms!.first.pricePerNight : double.maxFinite;
          final priceB = b.rooms != null && b.rooms!.isNotEmpty ? b.rooms!.first.pricePerNight : double.maxFinite;
          return priceA!.compareTo(priceB!);
        case 'price_desc':
          final priceA = a.rooms != null && a.rooms!.isNotEmpty ? a.rooms!.first.pricePerNight : double.minPositive;
          final priceB = b.rooms != null && b.rooms!.isNotEmpty ? b.rooms!.first.pricePerNight : double.minPositive;
          return priceB!.compareTo(priceA!);
        case 'rating_desc':
          return (b.starRating ?? 0).compareTo(a.starRating ?? 0);
        case 'name_asc':
          return a.name!.compareTo(b.name!);
        default:
          return 0; // Maintain original order if API already sorted or no specific sort
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      // Note: This only filters locally. If you need server-side search,
      // you'd call _fetchHotels(isRefresh: true) and pass the query to the API.
    });
  }

  void _applyFiltersAndSort() {
    _fetchHotels(isRefresh: true); // Re-fetch all data from API with new filters and then apply local sort.
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Apply search filtering locally to the fetched _hotels list.
    // This list will be used for display.
    final List<Hotel> displayedHotels = _hotels.where((hotel) {
      return hotel.name!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();


    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الفنادق'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_outlined),
              tooltip: 'تصفية وفرز',
              onPressed: () => _showFilterAndSortDialog(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'ابحث عن فندق...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: kSurfaceColor,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),

            // Hotels List or status message
            Expanded(
              child: _isLoading && _hotels.isEmpty && _errorMessage == null
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryColor)) // Initial loading
                  : _errorMessage != null // Show error message if fetch failed
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
                                ElevatedButton(onPressed: () => _fetchHotels(isRefresh: true), child: const Text('إعادة المحاولة')),
                              ],
                            ),
                          ),
                        )
                      : displayedHotels.isEmpty // Show no hotels message if list is empty after all operations
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.hotel, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                                    const SizedBox(height: 20),
                                    Text(
                                      'لا توجد فنادق مطابقة لمعايير البحث أو التصفية.',
                                      style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'حاول تغيير معايير البحث أو التصفية.',
                                      style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 20,
                                childAspectRatio: 0.75, // Adjust card aspect ratio
                              ),
                              itemCount: displayedHotels.length + (_canLoadMore || _isLoading ? 1 : 0), // Add 1 for loading indicator at bottom
                              itemBuilder: (context, index) {
                                if (index < displayedHotels.length) {
                                  final hotel = displayedHotels[index];
                                  return HotelCard(hotel: hotel);
                                } else {
                                  // Show loading indicator when fetching more data
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                                  );
                                }
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Filter and Sort Dialog ---
  void _showFilterAndSortDialog(BuildContext context) {
    // Keep local state for the dialog
    String? tempSelectedCity = _selectedCityFilter;
    int? tempSelectedStarRating = _selectedStarRatingFilter;
    String tempSelectedSortBy = _selectedSortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows content to take full height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder( // Use StatefulBuilder for internal state management of the dialog
          builder: (BuildContext context, StateSetter setStateModal) {
            final textTheme = Theme.of(context).textTheme;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Make column wrap content
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تصفية وفرز الفنادق',
                      style: textTheme.headlineSmall,
                    ),
                    const Divider(height: 30, thickness: 1),

                    // --- City Filter ---
                    Text('المدينة', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: tempSelectedCity,
                      hint: const Text('اختر مدينة'),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        fillColor: kSurfaceColor,
                        filled: true,
                      ),
                      items: _cities.map((city) {
                        return DropdownMenuItem(
                          value: city == 'جميع المدن' ? null : city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateModal(() {
                          tempSelectedCity = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Star Rating Filter ---
                    Text('التصنيف (نجوم)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<int>(
                      value: tempSelectedStarRating,
                      hint: const Text('اختر عدد النجوم'),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        fillColor: kSurfaceColor,
                        filled: true,
                      ),
                      items: _starRatings.map((rating) {
                        return DropdownMenuItem(
                          value: rating == 0 ? null : rating,
                          child: Text(rating == 0 ? 'كل التصنيفات' : '$rating نجوم'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateModal(() {
                          tempSelectedStarRating = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- Sort By ---
                    Text('الفرز حسب', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('افتراضي'),
                          value: 'default',
                          groupValue: tempSelectedSortBy,
                          onChanged: (value) => setStateModal(() => tempSelectedSortBy = value!),
                          activeColor: kPrimaryColor,
                        ),
                        RadioListTile<String>(
                          title: const Text('السعر (من الأقل للأعلى)'),
                          value: 'price_asc',
                          groupValue: tempSelectedSortBy,
                          onChanged: (value) => setStateModal(() => tempSelectedSortBy = value!),
                          activeColor: kPrimaryColor,
                        ),
                        RadioListTile<String>(
                          title: const Text('السعر (من الأعلى للأقل)'),
                          value: 'price_desc',
                          groupValue: tempSelectedSortBy,
                          onChanged: (value) => setStateModal(() => tempSelectedSortBy = value!),
                          activeColor: kPrimaryColor,
                        ),
                        RadioListTile<String>(
                          title: const Text('التصنيف (من الأعلى للأقل)'),
                          value: 'rating_desc',
                          groupValue: tempSelectedSortBy,
                          onChanged: (value) => setStateModal(() => tempSelectedSortBy = value!),
                          activeColor: kPrimaryColor,
                        ),
                        RadioListTile<String>(
                          title: const Text('الاسم (أبجدياً)'),
                          value: 'name_asc',
                          groupValue: tempSelectedSortBy,
                          onChanged: (value) => setStateModal(() => tempSelectedSortBy = value!),
                          activeColor: kPrimaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                          },
                          child: Text('إلغاء', style: textTheme.labelMedium),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCityFilter = tempSelectedCity;
                              _selectedStarRatingFilter = tempSelectedStarRating;
                              _selectedSortBy = tempSelectedSortBy;
                            });
                            Navigator.pop(context); // Close dialog
                            _applyFiltersAndSort(); // Apply and re-fetch
                          },
                          child: Text('تطبيق', style: textTheme.labelLarge),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HotelCard extends StatelessWidget {
  final Hotel hotel; // Changed to Hotel model

  const HotelCard({
    super.key,
    required this.hotel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Determine the minimum price per night if rooms are available
    final double? displayPrice = hotel.rooms != null && hotel.rooms!.isNotEmpty
        ? hotel.rooms!.map((room) => room.pricePerNight).reduce((a, b) => a! < b! ? a : b) // Get min price
        : null;

    // Default image if mainImageUrl is null or empty, or if network fails
    final String defaultImageUrl = 'https://via.placeholder.com/300x200?text=No+Hotel+Image';
    // Use the getter from Hotel model which handles /storage prefix
    final String imageUrl = hotel.imageUrl ?? defaultImageUrl; 

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('عرض تفاصيل فندق ${hotel.name}')),
          );
          // Navigate to HotelDetailsPage
          Navigator.push(context, MaterialPageRoute(builder: (context) => HotelDetailsPage(hotelId: hotel.id)));
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: MediaQuery.of(context).size.width * 0.35, // Adjust height based on screen width
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width * 0.35,
                  color: kSurfaceColor,
                  child: const Center(child: Icon(Icons.hotel_outlined, color: kSecondaryTextColor, size: 60)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name!,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: kSecondaryTextColor, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.city ?? 'غير محدد',
                          style: textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (hotel.starRating != null && hotel.starRating! > 0) // Only show if rating is positive
                        RatingBarIndicator(
                          rating: hotel.starRating!.toDouble(),
                          itemBuilder: (context, index) => Icon(
                            Icons.star_rounded,
                            color: kAccentColor,
                          ),
                          itemCount: 5,
                          itemSize: 18.0,
                          direction: Axis.horizontal,
                        )
                      else // Show "No rating" or a default if rating is 0 or null
                        Text('لا يوجد تقييم', style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor)),
                      
                      Text(
                        displayPrice != null
                            ? '${displayPrice.toStringAsFixed(0)} SYP / ليلة'
                            : 'غير متوفر',
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: double.infinity, // Make button fill width
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to HotelDetailsPage
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HotelDetailsPage(hotelId: hotel.id)));
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text('احجز الآن', style: textTheme.labelLarge),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}