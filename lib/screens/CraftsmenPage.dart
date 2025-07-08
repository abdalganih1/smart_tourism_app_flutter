// lib/screens/CraftsmenPage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // لفتح روابط الاتصال

import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/product.dart'; // To fetch products and then get sellers
import 'package:smart_tourism_app/models/user.dart'; // User model (for seller details)
import 'package:smart_tourism_app/models/user_profile.dart'; // UserProfile model
import 'package:smart_tourism_app/models/pagination.dart'; // Pagination model
import 'package:smart_tourism_app/config/config.dart';

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

class CraftsmenPage extends StatefulWidget {
  const CraftsmenPage({super.key});

  @override
  _CraftsmenPageState createState() => _CraftsmenPageState();
}

class _CraftsmenPageState extends State<CraftsmenPage> {
  // قائمة المدن (يمكن أن تكون ثابتة أو تُجلب من API لاحقاً)
  final List<String> _regions = [
    'جميع المناطق',
    'دمشق',
    'حلب',
    'اللاذقية',
    'حمص',
    'طرطوس',
    'السويداء',
  ];
  String _selectedRegion = 'جميع المناطق';

  List<User> _craftsmen = []; // سنقوم بتعبئة هذه القائمة من البائعين الفريدين
  bool _isLoading = false;
  String? _errorMessage;
  int _productsPage = 1;
  bool _canLoadMoreProducts = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCraftsmenFromProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _canLoadMoreProducts &&
        !_isLoading) {
      _productsPage++;
      _fetchCraftsmenFromProducts(page: _productsPage);
    }
  }

  // Fetch craftsmen by fetching products and extracting unique sellers
  Future<void> _fetchCraftsmenFromProducts({
    int page = 1,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      _productsPage = 1;
      _craftsmen.clear(); // Clear existing data on refresh
    }

    if (!_canLoadMoreProducts && !isRefresh) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) _errorMessage = null;
    });

    try {
      final tourismRepo = Provider.of<TourismRepository>(
        context,
        listen: false,
      );
      // Fetch products, assuming products include seller (User) details
      final response = await tourismRepo.getProducts(page: _productsPage);

      setState(() {
        Set<int> existingCraftsmenIds = _craftsmen.map((c) => c.id).toSet();
        for (var product in response.data) {
          if (product.seller != null &&
              product.seller!.userType == 'Vendor' &&
              !existingCraftsmenIds.contains(product.seller!.id)) {
            _craftsmen.add(product.seller!);
            existingCraftsmenIds.add(product.seller!.id);
          }
        }
        _canLoadMoreProducts =
            response.meta.currentPage < response.meta.lastPage;
      });
    } on ApiException catch (e) {
      print(
        'API Error fetching craftsmen via products: ${e.statusCode} - ${e.message}',
      );
      setState(() {
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      print('Network Error fetching craftsmen via products: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print(
        'Unexpected Error fetching craftsmen via products: ${e.toString()}',
      );
      setState(() {
        _errorMessage = 'فشل في تحميل بيانات الحرفيين.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Helper to open phone dialer ---
  Future<void> _launchPhoneDialer(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح تطبيق الاتصال.'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }

  // --- Helper to navigate to craftsman's shop (products list filtered by seller) ---
  void _navigateToCraftsmanShop(User craftsman) {
    if (mounted) {
      // Assuming you have a route or page for product listing filtered by seller ID
      // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => ProductListPage(sellerId: craftsman.id)));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سيتم فتح متجر ${craftsman.username}'),
          backgroundColor: kSuccessColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final List<User> filteredCraftsmen = _craftsmen;

    // final List<User> filteredCraftsmen =
    //     _selectedRegion == 'جميع المناطق'
    //         ? _craftsmen
    //         : _craftsmen
    //             .where((c) => c.profile?.city == _selectedRegion)
    //             .toList(); // Filter by city in profile

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دعم الحرفيين'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Region Filter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                value: _selectedRegion,
                items:
                    _regions
                        .map(
                          (region) => DropdownMenuItem(
                            value: region,
                            child: Text(region, style: textTheme.bodyLarge),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'اختر المنطقة',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: kSurfaceColor,
                ),
              ),
            ),

            // Craftsmen List
            Expanded(
              child:
                  _isLoading &&
                          _craftsmen.isEmpty &&
                          _errorMessage ==
                              null // Show spinner only if no data yet
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
                              Icon(
                                Icons.error_outline,
                                size: 60,
                                color: kErrorColor,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  color: kErrorColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed:
                                    () => _fetchCraftsmenFromProducts(
                                      isRefresh: true,
                                    ),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                      )
                      : filteredCraftsmen.isEmpty
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off_outlined,
                                size: 70,
                                color: kSecondaryTextColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'لا توجد حرفيون متاحون في هذه المنطقة.',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: kSecondaryTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'حاول اختيار منطقة أخرى أو تفقد لاحقاً.',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: kSecondaryTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            filteredCraftsmen.length +
                            (_canLoadMoreProducts &&
                                    _selectedRegion == 'جميع المناطق'
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index < filteredCraftsmen.length) {
                            final craftsman = filteredCraftsmen[index];
                            return CraftsmanCard(
                              craftsman: craftsman,
                              onCall: _launchPhoneDialer,
                              onVisitShop: _navigateToCraftsmanShop,
                            );
                          } else {
                            // Show loading indicator for more products
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: kPrimaryColor,
                                ),
                              ),
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
}

class CraftsmanCard extends StatelessWidget {
  final User craftsman; // Changed to User model
  final Function(String) onCall;
  final Function(User) onVisitShop;

  const CraftsmanCard({
    super.key,
    required this.craftsman,
    required this.onCall,
    required this.onVisitShop,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Assuming primary phone number is available in profile or User model
    String? contactNumber =
        craftsman.phoneNumbers
            ?.firstWhere(
              (phone) => phone.isPrimary,
              // orElse: () => craftsman.phoneNumbers?.first,
            )
            ?.phoneNumber;
    String displayContact = contactNumber ?? 'غير متوفر';

    // Placeholder image logic: Use profile_picture_url or default asset
    String? imageUrl = craftsman.profile?.profilePictureUrl;
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = Config.httpUrl + imageUrl; 
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to Craftsman's profile page or shop directly
          onVisitShop(craftsman);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Craftsman Image / Profile Picture
              Align(
                alignment: Alignment.center,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  backgroundImage:
                      (imageUrl != null && imageUrl.isNotEmpty)
                          ? NetworkImage(imageUrl) as ImageProvider
                          : const AssetImage(
                            'assets/user.png',
                          ), // Default asset image
                  onBackgroundImageError: (exception, stackTrace) {
                    print(
                      'Error loading craftsman profile picture: $exception',
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: Text(
                  craftsman.profile?.firstName != null &&
                          craftsman.profile!.lastName != null
                      ? '${craftsman.profile!.firstName!} ${craftsman.profile!.lastName!}'
                      : craftsman.username,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'حرفي في: ${craftsman.profile?.bio ?? 'لا يوجد وصف'}', // Using bio as a quick description
                  style: textTheme.bodyMedium?.copyWith(
                    color: kSecondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),

              // Contact Info (example with primary phone number)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 20,
                    color: kSecondaryTextColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'رقم التواصل: $displayContact',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          contactNumber != null && contactNumber.isNotEmpty
                              ? () => onCall(contactNumber)
                              : null, // Disable if no number
                      icon: const Icon(Icons.call_outlined),
                      label: Text('اتصل به', style: textTheme.labelLarge),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onVisitShop(craftsman),
                      icon: const Icon(Icons.store_outlined),
                      label: Text('زيارة المتجر', style: textTheme.labelLarge),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
