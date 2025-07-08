// lib/screens/PlaceDetailsPage.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart'; // لعرض الصور المتعددة
import 'package:intl/intl.dart'as intl;
import 'package:provider/provider.dart';
import 'package:smart_tourism_app/screens/evaluations.dart';
import 'package:url_launcher/url_launcher.dart'; // لفتح Google Maps أو تطبيقات الملاحة
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // لعرض التقييمات

import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/repositories/interaction_repository.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/tourist_site.dart'; // TouristSite model
import 'package:smart_tourism_app/models/rating.dart'; // Rating model
import 'package:smart_tourism_app/models/pagination.dart'; // Pagination model
import 'package:smart_tourism_app/utils/constants.dart'; // For TargetTypes (e.g., TargetTypes.touristSite)

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

class PlaceDetailsPage extends StatefulWidget {
  final int siteId; // سنستقبل ID الموقع بدلاً من البيانات الكاملة

  const PlaceDetailsPage({super.key, required this.siteId});

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  TouristSite? _placeDetails;
  bool _isLoading = false;
  String? _errorMessage;
  Set<Marker> _markers = {};
  bool _isFavorited = false;
  int? _favoriteId; // ID of the favorite entry if already favorited

  // Ratings related state
  List<Rating> _ratings = [];
  bool _isRatingsLoading = false;
  String? _ratingsErrorMessage;
  int _ratingsCurrentPage = 1;
  bool _canLoadMoreRatings = true;
  final ScrollController _ratingsScrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _fetchPlaceDetails();
    _checkFavoriteStatus();
    _fetchRatings();
    _ratingsScrollController.addListener(_onRatingsScroll);
  }

  @override
  void dispose() {
    _ratingsScrollController.dispose();
    super.dispose();
  }

  void _onRatingsScroll() {
    if (_ratingsScrollController.position.pixels == _ratingsScrollController.position.maxScrollExtent && _canLoadMoreRatings && !_isRatingsLoading) {
      _ratingsCurrentPage++;
      _fetchRatings(page: _ratingsCurrentPage);
    }
  }

  Future<void> _fetchPlaceDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      final details = await tourismRepo.getTouristSiteDetails(widget.siteId);
      setState(() {
        _placeDetails = details;
        if (details.latitude != null && details.longitude != null) {
          _markers.add(
            Marker(
              markerId: MarkerId(details.id.toString()),
              position: LatLng(details.latitude!, details.longitude!),
              infoWindow: InfoWindow(title: details.name),
            ),
          );
        }
      });
    } on ApiException catch (e) {
      print('API Error fetching place details: ${e.statusCode} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      print('Network Error fetching place details: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('Unexpected Error fetching place details: ${e.toString()}');
      setState(() {
        _errorMessage = 'فشل في تحميل تفاصيل المكان.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      final status = await interactionRepo.checkFavoriteStatus(TargetTypes.touristSite, widget.siteId);
      setState(() {
        _isFavorited = status['is_favorited'] ?? false;
        _favoriteId = status['favorite_id'];
      });
    } catch (e) {
      print('Error checking favorite status: $e');
      // Don't block UI for this error, just log it
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isLoading = true; // Temporarily show loading on button
    });
    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      final result = await interactionRepo.toggleFavorite(TargetTypes.touristSite, widget.siteId);
      setState(() {
        _isFavorited = result['is_favorited'] ?? !_isFavorited; // Update based on API response
        _favoriteId = result['favorite_id'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (_isFavorited ? 'تم الإضافة للمفضلة.' : 'تمت الإزالة من المفضلة.')),
          backgroundColor: _isFavorited ? kSuccessColor : kAccentColor,
        ),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'فشل تحديث المفضلة.'), backgroundColor: kErrorColor),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ غير متوقع في المفضلة.'), backgroundColor: kErrorColor),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRatings({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) {
      _ratingsCurrentPage = 1;
      _ratings.clear(); // Clear existing data on refresh
    }

    if (!_canLoadMoreRatings && !isRefresh) return; // No more data to load

    setState(() {
      _isRatingsLoading = true;
      if (isRefresh) _ratingsErrorMessage = null;
    });

    try {
      final interactionRepo = Provider.of<InteractionRepository>(context, listen: false);
      final response = await interactionRepo.getRatingsForTarget(TargetTypes.touristSite, widget.siteId, page: _ratingsCurrentPage);

      setState(() {
        _ratings.addAll(response.data);
        _canLoadMoreRatings = response.meta.currentPage < response.meta.lastPage;
      });
    } on ApiException catch (e) {
      print('API Error fetching ratings: ${e.statusCode} - ${e.message}');
      setState(() {
        _ratingsErrorMessage = e.message;
      });
    } on NetworkException catch (e) {
      print('Network Error fetching ratings: ${e.message}');
      setState(() {
        _ratingsErrorMessage = e.message;
      });
    } catch (e) {
      print('Unexpected Error fetching ratings: ${e.toString()}');
      setState(() {
        _ratingsErrorMessage = 'فشل في تحميل التقييمات.';
      });
    } finally {
      setState(() {
        _isRatingsLoading = false;
      });
    }
  }

  Future<void> _launchMapsUrl(double lat, double lon, String label) async {
    final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
    final String appleMapsUrl = 'https://maps.apple.com/?q=$lat,$lon';

    if (Theme.of(context).platform == TargetPlatform.android) {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح خرائط جوجل.')),
        );
      }
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(Uri.parse(appleMapsUrl));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح خرائط آبل.')),
        );
      }
    } else {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الخرائط.')),
        );
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
          title: Text(_placeDetails?.name ?? 'تفاصيل المكان'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: _isLoading && _placeDetails == null
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
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(color: kErrorColor),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _fetchPlaceDetails,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _placeDetails == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.place, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                              const SizedBox(height: 20),
                              Text(
                                'تعذر تحميل تفاصيل المكان.',
                                style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'قد يكون المكان غير موجود أو هناك مشكلة في الاتصال.',
                                style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Image / Image Gallery (Placeholder for multiple images)
                            _buildImageGallery(context, _placeDetails!.mainImageUrl),
                            const SizedBox(height: 20),

                            // Place Name and Favorite Button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _placeDetails!.name??'',
                                      style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  _isLoading // Show loading indicator on button
                                      ? const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 2))
                                      : IconButton(
                                          icon: Icon(
                                            _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            color: _isFavorited ? Colors.redAccent : kSecondaryTextColor,
                                            size: 30,
                                          ),
                                          onPressed: _toggleFavorite,
                                          tooltip: _isFavorited ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Description
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                _placeDetails!.description ?? 'لا يوجد وصف متاح لهذا المكان.',
                                style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Location on Map
                            if (_placeDetails!.latitude != null && _placeDetails!.longitude != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      "الموقع على الخريطة",
                                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 250, // Height for the map container
                                    margin: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: kDividerColor, width: 1),
                                    ),
                                    child: ClipRRect( // Clip map for rounded corners
                                      borderRadius: BorderRadius.circular(16),
                                      child: GoogleMap(
                                        initialCameraPosition: CameraPosition(
                                          target: LatLng(_placeDetails!.latitude!, _placeDetails!.longitude!),
                                          zoom: 15,
                                        ),
                                        markers: _markers,
                                        myLocationButtonEnabled: false, // Hide default button
                                        myLocationEnabled: true,
                                        zoomControlsEnabled: false, // Hide default zoom controls
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _launchMapsUrl(_placeDetails!.latitude!, _placeDetails!.longitude!, _placeDetails!.name??'');
                                      },
                                      icon: const Icon(Icons.directions_outlined),
                                      label: const Text("احصل على الاتجاهات"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor, // Use primary color for action button
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),

                            // Reviews and Ratings
                            _buildRatingsSection(context),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
      ),
    );
  }

  // --- Image Gallery Widget (using CarouselSlider) ---
  Widget _buildImageGallery(BuildContext context, String? mainImageUrl) {
    // For now, only mainImageUrl is available. If you have additional_images, add them here.
    final List<String> imageUrls = [];
    if (mainImageUrl != null && mainImageUrl.isNotEmpty) {
      imageUrls.add(mainImageUrl);
    }
    // TODO: If TouristSite model supports 'additional_images', add them to imageUrls list
    // Example: if (_placeDetails!.additionalImages != null) imageUrls.addAll(_placeDetails!.additionalImages!);

    if (imageUrls.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        color: kSurfaceColor,
        child: const Center(child: Icon(Icons.image_not_supported, size: 100, color: kSecondaryTextColor)),
      );
    }

    return CarouselSlider.builder(
      itemCount: imageUrls.length,
      itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: kSurfaceColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrls[itemIndex],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_outlined, size: 60, color: kSecondaryTextColor),
              ),
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: 250.0,
        autoPlay: imageUrls.length > 1, // Only auto-play if more than one image
        enlargeCenterPage: true,
        viewportFraction: 0.9,
        aspectRatio: 16/9,
      ),
    );
  }

  // --- Ratings Section Widget ---
  Widget _buildRatingsSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "المراجعات والتقييمات",
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
              if (_placeDetails != null)
                TextButton.icon(
                  onPressed: () {
                    // Navigate to full ReviewsPage for this site
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewsPage(
                          targetType: TargetTypes.touristSite,
                          targetId: _placeDetails!.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.rate_review_outlined, size: 20, color: kPrimaryColor),
                  label: Text('عرض كل التقييمات', style: textTheme.labelMedium),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _isRatingsLoading && _ratings.isEmpty
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _ratingsErrorMessage != null
                  ? Center(child: Text('خطأ في تحميل التقييمات: $_ratingsErrorMessage', style: textTheme.bodyMedium?.copyWith(color: kErrorColor)))
                  : _ratings.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد تقييمات حتى الآن.',
                            style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
                          shrinkWrap: true, // Wrap content height
                          itemCount: _ratings.length > 3 ? 3 : _ratings.length, // Show top 3 reviews
                          itemBuilder: (context, index) {
                            final rating = _ratings[index];
                            return _buildReviewCard(context, rating);
                          },
                        ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Show a dialog to add a new review or navigate to AddReviewPage
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('إضافة مراجعة غير متاحة بعد في هذه الصفحة.'), backgroundColor: kAccentColor),
                );
              },
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('أضف مراجعتك'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reused Review Card from ReviewsPage
  Widget _buildReviewCard(BuildContext context, Rating review) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  child: Text(
                    review.user?.username?.substring(0, 1).toUpperCase() ?? 'U',
                    style: textTheme.titleMedium?.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.user?.username ?? 'مستخدم مجهول',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      const SizedBox(height: 4),
                      RatingBarIndicator(
                        rating: review.ratingValue.toDouble(),
                        itemBuilder: (context, index) => Icon(
                          Icons.star_rounded,
                          color: kAccentColor,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                        direction: Axis.horizontal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.reviewTitle != null && review.reviewTitle!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                child: Text(
                  review.reviewTitle!,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            if (review.reviewText != null && review.reviewText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  review.reviewText!,
                  style: textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '${review.createdAt != null ? intl.DateFormat('yyyy/MM/dd').format(review.createdAt!) : ''}',
                style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}