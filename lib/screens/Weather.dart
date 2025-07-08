// lib/screens/Weather.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl; // لتنسيق التاريخ والوقت

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

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  // TODO: استبدل 'your_api_key' بمفتاح API الخاص بك من OpenWeatherMap
  final String apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  String _selectedCity = 'دمشق'; // Default city
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _cities = ['دمشق', 'حلب', 'حمص', 'اللاذقية', 'طرطوس', 'حماة', 'السويداء', 'دير الزور']; // Add more cities as needed

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (apiKey == 'YOUR_OPENWEATHERMAP_API_KEY' || apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء إدخال مفتاح API الخاص بـ OpenWeatherMap في الكود.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url =
          'https://api.openweathermap.org/data/2.5/forecast?q=$_selectedCity&units=metric&lang=ar&appid=$apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
        });
      } else {
        final errorBody = json.decode(response.body);
        _errorMessage = errorBody['message'] ?? 'فشل في تحميل بيانات الطقس.';
      }
    } catch (e) {
      _errorMessage = 'تعذر الاتصال بخدمة الطقس: ${e.toString()}';
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
          title: Text('حالة الطقس'),
          centerTitle: true,
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
          actions: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                icon: const Icon(Icons.location_on_outlined, color: kPrimaryColor),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCity = newValue;
                    });
                    _fetchWeather();
                  }
                },
                items: _cities.map<DropdownMenuItem<String>>((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city, style: textTheme.bodyLarge?.copyWith(color: kTextColor)),
                  );
                }).toList(),
                dropdownColor: kSurfaceColor, // Background for dropdown menu
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off_outlined, size: 60, color: kErrorColor),
                          const SizedBox(height: 15),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(color: kErrorColor),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _fetchWeather,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _weatherData == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wb_sunny_outlined, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                            const SizedBox(height: 20),
                            Text(
                              'لا توجد بيانات طقس متاحة حالياً.',
                              style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildCurrentWeather(textTheme),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildWeeklyForecast(textTheme),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildCurrentWeather(TextTheme textTheme) {
    final current = _weatherData!['list'][0];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "الطقس الحالي في $_selectedCity",
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.network(
                  'https://openweathermap.org/img/wn/${current['weather'][0]['icon']}@4x.png', // Higher resolution icon
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.cloud_off, size: 80, color: kSecondaryTextColor),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${current['main']['temp'].round()}°C",
                      style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: kTextColor),
                    ),
                    Text(
                      current['weather'][0]['description'],
                      style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(textTheme, Icons.thermostat_outlined, 'أقصى', '${current['main']['temp_max'].round()}°C'),
                _buildWeatherDetail(textTheme, Icons.thermostat_sharp, 'أدنى', '${current['main']['temp_min'].round()}°C'),
                _buildWeatherDetail(textTheme, Icons.opacity_outlined, 'الرطوبة', '${current['main']['humidity']}%'),
                _buildWeatherDetail(textTheme, Icons.wind_power_outlined, 'الرياح', '${current['wind']['speed'].round()} م/ث'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(TextTheme textTheme, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: kPrimaryColor),
        const SizedBox(height: 4),
        Text(label, style: textTheme.bodySmall),
        Text(value, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }


  Widget _buildWeeklyForecast(TextTheme textTheme) {
    // OpenWeatherMap's 5-day forecast provides data every 3 hours (8 entries per day).
    // We want daily forecast, so we take one entry per day, typically at noon or 12:00 UTC.
    // Group by day to ensure we get distinct days and not just 3-hour intervals.
    final Map<String, dynamic> dailyForecasts = {};
    for (var forecast in _weatherData!['list']) {
      final DateTime date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000).toLocal();
      final String formattedDate = intl.DateFormat('yyyy-MM-dd').format(date);
      // Take the first entry for each day, or an entry closest to noon
      if (!dailyForecasts.containsKey(formattedDate)) {
        dailyForecasts[formattedDate] = forecast;
      }
    }

    final List forecastList = dailyForecasts.values.toList();
    // Sort by date to ensure correct order
    forecastList.sort((a, b) => DateTime.fromMillisecondsSinceEpoch(a['dt'] * 1000)
        .compareTo(DateTime.fromMillisecondsSinceEpoch(b['dt'] * 1000)));

    return ListView.builder(
      itemCount: forecastList.length,
      itemBuilder: (context, index) {
        final dayData = forecastList[index];
        final DateTime forecastDate = DateTime.fromMillisecondsSinceEpoch(dayData['dt'] * 1000).toLocal();
        final String dayName = intl.DateFormat('EEEE', 'ar').format(forecastDate); // Full day name in Arabic
        final String formattedDate = intl.DateFormat('dd/MM', 'ar').format(forecastDate); // Date e.g., 24/05

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Image.network(
              'https://openweathermap.org/img/wn/${dayData['weather'][0]['icon']}@2x.png',
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.cloud_off, size: 50, color: kSecondaryTextColor),
            ),
            title: Text(
              '$dayName, $formattedDate',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kPrimaryColor),
              textAlign: TextAlign.right,
            ),
            subtitle: Text(
              dayData['weather'][0]['description'],
              style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor),
              textAlign: TextAlign.right,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${dayData['main']['temp'].round()}°C',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'يشعر بـ ${dayData['main']['feels_like'].round()}°C',
                  style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}