// lib/screens/ActivitiesPage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl; // لتنسيق التاريخ والوقت

import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/tourist_activity.dart'; // TouristActivity model
import 'package:smart_tourism_app/models/pagination.dart'; // Pagination model

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

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  _ActivitiesPageState createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  List<TouristActivity> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchActivities();
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
      _fetchActivities(page: _currentPage);
    }
  }

  Future<void> _fetchActivities({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _activities.clear(); // Clear existing data on refresh
    }

    if (!_canLoadMore && !isRefresh) return; // No more data to load

    setState(() {
      _isLoading = true;
      if (isRefresh) _errorMessage = null;
    });

    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      final response = await tourismRepo.getTouristActivities(page: _currentPage);

      setState(() {
        _activities.addAll(response.data);
        _canLoadMore = response.meta.currentPage < response.meta.lastPage;
      });
    } on ApiException catch (e) {
      print('API Error fetching activities: ${e.statusCode} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      print('Network Error fetching activities: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('Unexpected Error fetching activities: ${e.toString()}');
      setState(() {
        _errorMessage = 'فشل في تحميل الأنشطة السياحية.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleBookingAction(TouristActivity activity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم طلب الحجز لـ ${activity.name}.'),
        backgroundColor: kSuccessColor,
      ),
    );
    // TODO: Implement actual booking logic.
    // You might navigate to a booking form or call a booking API endpoint.
    // Example: Provider.of<BookingRepository>(context, listen: false).placeActivityBooking(activity.id, ...);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأنشطة السياحية'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () => _fetchActivities(isRefresh: true),
          color: kPrimaryColor,
          backgroundColor: Colors.white,
          child: _isLoading && _activities.isEmpty && _errorMessage == null
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
                            ElevatedButton(onPressed: () => _fetchActivities(isRefresh: true), child: const Text('إعادة المحاولة')),
                          ],
                        ),
                      ),
                    )
                  : _activities.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.park_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                                const SizedBox(height: 20),
                                Text(
                                  'لا توجد أنشطة سياحية متاحة حالياً.',
                                  style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'تابعنا لمعرفة أحدث الأنشطة والجولات السياحية.',
                                  style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _activities.length + (_canLoadMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _activities.length) {
                              final activity = _activities[index];
                              return ActivityCard(activity: activity, onBookingAction: _handleBookingAction);
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
}

class ActivityCard extends StatelessWidget {
  final TouristActivity activity;
  final Function(TouristActivity) onBookingAction;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onBookingAction,
  });

  // Helper to format duration from minutes
  String _formatDuration(int? durationMinutes) {
    if (durationMinutes == null || durationMinutes <= 0) return 'غير محددة';
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    String result = '';
    if (hours > 0) result += '$hours ساعة${hours > 1 ? 'ات' : ''}';
    if (minutes > 0) {
      if (hours > 0) result += ' و ';
      result += '$minutes دقيقة${minutes > 1 ? 'ات' : ''}';
    }
    return result.isEmpty ? 'غير محددة' : result;
  }

  // Helper to get an icon based on activity characteristics (can be improved)
  IconData _getActivityIcon(TouristActivity activity) {
    if (activity.siteId != null) return Icons.location_city_outlined; // Tied to a site
    if (activity.price == 0) return Icons.event_available_outlined; // Free event
    return Icons.tour_outlined; // General tour/activity
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final String formattedCost = activity.price != null && activity.price! > 0
        ? '${activity.price!.toStringAsFixed(0)} SYP'
        : 'مجاني';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to Activity Details Page
          print('Tapped on activity: ${activity.name}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Image (from site image or general activity image)
            if (activity.site?.mainImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  activity.site?.mainImageUrl ??  'https://via.placeholder.com/400x200?text=No+Image', // Fallback to placeholder
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width * 0.4,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width * 0.4,
                    color: kSurfaceColor,
                    child: const Center(child: Icon(Icons.image_not_supported_outlined, color: kSecondaryTextColor, size: 60)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_getActivityIcon(activity), color: kPrimaryColor, size: 28),
                      const SizedBox(width: 12),
                      // Expanded(
                      //   child: Text(
                      //     activity.name,
                      //     style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                      //     maxLines: 2,
                      //     overflow: TextOverflow.ellipsis,
                      //   ),
                      // ),
                    ],
                  ),
                  if (activity.description != null && activity.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        activity.description!,
                        style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildInfoRow(context, Icons.access_time_outlined, 'المدة:', _formatDuration(activity.durationMinutes)),
                  _buildInfoRow(context, Icons.location_on_outlined, 'الموقع:', activity.locationText ?? activity.site?.city ?? 'غير محدد'),
                  _buildInfoRow(context, Icons.person_outline, 'المنظم:', activity.organizer?.username ?? 'غير محدد'), // Assuming organizer is loaded

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'التكلفة: $formattedCost',
                      style: textTheme.headlineSmall?.copyWith(
                        color: activity.price != null && activity.price! > 0 ? kAccentColor : kSuccessColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => onBookingAction(activity),
                      icon: const Icon(Icons.book_online_outlined),
                      label: Text(activity.price != null && activity.price! > 0 ? 'احجز الآن' : 'سجل الآن'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activity.price != null && activity.price! > 0 ? kAccentColor : kPrimaryColor,
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

  // Reusable info row for consistency
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kSecondaryTextColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: kTextColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}