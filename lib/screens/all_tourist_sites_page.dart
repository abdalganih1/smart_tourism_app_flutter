// lib/screens/all_tourist_sites_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/models/tourist_site.dart';
import 'package:smart_tourism_app/models/pagination.dart';
import 'package:smart_tourism_app/screens/TouristSiteDetailsPage.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';

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


class AllTouristSitesPage extends StatefulWidget {
  const AllTouristSitesPage({super.key});

  @override
  State<AllTouristSitesPage> createState() => _AllTouristSitesPageState();
}

class _AllTouristSitesPageState extends State<AllTouristSitesPage> {
  final List<TouristSite> _sites = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();

  // يمكنك إضافة فلاتر هنا لاحقًا، مثل المدينة أو الفئة
  String? _selectedCityFilter;
  int? _selectedCategoryFilterId;


  @override
  void initState() {
    super.initState();
    _fetchTouristSites(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _canLoadMore && !_isLoading) {
      _currentPage++;
      _fetchTouristSites(page: _currentPage);
    }
  }

  Future<void> _fetchTouristSites({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _sites.clear();
      _canLoadMore = true;
    }

    if (!_canLoadMore && !isRefresh) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) _errorMessage = null;
    });

    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      final response = await tourismRepo.getTouristSites(
        page: _currentPage,
        city: _selectedCityFilter,
        categoryId: _selectedCategoryFilterId,
      );

      setState(() {
        _sites.addAll(response.data);
        _canLoadMore = response.meta.currentPage < response.meta.lastPage;
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
        _errorMessage = 'فشل في تحميل المواقع السياحية.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('جميع الوجهات السياحية'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
          // يمكنك إضافة زر للفلترة هنا لاحقًا
        ),
        body: RefreshIndicator(
          onRefresh: () => _fetchTouristSites(isRefresh: true),
          color: kPrimaryColor,
          backgroundColor: Colors.white,
          child: _isLoading && _sites.isEmpty && _errorMessage == null
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
                  : _sites.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                                const SizedBox(height: 20),
                                Text(
                                  'لا توجد وجهات سياحية متاحة حاليًا.',
                                  style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'حاول إعادة المحاولة لاحقًا أو تغيير معايير البحث.',
                                  style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // Two items per row
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 0.7, // Adjust as needed
                          ),
                          itemCount: _sites.length + (_canLoadMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _sites.length) {
                              final site = _sites[index];
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
      ),
    );
  }

  // Reuse a similar card widget from HomePage or create a new one for this page
  Widget _buildTouristSiteCard(BuildContext context, TouristSite site) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Navigate to Tourist Site Details Page
          if (site.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TouristSiteDetailsPage(siteId: site.id!),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: site.imageUrl != null && site.imageUrl!.isNotEmpty
                  ? Image.network(
                      site.imageUrl!,
                      height: 150,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      site.name ?? 'اسم الموقع غير متوفر',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: kSecondaryTextColor, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            site.city ?? 'غير محدد',
                            style: textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // يمكنك إضافة تقييم أو معلومات إضافية هنا إذا كانت متوفرة في نموذج TouristSite
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