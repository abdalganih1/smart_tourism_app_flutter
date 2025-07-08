// lib/screens/Planner.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

class TripPlannerPage extends StatefulWidget {
  const TripPlannerPage({super.key});

  @override
  _TripPlannerPageState createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  List<String> places = [];
  final TextEditingController _placeController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedPlaces = prefs.getString('trip_places_list'); // Use a unique key
      if (savedPlaces != null) {
        setState(() {
          places = List<String>.from(json.decode(savedPlaces));
        });
      }
    } catch (e) {
      print('Error loading places: $e');
      // Optionally show an error message
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePlaces() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('trip_places_list', json.encode(places));
    } catch (e) {
      print('Error saving places: $e');
      // Optionally show an error message
    }
  }

  void _addPlace() {
    if (_placeController.text.trim().isNotEmpty) {
      setState(() {
        places.add(_placeController.text.trim());
        _placeController.clear();
      });
      _savePlaces();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم مكان صالح.'), backgroundColor: kAccentColor),
      );
    }
  }

  void _removePlace(int index) {
    setState(() {
      places.removeAt(index);
    });
    _savePlaces();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المكان من الخطة.'), backgroundColor: kSuccessColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مخطط الرحلات'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _placeController,
                      decoration: InputDecoration(
                        hintText: 'أضف مكاناً جديداً...',
                        prefixIcon: const Icon(Icons.add_location_alt_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: kSurfaceColor,
                      ),
                      textAlign: TextAlign.right, // RTL alignment
                      textDirection: TextDirection.rtl, // RTL text direction
                      onSubmitted: (_) => _addPlace(), // Add on enter
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56, // Match TextField height
                    child: ElevatedButton(
                      onPressed: _addPlace,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text('أضف', style: textTheme.labelLarge),
                    ),
                  ),
                ],
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : Expanded(
                    child: places.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_calendar_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                                  const SizedBox(height: 20),
                                  Text(
                                    'لا توجد أماكن في خطتك بعد',
                                    style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ابدأ بإضافة الأماكن التي تود زيارتها في رحلتك.',
                                    style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: places.length,
                            itemBuilder: (context, index) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: kPrimaryColor.withOpacity(0.1),
                                    child: Text('${index + 1}', style: textTheme.titleSmall?.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(
                                    places[index],
                                    style: textTheme.titleMedium,
                                    textAlign: TextAlign.right, // RTL alignment
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete_outline, color: kErrorColor),
                                    onPressed: () => _removePlace(index),
                                    tooltip: 'إزالة',
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              );
                            },
                          ),
                  ),
            if (places.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إنشاء تقرير الخطة بنجاح.'), backgroundColor: kSuccessColor),
                      );
                      // TODO: Implement generate report / share plan logic
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('مشاركة الخطة / إنشاء تقرير'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}