// lib/screens/tourist_sites_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/screens/TouristSiteDetailsPage.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/tourist_site.dart';
import 'package:smart_tourism_app/models/site_category.dart';
import 'package:smart_tourism_app/models/pagination.dart'; // For paginated response

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


class TouristSitesListPage extends StatefulWidget {
  final int? initialCategoryId; // Optional: filter by category when navigating
  final String? initialCity;    // Optional: filter by city when navigating

  const TouristSitesListPage({super.key, this.initialCategoryId, this.initialCity});

  @override
  State<TouristSitesListPage> createState() => _TouristSitesListPageState();
}

class _TouristSitesListPageState extends State<TouristSitesListPage> {
  final ScrollController _scrollController = ScrollController();
  List<TouristSite> _touristSites = [];
  List<SiteCategory> _siteCategories = []; // لتخزين الفئات وجلبها
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _canLoadMore = true;

  // Filter/Sort States
  String? _selectedCity;
  int? _selectedCategoryId; // يمكن أن يكون null لـ "جميع الفئات"
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // For general search by name/description

  @override
  void initState() {
    super.initState();
    // Initialize filters from constructor arguments if provided
    _selectedCategoryId = widget.initialCategoryId;
    _selectedCity = widget.initialCity;

    // Use Future.sync or a more robust initialization pattern if you need _siteCategories before _fetchTouristSites
    _fetchSiteCategories().then((_) {
      _fetchTouristSites(isRefresh: true); // Initial data fetch
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        _canLoadMore && !_isLoading) {
      _currentPage++;
      _fetchTouristSites(page: _currentPage);
    }
  }

  Future<void> _fetchTouristSites({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _touristSites.clear(); // Clear existing data on refresh
      _canLoadMore = true;
    }

    if (!_canLoadMore && !isRefresh) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) _errorMessage = null;
    });

    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      final PaginatedResponse<TouristSite> response = await tourismRepo.getTouristSites(
        page: _currentPage,
        city: _selectedCity,
        categoryId: _selectedCategoryId, // إذا كان null، فلن يرسل البارامتر
        // query: _searchQuery.isNotEmpty ? _searchQuery : null, // <--- تم التعليق على هذا السطر أو إزالته
      );

      // Perform local search filtering if backend API doesn't support 'query'
      List<TouristSite> fetchedSites = response.data;
      if (_searchQuery.isNotEmpty) {
        fetchedSites = fetchedSites.where((site) {
          final queryLower = _searchQuery.toLowerCase();
          final nameLower = site.name?.toLowerCase() ?? '';
          final descriptionLower = site.description?.toLowerCase() ?? '';
          final cityLower = site.city?.toLowerCase() ?? '';
          return nameLower.contains(queryLower) ||
                 descriptionLower.contains(queryLower) ||
                 cityLower.contains(queryLower);
        }).toList();
      }


      setState(() {
        _touristSites.addAll(fetchedSites); // Add filtered data
        _canLoadMore = response.meta.currentPage < response.meta.lastPage; // Pagination based on full API response
      });
    } on ApiException catch (e) {
      print('API Error fetching tourist sites: ${e.statusCode} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      print('Network Error fetching tourist sites: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('Unexpected Error fetching tourist sites: ${e.toString()}');
      setState(() {
        _errorMessage = 'فشل في تحميل الوجهات السياحية.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSiteCategories() async {
    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      final List<SiteCategory> fetchedCategories = await tourismRepo.getSiteCategories();
      setState(() {
        // إضافة خيار "جميع الفئات" كأول عنصر، مع ID Null
        _siteCategories = [
          SiteCategory(id: null, name: 'جميع الفئات', description: null, parentCategoryId: null),
          ...fetchedCategories,
        ];
        // إذا كان _selectedCategoryId لا يزال null ولم يتم تحديده من الـ widget، اختر "جميع الفئات"
        // أو إذا كانت قيمة initialCategoryId لا تتوافق مع أي فئة موجودة
        if (_selectedCategoryId == null || !_siteCategories.any((cat) => cat.id == _selectedCategoryId)) {
           _selectedCategoryId = _siteCategories.first.id;
        }
      });
    } catch (e) {
      print('Error fetching site categories: $e');
      // في حال وجود خطأ، تأكد من وجود خيار "جميع الفئات" على الأقل
      setState(() {
        _siteCategories = [SiteCategory(id: null, name: 'جميع الفئات', description: null, parentCategoryId: null)];
        _selectedCategoryId ??= _siteCategories.first.id;
      });
    }
  }

  void _applyFilters() {
    // هذا سيقوم بإعادة جلب البيانات من الصفحة الأولى مع الفلاتر الجديدة
    _fetchTouristSites(isRefresh: true);
  }

  void _navigateToDetails(int siteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TouristSiteDetailsPage(siteId: siteId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الوجهات السياحية'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () => _fetchTouristSites(isRefresh: true),
          color: kPrimaryColor,
          backgroundColor: Colors.white,
          child: Column(
            children: [
              // --- Filter and Search Bar ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن وجهة...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: kSurfaceColor,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = ''; // Clear local search query
                                  });
                                  _applyFilters(); // Re-fetch/re-filter
                                },
                              )
                            : null,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          // No need to call _applyFilters on every change if we filter locally
                          // or if _applyFilters uses the _searchQuery directly on submit.
                          // It will be applied on submit anyway.
                        });
                      },
                      onSubmitted: (_) => _applyFilters(), // Apply search on enter
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>( // Can be null
                            value: _selectedCity,
                            hint: Text('اختر مدينة', style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor)),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: kSurfaceColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('جميع المدن', textAlign: TextAlign.right)),
                              // يمكنك جلب المدن ديناميكياً من API أو قائمة ثابتة
                              ...['دمشق', 'حلب', 'حمص', 'اللاذقية', 'طرطوس', 'السويداء'].map((city) =>
                                  DropdownMenuItem<String?>(value: city, child: Text(city, textAlign: TextAlign.right)),
                              ).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCity = value;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _siteCategories.isEmpty // Show loading/empty state for categories dropdown
                              ? const SizedBox(
                                  width: 48, height: 48,
                                  child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 2),
                                )
                              : DropdownButtonFormField<int?>( // Can be null
                                  value: _selectedCategoryId,
                                  hint: Text('اختر فئة', style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor)),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: kSurfaceColor,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  items: _siteCategories.map<DropdownMenuItem<int?>>((SiteCategory category) {
                                    return DropdownMenuItem<int?>(
                                      value: category.id, // ID will be null for "جميع الفئات"
                                      child: Text(category.name, textAlign: TextAlign.right),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategoryId = value;
                                    });
                                    _applyFilters();
                                  },
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // --- Sites List ---
              Expanded(
                child: _isLoading && _touristSites.isEmpty && _errorMessage == null
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
                                  ElevatedButton(onPressed: () => _fetchTouristSites(isRefresh: true), child: const Text('إعادة المحاولة')),
                                ],
                              ),
                            ),
                          )
                        : _touristSites.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(30.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.location_off_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                                      const SizedBox(height: 20),
                                      Text(
                                        'لا توجد وجهات سياحية مطابقة.',
                                        style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'حاول تغيير عوامل التصفية أو إزالة البحث.',
                                        style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: _touristSites.length + (_canLoadMore && !_searchQuery.isNotEmpty ? 1 : 0), // Only show load more if no local search
                                itemBuilder: (context, index) {
                                  if (index < _touristSites.length) {
                                    final site = _touristSites[index];
                                    return _buildTouristSiteCard(context, site);
                                  } else {
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
      ),
    );
  }

  // --- Tourist Site Card Widget ---
  Widget _buildTouristSiteCard(BuildContext context, TouristSite site) {
    final textTheme = Theme.of(context).textTheme;
    // You might want to get actual rating from API if available for the site
    final double rating = 4.5; // Placeholder or calculate from InteractionRepo

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          if (site.id != null) {
            _navigateToDetails(site.id!);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: site.imageUrl != null && site.imageUrl!.isNotEmpty // Use the imageUrl getter
                  ? Image.network(
                      site.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180, width: double.infinity, color: kSurfaceColor,
                        child: const Center(child: Icon(Icons.broken_image_outlined, color: kSecondaryTextColor, size: 60)),
                      ),
                    )
                  : Container(
                      height: 180, width: double.infinity, color: kSurfaceColor,
                      child: const Center(child: Icon(Icons.image_not_supported, color: kSecondaryTextColor, size: 80)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name!, // Name is required, so ! is safe here
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: kSecondaryTextColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          site.locationText ?? site.city ?? 'سوريا',
                          style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.star_rounded, size: 18, color: kAccentColor),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    site.description ?? 'لا يوجد وصف متاح لهذا الموقع.',
                    style: textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (site.id != null) {
                          _navigateToDetails(site.id!);
                        }
                      },
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('عرض التفاصيل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
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