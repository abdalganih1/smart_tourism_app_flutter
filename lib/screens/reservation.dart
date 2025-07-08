// lib/screens/reservation.dart (أو lib/screens/HotelBookingPage.dart)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl; // لتنسيق التواريخ

import 'package:smart_tourism_app/repositories/booking_repository.dart';
import 'package:smart_tourism_app/repositories/hotel_repository.dart'; // <--- استخدام HotelRepository لجلب الغرف
import 'package:smart_tourism_app/models/hotel_room.dart'; // HotelRoom model
import 'package:smart_tourism_app/models/hotel.dart'; // Hotel model (for hotel details within room)
import 'package:smart_tourism_app/models/hotel_booking.dart'; // HotelBooking model
import 'package:smart_tourism_app/utils/api_exceptions.dart';

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

class HotelBookingPage extends StatefulWidget {
  // يمكن أن تستقبل id الغرفة أو id الفندق
  final int? roomId; // إذا كان المستخدم قد اختار غرفة بالفعل
  final int? hotelId; // إذا كان المستخدم يريد رؤية الغرف المتاحة في فندق معين للحجز

  const HotelBookingPage({super.key, this.roomId, this.hotelId});

  @override
  _HotelBookingPageState createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // Form Controllers
  final TextEditingController _numAdultsController = TextEditingController(text: '1');
  final TextEditingController _numChildrenController = TextEditingController(text: '0');
  final TextEditingController _specialRequestsController = TextEditingController();

  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  HotelRoom? _selectedRoom; // الغرفة التي سيتم حجزها
  List<HotelRoom> _availableRooms = []; // قائمة الغرف المتاحة للاختيار منها

  // For UI selection, not sent to API as per your schema
  String _selectedPaymentMethod = 'بطاقة ائتمانية';
  final List<String> _paymentMethods = ['بطاقة ائتمانية', 'الدفع عند الوصول'];


  @override
  void initState() {
    super.initState();
    // جلب تفاصيل الغرفة المحددة مباشرة
    if (widget.roomId != null) {
      _fetchRoomDetails(widget.roomId!);
    }
    // جلب جميع الغرف لفندق معين للسماح بالاختيار
    else if (widget.hotelId != null) {
      _fetchHotelRooms(widget.hotelId!);
    }
    // إذا لم يتم تمرير لا roomId ولا hotelId، يتم عرض خطأ
    else {
      _errorMessage = 'يجب تحديد الغرفة أو الفندق للحجز.';
    }
  }

