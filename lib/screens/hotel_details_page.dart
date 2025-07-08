// lib/screens/hotel_details_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // لعرض التقييمات
import 'package:url_launcher/url_launcher.dart'; // لفتح روابط الاتصال والخرائط

import 'package:smart_tourism_app/repositories/hotel_repository.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/hotel.dart'; // Hotel model
import 'package:smart_tourism_app/models/hotel_room.dart'; // HotelRoom model
import 'package:smart_tourism_app/screens/reservation.dart'; // Import the HotelBookingPage

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

class HotelDetailsPage extends StatefulWidget {
  final int hotelId;
  const HotelDetailsPage({super.key, required this.hotelId});

  @override
  State<HotelDetailsPage> createState() => _HotelDetailsPageState();
}

class _HotelDetailsPageState extends State<HotelDetailsPage> {
  Hotel? _hotel;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHotelDetails();
  }

  Future<void> _fetchHotelDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final hotelRepo = Provider.of<HotelRepository>(context, listen: false);
      final hotel = await hotelRepo.getHotelDetails(widget.hotelId);
      setState(() {
        _hotel = hotel;
      });
    } on ApiException catch (e) {
      print('API Error fetching hotel details: ${e.statusCode} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } on NetworkException catch (e) {
      print('Network Error fetching hotel details: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      print('Unexpected Error fetching hotel details: ${e.toString()}');
      setState(() {
        _errorMessage = 'فشل في تحميل تفاصيل الفندق.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to launch phone dialer
  Future<void> _launchPhoneDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الاتصال بالرقم.'), backgroundColor: kErrorColor),
      );
    }
  }

  // Function to launch email client
  Future<void> _launchEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق البريد الإلكتروني.'), backgroundColor: kErrorColor),
      );
    }
  }

  // Function to launch maps app
  Future<void> _launchMapsUrl(double lat, double lon, String label) async {
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon&query_place_id=$label';
    final Uri launchUri = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الخرائط.'), backgroundColor: kErrorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_hotel?.name ?? 'تفاصيل الفندق'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: _isLoading && _hotel == null
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
                          ElevatedButton(onPressed: _fetchHotelDetails, child: const Text('إعادة المحاولة')),
                        ],
                      ),
                    ),
                  )
                : _hotel == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hotel_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                              const SizedBox(height: 20),
                              Text(
                                'الفندق غير موجود أو تم حذفه.',
                                style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'الرجاء التحقق من الرابط أو العودة لصفحة الفنادق.',
                                style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hotel Image (Large)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _hotel!.imageUrl ?? 'https://via.placeholder.com/600x400?text=Hotel+Image',
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: double.infinity,
                                  height: 250,
                                  color: kSurfaceColor,
                                  child: const Center(child: Icon(Icons.broken_image_outlined, color: kSecondaryTextColor, size: 80)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Hotel Name & Rating
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    _hotel!.name!,
                                    style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_hotel!.starRating != null && _hotel!.starRating! > 0)
                                  RatingBarIndicator(
                                    rating: _hotel!.starRating!.toDouble(),
                                    itemBuilder: (context, index) => Icon(
                                      Icons.star_rounded,
                                      color: kAccentColor,
                                    ),
                                    itemCount: 5,
                                    itemSize: 28.0,
                                    direction: Axis.horizontal,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Hotel Description
                            if (_hotel!.description != null && _hotel!.description!.isNotEmpty)
                              Text(
                                _hotel!.description!,
                                style: textTheme.bodyLarge?.copyWith(color: kTextColor),
                              ),
                            const SizedBox(height: 20),

                            // Location & Contact Info
                            _buildInfoSection(
                              context,
                              'الموقع والتواصل',
                              [
                                if (_hotel!.addressLine1 != null && _hotel!.addressLine1!.isNotEmpty)
                                  _buildInfoRow(textTheme, Icons.location_on_outlined, 'العنوان:', '${_hotel!.addressLine1!}, ${_hotel!.city ?? ''}, ${_hotel!.country ?? ''}'),
                                if (_hotel!.contactPhone != null && _hotel!.contactPhone!.isNotEmpty)
                                  _buildClickableInfoRow(textTheme, Icons.phone_outlined, 'الهاتف:', _hotel!.contactPhone!, () => _launchPhoneDialer(_hotel!.contactPhone!)),
                                if (_hotel!.contactEmail != null && _hotel!.contactEmail!.isNotEmpty)
                                  _buildClickableInfoRow(textTheme, Icons.email_outlined, 'البريد الإلكتروني:', _hotel!.contactEmail!, () => _launchEmail(_hotel!.contactEmail!)),
                                if (_hotel!.latitude != null && _hotel!.longitude != null)
                                  _buildClickableInfoRow(textTheme, Icons.map_outlined, 'عرض على الخريطة', 'اضغط هنا', () => _launchMapsUrl(_hotel!.latitude!, _hotel!.longitude!, _hotel!.name!)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Rooms Section
                            _buildRoomsSection(textTheme),
                            const SizedBox(height: 20),

                            // TODO: Add sections for Ratings/Reviews and Comments later if API supports
                            // _buildReviewsSection(textTheme),
                            // _buildCommentsSection(textTheme),
                          ],
                        ),
                      ),
      ),
    );
  }

  // Helper for info sections
  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
        const Divider(height: 16, thickness: 0.5),
        ...children,
      ],
    );
  }

  // Helper for static info rows
  Widget _buildInfoRow(TextTheme textTheme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kSecondaryTextColor),
          const SizedBox(width: 8),
          Text(label, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyLarge?.copyWith(color: kTextColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for clickable info rows (phone, email, map)
  Widget _buildClickableInfoRow(TextTheme textTheme, IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: kPrimaryColor),
            const SizedBox(width: 8),
            Text(label, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            Expanded(
              child: Text(
                value,
                style: textTheme.bodyLarge?.copyWith(color: kPrimaryColor, decoration: TextDecoration.underline),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Rooms Section ---
  Widget _buildRoomsSection(TextTheme textTheme) {
    if (_hotel!.rooms == null || _hotel!.rooms!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الغرف المتاحة',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          const Divider(height: 16, thickness: 0.5),
          const SizedBox(height: 8),
          Text(
            'لا توجد غرف متاحة حالياً لهذا الفندق.',
            style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الغرف المتاحة',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
        ),
        const Divider(height: 16, thickness: 0.5),
        ListView.builder(
          shrinkWrap: true, // Important for nested list views
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling of inner list
          itemCount: _hotel!.rooms!.length,
          itemBuilder: (context, index) {
            final room = _hotel!.rooms![index];
            return _buildRoomCard(context, room);
          },
        ),
      ],
    );
  }

  // --- Room Card Widget ---
  Widget _buildRoomCard(BuildContext context, HotelRoom room) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: () {
          // Navigate to booking page for this specific room
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HotelBookingPage(roomId: room.id, hotelId: room.hotelId), // Pass hotelId too for context
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.type?.name ?? 'نوع الغرفة',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                room.description ?? 'لا يوجد وصف متاح.',
                style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم الغرفة: ${room.roomNumber}',
                        style: textTheme.bodySmall,
                      ),
                      Text(
                        'السعة القصوى: ${room.maxOccupancy ?? 'غير محدد'} بالغ',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    '${room.pricePerNight?.toStringAsFixed(0)} SYP / ليلة',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to booking page for this specific room
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HotelBookingPage(roomId: room.id, hotelId: room.hotelId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.book_online_outlined, size: 18),
                  label: const Text('احجز هذه الغرفة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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