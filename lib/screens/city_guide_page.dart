// lib/screens/city_guide_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // لفتح Google Maps أو تطبيقات الملاحة

import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/utils/api_exceptions.dart';
import 'package:smart_tourism_app/models/tourist_site.dart'; // Model for Tourist Sites
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

class CityGuidePage extends StatefulWidget {
  const CityGuidePage({super.key});

  @override
  State<CityGuidePage> createState() => _CityGuidePageState();
}

class _CityGuidePageState extends State<CityGuidePage> {
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  List<TouristSite> _touristSites = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Initial camera position (can be set to a default city or user's current location)
  static const LatLng _initialCameraPosition = LatLng(34.8021, 38.9968); // Center of Syria approximate

  @override
  void initState() {
    super.initState();
    _fetchTouristSites();
  }

  Future<void> _fetchTouristSites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tourismRepo = Provider.of<TourismRepository>(context, listen: false);
      // Fetch all tourist sites (or paginate and load more as needed)
      // For a guide map, fetching all might be necessary to populate markers
      // Consider adding city filtering if needed for a specific city guide
      final PaginatedResponse<TouristSite> response = await tourismRepo.getTouristSites(page: 1, city: null); // You can add city filter here

      setState(() {
        _touristSites = response.data.where((site) => site.latitude != null && site.longitude != null).toList();
        _setMarkers(); // Populate markers after fetching sites
        if (_touristSites.isNotEmpty && mapController != null) {
          // Animate camera to the first site or a calculated center
          mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(
              _boundsFromLatLngList(_touristSites.map((s) => LatLng(s.latitude!, s.longitude!)).toList()),
              50.0, // padding
            ),
          );
        }
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

  void _setMarkers() {
    setState(() {
      _markers = _touristSites.map((site) {
        return Marker(
          markerId: MarkerId(site.id.toString()),
          position: LatLng(site.latitude!, site.longitude!),
          infoWindow: InfoWindow(
            title: site.name,
            snippet: site.locationText ?? site.city,
            onTap: () {
              // TODO: Navigate to Tourist Site Details Page
              print('Tapped InfoWindow for ${site.name}');
            },
          ),
          onTap: () {
            // Optional: Highlight item in list when marker is tapped
            print('Tapped Marker for ${site.name}');
          }
        );
      }).toSet();
    });
  }

  // Helper to calculate bounds for fitting all markers
  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  // Function to open Google Maps or other navigation apps
  Future<void> _launchMapsUrl(double lat, double lon, String label) async {
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon&query_place_id=$label';
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
      // Fallback for web or other platforms
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل المدينة'),
        centerTitle: true,
        backgroundColor: kBackgroundColor,
        foregroundColor: kTextColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : _errorMessage != null
                    ? Center(child: Text('خطأ في تحميل الخريطة: $_errorMessage', textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: kErrorColor)))
                    : GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: _initialCameraPosition,
                          zoom: 7, // Wider zoom to show more of Syria initially
                        ),
                        onMapCreated: (controller) {
                          mapController = controller;
                          if (_touristSites.isNotEmpty) {
                            // If sites are already loaded, animate camera to fit them
                            mapController!.animateCamera(
                              CameraUpdate.newLatLngBounds(
                                _boundsFromLatLngList(_touristSites.map((s) => LatLng(s.latitude!, s.longitude!)).toList()),
                                50.0,
                              ),
                            );
                          }
                        },
                        markers: _markers,
                        myLocationButtonEnabled: true,
                        myLocationEnabled: true,
                      ),
          ),
          Expanded(
            flex: 3,
            child: _isLoading && _touristSites.isEmpty
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : _errorMessage != null
                    ? Center(child: Text('خطأ في تحميل المواقع: $_errorMessage', textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: kErrorColor)))
                    : _touristSites.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off_outlined, size: 60, color: kSecondaryTextColor.withOpacity(0.5)),
                                const SizedBox(height: 15),
                                Text(
                                  'لا توجد مواقع سياحية لعرضها حالياً.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _touristSites.length,
                            itemBuilder: (context, index) {
                              final site = _touristSites[index];
                              return _buildPlaceCard(context, site);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // --- Place Card Widget (for list) ---
  Widget _buildPlaceCard(BuildContext context, TouristSite site) {
    final textTheme = Theme.of(context).textTheme;

    IconData _getSiteTypeIcon(String? categoryName) {
      if (categoryName == null) return Icons.place_outlined;
      switch (categoryName.toLowerCase()) {
        case 'historical': return Icons.account_balance_outlined;
        case 'natural': return Icons.nature_people_outlined;
        case 'religious': return Icons.church_outlined; // or Icons.mosque_outlined based on context
        case 'museums': return Icons.museum_outlined;
        case 'shopping': return Icons.shopping_bag_outlined;
        case 'restaurant': return Icons.restaurant_menu_outlined; // If restaurants are sites
        default: return Icons.place_outlined;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Animate map camera to selected place
          if (site.latitude != null && site.longitude != null && mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(site.latitude!, site.longitude!), 15.0),
            );
          }
          // TODO: Navigate to Tourist Site Details Page if desired
          print('Tapped on site: ${site.name}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getSiteTypeIcon(site.category?.name), color: kPrimaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      site.name??'',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (site.locationText != null && site.locationText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 40.0), // Align with icon
                  child: Text(
                    site.locationText!,
                    style: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (site.latitude != null && site.longitude != null)
                    TextButton.icon(
                      onPressed: () {
                        _launchMapsUrl(site.latitude!, site.longitude!, site.name??'');
                      },
                      icon: const Icon(Icons.directions_outlined, size: 20, color: kPrimaryColor),
                      label: Text('اتجاهات', style: textTheme.labelMedium?.copyWith(color: kPrimaryColor)),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to Tourist Site Details Page
                      print('View details for: ${site.name}');
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
      ),
    );
  }
}