  @override
  void dispose() {
    _numAdultsController.dispose();
    _numChildrenController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  // يجلب تفاصيل غرفة محددة (إذا تم تمرير roomId)
  Future<void> _fetchRoomDetails(int roomId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final hotelRepo = Provider.of<HotelRepository>(context, listen: false);
      // API has /hotels/{hotel}/rooms to list rooms, but no direct /rooms/{id} endpoint in provided OpenAPI.
      // Assuming getHotelRooms can fetch rooms for a specific hotel and then filter by ID.
      // A more direct API call would be: await hotelRepo.getRoomDetails(roomId); if such endpoint existed.
      final List<HotelRoom> rooms = await hotelRepo.getHotelRooms(
          widget.hotelId ?? roomId); // If no hotelId, try to fetch rooms for the room's hotel ID
      final room = rooms.firstWhere((r) => r.id == roomId, orElse: () => throw Exception('Room not found in list.'));
      setState(() {
        _selectedRoom = room;
        _availableRooms = rooms; // Populate available rooms in case user wants to change
      });
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'فشل تحميل تفاصيل الغرفة: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // يجلب جميع الغرف لفندق معين (إذا تم تمرير hotelId)
  Future<void> _fetchHotelRooms(int hotelId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final hotelRepo = Provider.of<HotelRepository>(context, listen: false);
      final rooms = await hotelRepo.getHotelRooms(hotelId);
      setState(() {
        _availableRooms = rooms;
        if (rooms.isNotEmpty) {
          _selectedRoom = rooms.first; // Select first room by default if available
        } else {
          _errorMessage = 'لا توجد غرف متاحة لهذا الفندق.';
        }
      });
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'فشل تحميل غرف الفندق: ${e.toString()}';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isCheckIn}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)), // Start from tomorrow
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2), // Max 2 years from now
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: kTextColor, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = pickedDate;
          // إذا كان تاريخ الخروج قبل تاريخ الدخول، يتم إعادة تعيينه
          if (_checkOutDate != null && _checkOutDate!.isBefore(_checkInDate!)) {
            _checkOutDate = null;
          }
        } else {
          _checkOutDate = pickedDate;
          // إذا كان تاريخ الدخول بعد تاريخ الخروج، يتم إعادة تعيينه
          if (_checkInDate != null && _checkOutDate!.isBefore(_checkInDate!)) {
            _checkInDate = null;
          }
        }
      });
    }
  }

  void _placeBooking() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة جميع الحقول المطلوبة بشكل صحيح.'), backgroundColor: kErrorColor),
      );
      return;
    }
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار غرفة للحجز.'), backgroundColor: kErrorColor),
      );
      return;
    }
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار تاريخ الدخول والخروج.'), backgroundColor: kErrorColor),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookingRepo = Provider.of<BookingRepository>(context, listen: false);
      // Prepare bookingData according to StoreHotelBookingRequest schema
      final bookingData = {
        'room_id': _selectedRoom!.id,
        'check_in_date': intl.DateFormat('yyyy-MM-dd').format(_checkInDate!),
        'check_out_date': intl.DateFormat('yyyy-MM-dd').format(_checkOutDate!),
        'num_adults': int.parse(_numAdultsController.text),
        'num_children': int.parse(_numChildrenController.text),
        'special_requests': _specialRequestsController.text.trim().isNotEmpty ? _specialRequestsController.text.trim() : null,
      };

      final HotelBooking newBooking = await bookingRepo.placeHotelBooking(bookingData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تأكيد حجزك بنجاح!'), backgroundColor: kSuccessColor),
        );
        _showBookingConfirmationDialog(newBooking);
      }
    } on ValidationException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'خطأ في التحقق من البيانات.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: kErrorColor),
      );
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'فشل في إتمام الحجز.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: kErrorColor),
      );
    } on NetworkException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'لا يوجد اتصال بالإنترنت.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: kErrorColor),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع: ${e.toString()}.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: kErrorColor),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBookingConfirmationDialog(HotelBooking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تم تأكيد الحجز', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: kSuccessColor, size: 80),
            const SizedBox(height: 16),
            Text(
              'شكراً لك! تم حجز غرفتك بنجاح.\nرقم الحجز: ${booking.id}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            // Placeholder for QR Code (API might return a QR URL or you generate it)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_2_outlined, size: 100, color: kPrimaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'تفاصيل الحجز أرسلت إلى بريدك الإلكتروني.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen (e.g., HotelDetailsPage)
            },
            child: const Text('موافق'),
          ),
        ],
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
          title: Text(_selectedRoom?.hotel?.name ?? 'حجز غرفة'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: _isLoading && _selectedRoom == null // Show spinner if room details are loading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _errorMessage != null && _selectedRoom == null // Show error if initial load failed
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
                            onPressed: () {
                              if (widget.roomId != null) _fetchRoomDetails(widget.roomId!);
                              else if (widget.hotelId != null) _fetchHotelRooms(widget.hotelId!);
                              else _errorMessage = 'يجب تحديد الغرفة أو الفندق للحجز.'; // Fallback
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _selectedRoom == null // Show empty state if no room could be loaded
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bed_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                              const SizedBox(height: 20),
                              Text(
                                'لا يمكن الحجز بدون اختيار غرفة.',
                                style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'الرجاء العودة لصفحة الفندق واختيار غرفة متاحة.',
                                style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفاصيل الغرفة المختارة:',
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              // Display selected room details (as a card)
                              _buildSelectedRoomCard(textTheme),
                              const SizedBox(height: 24),

                              // Room selection dropdown (if hotelId was provided)
                              if (widget.hotelId != null && _availableRooms.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'اختيار غرفة أخرى:',
                                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<HotelRoom>(
                                      value: _selectedRoom,
                                      decoration: const InputDecoration(
                                        labelText: 'اختر غرفة',
                                        prefixIcon: Icon(Icons.bed_outlined),
                                      ),
                                      items: _availableRooms.map((room) {
                                        return DropdownMenuItem(
                                          value: room,
                                          child: Text('${room.roomNumber} - ${room.type?.name ?? 'غرفة'} (${room.pricePerNight?.toStringAsFixed(0)} SYP)', style: textTheme.bodyLarge),
                                        );
                                      }).toList(),
                                      onChanged: (room) {
                                        setState(() {
                                          _selectedRoom = room;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),

                              Text(
                                'معلومات الحجز:',
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              // Number of Adults
                              TextFormField(
                                controller: _numAdultsController,
                                decoration: const InputDecoration(
                                  labelText: 'عدد البالغين',
                                  hintText: 'الحد الأدنى 1',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) < 1) {
                                    return 'الرجاء إدخال عدد صحيح للبالغين (1 على الأقل)';
                                  }
                                  if (_selectedRoom != null && int.parse(value) > _selectedRoom!.maxOccupancy!) {
                                    return 'عدد البالغين يتجاوز سعة الغرفة القصوى (${_selectedRoom!.maxOccupancy})';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Number of Children
                              TextFormField(
                                controller: _numChildrenController,
                                decoration: const InputDecoration(
                                  labelText: 'عدد الأطفال',
                                  hintText: 'إذا كان هناك أطفال',
                                  prefixIcon: Icon(Icons.child_care_outlined),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) < 0) {
                                    return 'الرجاء إدخال عدد صحيح للأطفال (0 أو أكثر)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              Text(
                                'التواريخ:',
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              // Check-in Date
                              _buildDateSelectionField(
                                textTheme,
                                'تاريخ الدخول',
                                _checkInDate,
                                () => _selectDate(context, isCheckIn: true),
                              ),
                              const SizedBox(height: 16),
                              // Check-out Date
                              _buildDateSelectionField(
                                textTheme,
                                'تاريخ الخروج',
                                _checkOutDate,
                                () => _selectDate(context, isCheckIn: false),
                              ),
                              const SizedBox(height: 24),

                              Text(
                                'ملاحظات إضافية:',
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              // Special Requests
                              TextFormField(
                                controller: _specialRequestsController,
                                decoration: const InputDecoration(
                                  labelText: 'طلبات خاصة (اختياري)',
                                  hintText: 'مثلاً: سرير إضافي، غرفة هادئة، إطلالة معينة...',
                                  prefixIcon: Icon(Icons.note_alt_outlined),
                                ),
                                maxLines: 3,
                                minLines: 1,
                              ),
                              const SizedBox(height: 24),

                              Text(
                                'طريقة الدفع (للمعلومات فقط):', // Payment method is for UI only per OpenAPI
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedPaymentMethod,
                                items: _paymentMethods
                                    .map(
                                      (method) => DropdownMenuItem(
                                        value: method,
                                        child: Text(method, style: textTheme.bodyLarge),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'طريقة الدفع',
                                  prefixIcon: const Icon(Icons.payment_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: kSurfaceColor,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Confirm Booking Button
                              SizedBox(
                                width: double.infinity,
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                                    : ElevatedButton.icon(
                                        onPressed: _placeBooking,
                                        icon: const Icon(Icons.check_circle_outline),
                                        label: Text('تأكيد الحجز', style: textTheme.labelLarge),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  // Helper for displaying selected room details
  Widget _buildSelectedRoomCard(TextTheme textTheme) {
    if (_selectedRoom == null) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedRoom!.type?.name ?? 'غرفة',
              style: textTheme.headlineSmall?.copyWith(color: kPrimaryColor),
            ),
            Text(
              'رقم الغرفة: ${_selectedRoom!.roomNumber}',
              style: textTheme.bodyLarge,
            ),
            Text(
              'السعر لليلة: ${_selectedRoom!.pricePerNight?.toStringAsFixed(2) ?? 'غير محدد'} SYP',
              style: textTheme.bodyLarge,
            ),
            Text(
              'الحد الأقصى للإشغال: ${_selectedRoom!.maxOccupancy ?? 'غير محدد'} بالغ',
              style: textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  // Helper for date selection fields
  Widget _buildDateSelectionField(TextTheme textTheme, String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              hintText: 'اختر التاريخ',
              prefixIcon: Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: kSurfaceColor,
            ),
            baseStyle: textTheme.bodyLarge,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date == null ? 'لم يتم الاختيار' : intl.DateFormat('yyyy/MM/dd').format(date),
                  style: textTheme.bodyLarge?.copyWith(color: date == null ? kSecondaryTextColor : kTextColor),
                ),
                Icon(Icons.arrow_drop_down, color: kSecondaryTextColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}