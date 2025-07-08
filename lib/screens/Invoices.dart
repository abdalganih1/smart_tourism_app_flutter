// lib/screens/booking_history_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // لتنسيق التواريخ

import 'package:smart_tourism_app/repositories/booking_repository.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/hotel_booking.dart';
import 'package:smart_tourism_app/models/product_order.dart';
import 'package:smart_tourism_app/models/pagination.dart';
import 'package:smart_tourism_app/models/hotel.dart'; // لبيانات الفندق داخل الحجز
import 'package:smart_tourism_app/models/product.dart'; // لبيانات المنتج داخل الطلب
import 'package:smart_tourism_app/models/product_order_item.dart'; // لعناصر طلب المنتج

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

enum BookingType { hotel, product } // لتمييز نوع الحجز/الطلب

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  _BookingHistoryPageState createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  bool _isLoading = false;
  String? _errorMessage;
  final List<dynamic> _allBookingsAndOrders = []; // قائمة موحدة
  int _hotelBookingPage = 1;
  int _productOrderPage = 1;
  bool _canLoadMoreHotelBookings = true;
  bool _canLoadMoreProductOrders = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCombinedHistory(isRefresh: true);
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
        (_canLoadMoreHotelBookings || _canLoadMoreProductOrders) &&
        !_isLoading) {
      _fetchCombinedHistory();
    }
  }

  Future<void> _fetchCombinedHistory({bool isRefresh = false}) async {
    if (isRefresh) {
      _allBookingsAndOrders.clear();
      _hotelBookingPage = 1;
      _productOrderPage = 1;
      _canLoadMoreHotelBookings = true;
      _canLoadMoreProductOrders = true;
    }

    if (!_canLoadMoreHotelBookings &&
        !_canLoadMoreProductOrders &&
        !isRefresh) {
      return; // No more data to load
    }

    // Set loading state only if widget is still mounted
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      if (isRefresh) _errorMessage = null;
    });

    try {
      final bookingRepo = Provider.of<BookingRepository>(
        context,
        listen: false,
      );

      // Fetch Hotel Bookings
      if (_canLoadMoreHotelBookings) {
        final hotelResponse = await bookingRepo.getMyHotelBookings(
          page: _hotelBookingPage,
        );
        if (mounted) {
          // Check mounted before setState
          setState(() {
            _allBookingsAndOrders.addAll(hotelResponse.data);
            _canLoadMoreHotelBookings =
                hotelResponse.meta.currentPage < hotelResponse.meta.lastPage;
            if (_canLoadMoreHotelBookings) _hotelBookingPage++;
          });
        }
      }

      // Fetch Product Orders
      if (_canLoadMoreProductOrders) {
        final productResponse = await bookingRepo.getMyProductOrders(
          page: _productOrderPage,
        );
        if (mounted) {
          // Check mounted before setState
          setState(() {
            _allBookingsAndOrders.addAll(productResponse.data);
            _canLoadMoreProductOrders =
                productResponse.meta.currentPage <
                productResponse.meta.lastPage;
            if (_canLoadMoreProductOrders) _productOrderPage++;
          });
        }
      }

      // Sort combined list by date (most recent first)
      if (mounted) {
        // Check mounted before setState/sorting
        setState(() {
          _allBookingsAndOrders.sort((a, b) {
            DateTime dateA;
            if (a is HotelBooking) {
              dateA = a.bookedAt!;
            } else if (a is ProductOrder) {
              dateA = a.orderDate;
            } else {
              // This case implies an unexpected type in the list; log or handle as needed.
              // For sorting purposes, we might consider such items "equal" or put them at the end.
              return 0;
            }

            DateTime dateB;
            if (b is HotelBooking) {
              dateB = b.bookedAt!;
            } else if (b is ProductOrder) {
              dateB = b.orderDate;
            } else {
              return 0;
            }
            return dateB.compareTo(dateA); // Descending order
          });
        });
      }
    } on ApiException catch (e) {
      print('API Error fetching history: ${e.statusCode} - ${e.message}');
      if (mounted) {
        // Check mounted before setState
        setState(() {
          _errorMessage = e.message;
        });
      }
    } on NetworkException catch (e) {
      print('Network Error fetching history: ${e.message}');
      if (mounted) {
        // Check mounted before setState
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      print('Unexpected Error fetching history: ${e.toString()}');
      if (mounted) {
        // Check mounted before setState
        setState(() {
          _errorMessage =
              'فشل في تحميل سجل الحجوزات والطلبات: ${e.toString()}'; // Add e.toString() for better debug
        });
      }
    } finally {
      if (mounted) {
        // Always reset loading state if mounted
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelHotelBooking(int bookingId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final bookingRepo = Provider.of<BookingRepository>(
        context,
        listen: false,
      );
      final cancelledBooking = await bookingRepo.cancelHotelBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إلغاء الحجز بنجاح: ${cancelledBooking.room?.hotel?.name ?? 'فندق'}',
            ),
            backgroundColor: kSuccessColor,
          ),
        );
        _fetchCombinedHistory(isRefresh: true); // Refresh list
      }
    } on ApiException catch (e) {
      print('API Error cancelling booking: ${e.statusCode} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إلغاء الحجز: ${e.message}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } catch (e) {
      print('Unexpected Error cancelling booking: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع أثناء إلغاء الحجز.'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return
    //  Directionality( // Removed Directionality here as it's typically set at MaterialApp level
    //   textDirection: TextDirection.rtl,
    //   child:
    Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير والحجوزات'),
        centerTitle: true,
        backgroundColor: kBackgroundColor,
        foregroundColor: kTextColor,
        elevation: 0,
      ),
      body:
          _isLoading &&
                  _allBookingsAndOrders
                      .isEmpty // Only show spinner if no data yet
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
                        onPressed: () => _fetchCombinedHistory(isRefresh: true),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
              : _allBookingsAndOrders.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 70,
                        color: kSecondaryTextColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'لا توجد فواتير أو حجوزات سابقة',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: kSecondaryTextColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'عندما تقوم بحجز فندق أو شراء منتج، ستظهر تفاصيلها هنا.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: kSecondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount:
                    _allBookingsAndOrders.length +
                    (_canLoadMoreHotelBookings || _canLoadMoreProductOrders
                        ? 1
                        : 0),
                itemBuilder: (context, index) {
                  if (index < _allBookingsAndOrders.length) {
                    final item = _allBookingsAndOrders[index];
                    if (item is HotelBooking) {
                      return _buildHotelBookingCard(context, item);
                    } else if (item is ProductOrder) {
                      return _buildProductOrderCard(context, item);
                    }
                    return const SizedBox.shrink(); // Fallback for unknown type
                  } else {
                    // Show loading indicator at the end of the list if more data can be loaded
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      ),
                    );
                  }
                },
              ),
      // ),
    );
  }

  // --- Widget for Hotel Booking Card ---
  Widget _buildHotelBookingCard(BuildContext context, HotelBooking booking) {
    final textTheme = Theme.of(context).textTheme;
    final String formattedCheckInDate = DateFormat(
      'yyyy/MM/dd',
    ).format(booking.checkInDate!);
    final String formattedCheckOutDate = DateFormat(
      'yyyy/MM/dd',
    ).format(booking.checkOutDate!);

    bool canCancel =
        booking.bookingStatus == 'PendingConfirmation' ||
        booking.bookingStatus == 'Confirmed';

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
                Icon(Icons.hotel_rounded, color: kPrimaryColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    booking.room?.hotel?.name ?? 'حجز فندق',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),
            _buildInfoRow(
              context,
              Icons.calendar_month,
              'تاريخ الدخول:',
              formattedCheckInDate,
            ),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'تاريخ الخروج:',
              formattedCheckOutDate,
            ),
            _buildInfoRow(
              context,
              Icons.bed_rounded,
              'نوع الغرفة:',
              booking.room?.type?.name ?? 'غير محدد',
            ),
            _buildInfoRow(
              context,
              Icons.person,
              'عدد البالغين:',
              booking.numAdults.toString(),
            ),
            if (booking.numChildren! > 0)
              _buildInfoRow(
                context,
                Icons.child_care,
                'عدد الأطفال:',
                booking.numChildren.toString(),
              ),
            _buildInfoRow(
              context,
              Icons.credit_card,
              'الحالة:',
              booking.bookingStatus!,
            ),
            _buildInfoRow(
              context,
              Icons.payments,
              'حالة الدفع:',
              booking.paymentStatus!,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'الإجمالي: ${booking.totalAmount?.toStringAsFixed(2) ?? 'غير محدد'} SYP',
                style: textTheme.headlineSmall?.copyWith(
                  color: kAccentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canCancel)
                  TextButton.icon(
                    onPressed: () {
                      _showCancelConfirmationDialog(
                        context,
                        booking.id,
                        booking.room?.hotel?.name ?? 'هذا الحجز',
                      );
                    },
                    icon: const Icon(Icons.cancel_outlined, color: kErrorColor),
                    label: Text(
                      'إلغاء الحجز',
                      style: textTheme.labelMedium?.copyWith(
                        color: kErrorColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showBookingDetailsDialog(context, booking);
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('عرض التفاصيل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget for Product Order Card ---
  Widget _buildProductOrderCard(BuildContext context, ProductOrder order) {
    final textTheme = Theme.of(context).textTheme;
    final String formattedOrderDate = DateFormat(
      'yyyy/MM/dd',
    ).format(order.orderDate);

    // Get the first product item for display, or a placeholder
    final ProductOrderItem? firstItem =
        order.items != null && order.items!.isNotEmpty
            ? order.items!.first
            : null;
    final String firstItemName = firstItem?.product?.name ?? 'منتجات متنوعة';
    final String? firstItemImage =
        firstItem
            ?.product
            ?.imageUrl; // Use the imageUrl getter from Product model

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      firstItemImage != null && firstItemImage.isNotEmpty
                          ? Image.network(
                            firstItemImage,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  width: 80,
                                  height: 80,
                                  color: kSurfaceColor,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: kSecondaryTextColor,
                                  ),
                                ),
                          )
                          : Container(
                            width: 80,
                            height: 80,
                            color: kSurfaceColor,
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: kSecondaryTextColor,
                              size: 40,
                            ),
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلب منتجات: ${firstItemName}',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.items?.length ?? 0} عنصر', // Null-safe length
                        style: textTheme.bodyMedium?.copyWith(
                          color: kSecondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'تاريخ الطلب:',
              formattedOrderDate,
            ),
            _buildInfoRow(
              context,
              Icons.local_shipping,
              'حالة الطلب:',
              order.orderStatus,
            ),
            _buildInfoRow(
              context,
              Icons.location_on,
              'الشحن إلى:',
              '${order.shippingCity ?? ''}, ${order.shippingAddressLine1 ?? ''}',
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'الإجمالي: ${order.totalAmount?.toStringAsFixed(2) ?? 'غير محدد'} SYP',
                style: textTheme.headlineSmall?.copyWith(
                  color: kAccentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تنزيل الفاتورة'),
                        backgroundColor: kSuccessColor,
                      ),
                    );
                    // TODO: Implement actual invoice download logic
                  },
                  icon: const Icon(Icons.download, color: kPrimaryColor),
                  label: Text(
                    'تنزيل الفاتورة',
                    style: textTheme.labelMedium?.copyWith(
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showProductOrderDetailsDialog(context, order);
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('عرض التفاصيل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Info Row Widget ---
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
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
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: kTextColor,
            ),
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

  // --- Dialog for Hotel Booking Details ---
  void _showBookingDetailsDialog(BuildContext context, HotelBooking booking) {
    final textTheme = Theme.of(context).textTheme;
    final String formattedCheckInDate = DateFormat(
      'yyyy/MM/dd',
    ).format(booking.checkInDate!);
    final String formattedCheckOutDate = DateFormat(
      'yyyy/MM/dd',
    ).format(booking.checkOutDate!);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            booking.room?.hotel?.name ?? 'تفاصيل الحجز',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogInfoRow(
                  textTheme,
                  'رقم الحجز:',
                  booking.id.toString(),
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'الفندق:',
                  booking.room?.hotel?.name ?? 'غير متوفر',
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'المدينة:',
                  booking.room?.hotel?.city ?? 'غير متوفر',
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'نوع الغرفة:',
                  booking.room?.type?.name ?? 'غير متوفر',
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'رقم الغرفة:',
                  booking.room?.roomNumber ?? 'غير متوفر',
                ),
                _buildDialogInfoRow(textTheme, 'الدخول:', formattedCheckInDate),
                _buildDialogInfoRow(
                  textTheme,
                  'الخروج:',
                  formattedCheckOutDate,
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'البالغين:',
                  booking.numAdults.toString(),
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'الأطفال:',
                  booking.numChildren.toString(),
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'حالة الحجز:',
                  booking.bookingStatus!,
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'حالة الدفع:',
                  booking.paymentStatus!,
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'المبلغ الإجمالي:',
                  '${booking.totalAmount?.toStringAsFixed(2) ?? 'غير محدد'} SYP',
                ),
                if (booking.specialRequests != null &&
                    booking.specialRequests!.isNotEmpty)
                  _buildDialogInfoRow(
                    textTheme,
                    'طلبات خاصة:',
                    booking.specialRequests!,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('إغلاق', style: textTheme.labelMedium),
            ),
          ],
        );
      },
    );
  }

  // --- Dialog for Product Order Details ---
  void _showProductOrderDetailsDialog(
    BuildContext context,
    ProductOrder order,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final String formattedOrderDate = DateFormat(
      'yyyy/MM/dd',
    ).format(order.orderDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'تفاصيل طلب المنتج',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogInfoRow(
                  textTheme,
                  'رقم الطلب:',
                  order.id.toString(),
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'تاريخ الطلب:',
                  formattedOrderDate,
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'حالة الطلب:',
                  order.orderStatus,
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'المبلغ الإجمالي:',
                  '${order.totalAmount?.toStringAsFixed(2) ?? 'غير محدد'} SYP',
                ),
                const Divider(height: 20, thickness: 0.5),
                Text(
                  'تفاصيل الشحن:',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'العنوان 1:',
                  order.shippingAddressLine1 ?? 'غير متوفر',
                ),
                if (order.shippingAddressLine2 != null &&
                    order.shippingAddressLine2!.isNotEmpty)
                  _buildDialogInfoRow(
                    textTheme,
                    'العنوان 2:',
                    order.shippingAddressLine2!,
                  ),
                _buildDialogInfoRow(
                  textTheme,
                  'المدينة:',
                  order.shippingCity ?? 'غير متوفر',
                ),
                _buildDialogInfoRow(
                  textTheme,
                  'البلد:',
                  order.shippingCountry ?? 'غير متوفر',
                ),
                const Divider(height: 20, thickness: 0.5),
                Text(
                  'عناصر الطلب:',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (order.items != null &&
                    order
                        .items!
                        .isNotEmpty) // Check if items list is not null and not empty
                  ...order.items!
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.product?.name ?? 'منتج'} (x${item.quantity})',
                                  style: textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${(item.priceAtPurchase ?? 0) * item.quantity} SYP',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList()
                else
                  Text(
                    'لا توجد عناصر في هذا الطلب.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: kSecondaryTextColor,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('إغلاق', style: textTheme.labelMedium),
            ),
          ],
        );
      },
    );
  }

  // Helper for dialog rows
  Widget _buildDialogInfoRow(TextTheme textTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // --- Confirmation Dialog for Cancellation ---
  void _showCancelConfirmationDialog(
    BuildContext context,
    int bookingId,
    String itemName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('تأكيد الإلغاء', textAlign: TextAlign.center),
          content: Text(
            'هل أنت متأكد أنك تريد إلغاء $itemName؟',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text('لا', style: Theme.of(context).textTheme.labelMedium),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _cancelHotelBooking(bookingId); // Proceed with cancellation
              },
              style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
              child: Text(
                'نعم، إلغاء',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        );
      },
    );
  }
}
