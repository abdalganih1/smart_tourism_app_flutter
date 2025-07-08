// lib/screens/events.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;

import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/tourist_activity.dart'; // TouristActivity model
import 'package:smart_tourism_app/models/pagination.dart'; // Pagination model

// تأكد من أن هذه الألوان معرفة ومتاحة
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kDividerColor = Color(0xFFEAEAEA);
const Color kSuccessColor = Color(0xFF2ECC71);
const Color kErrorColor = Color(0xFFE74C3C);

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<TouristActivity> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _canLoadMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
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
      _fetchEvents(page: _currentPage);
    }
  }

  Future<void> _fetchEvents({int page = 1, bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _events.clear(); // Clear existing data on refresh
    }

    if (!_canLoadMore && !isRefresh) return; // No more data to load

    setState(() {
      _isLoading = true;
      if (isRefresh) _errorMessage = null;
    });

    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      // Fetch Tourist Activities, which can act as "Events" in this context
      final response = await tourismRepo.getTouristActivities(page: _currentPage);

      setState(() {
        _events.addAll(response.data);
        _canLoadMore = response.meta.currentPage < response.meta.lastPage;
      });
    } on ApiException catch (e) {
      print('API Error fetching events: ${e.statusCode} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      print('Network Error fetching events: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('Unexpected Error fetching events: ${e.toString()}');
      setState(() {
        _errorMessage = 'فشل في تحميل الأحداث والفعاليات.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleEventAction(TouristActivity event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسجيل اهتمامك بـ ${event.name}.'),
        backgroundColor: kSuccessColor,
      ),
    );
    // TODO: Implement actual registration/booking logic for events
    // You might navigate to a booking screen or send a request to the API
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأحداث والفعاليات'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () => _fetchEvents(isRefresh: true),
          color: kPrimaryColor,
          backgroundColor: Colors.white,
          child: _isLoading && _events.isEmpty && _errorMessage == null
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
                            ElevatedButton(onPressed: () => _fetchEvents(isRefresh: true), child: const Text('إعادة المحاولة')),
                          ],
                        ),
                      ),
                    )
                  : _events.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_note_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                                const SizedBox(height: 20),
                                Text(
                                  'لا توجد أحداث وفعاليات حالياً.',
                                  style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'تابعنا لمعرفة أحدث الفعاليات السياحية والثقافية.',
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
                          itemCount: _events.length + (_canLoadMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _events.length) {
                              final event = _events[index];
                              return _buildEventCard(context, event);
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

  // --- Event Card Widget ---
  Widget _buildEventCard(BuildContext context, TouristActivity event) {
    final textTheme = Theme.of(context).textTheme;

    final String formattedDate = event.startDatetime != null
        ? intl.DateFormat('EEEE، dd MMMM yyyy - hh:mm a', 'ar').format(event.startDatetime!)
        : 'غير محدد';
    final String priceText = event.price != null && event.price! > 0
        ? '${event.price!.toStringAsFixed(0)} SYP'
        : 'مجاني';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to event details page (TouristActivityDetailsPage)
          print('Tapped on event: ${event.name}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.name??'',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 20, color: kSecondaryTextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 20, color: kSecondaryTextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.locationText ?? event.site?.name ?? 'غير محدد',
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (event.description != null && event.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    event.description!,
                    style: textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  priceText,
                  style: textTheme.headlineSmall?.copyWith(
                    color: event.price != null && event.price! > 0 ? kAccentColor : kSuccessColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleEventAction(event),
                  icon: const Icon(Icons.confirmation_num_outlined),
                  label: Text(event.price != null && event.price! > 0 ? "احجز تذكرتك" : "سجل الآن"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: event.price != null && event.price! > 0 ? kAccentColor : kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}