// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Import services and repositories
import 'package:smart_tourism_app/services/api_service.dart';
import 'package:smart_tourism_app/repositories/auth_repository.dart';
import 'package:smart_tourism_app/repositories/tourism_repository.dart';
import 'package:smart_tourism_app/repositories/booking_repository.dart';
import 'package:smart_tourism_app/repositories/shopping_cart_repository.dart';
import 'package:smart_tourism_app/repositories/interaction_repository.dart';
import 'package:smart_tourism_app/repositories/user_repository.dart';
import 'package:smart_tourism_app/repositories/hotel_repository.dart'; // <--- Add this import

// Import core screens
import 'package:smart_tourism_app/screens/login_screen.dart';
import 'package:smart_tourism_app/screens/main_screen.dart';

// Import all pages that might be navigated to directly (e.g., from drawer)
import 'package:smart_tourism_app/screens/home_page.dart';
import 'package:smart_tourism_app/screens/favorites_page.dart';
import 'package:smart_tourism_app/screens/profile_page.dart';
import 'package:smart_tourism_app/screens/Invoices.dart';
import 'package:smart_tourism_app/screens/Planner.dart';
import 'package:smart_tourism_app/screens/Questions.dart';
import 'package:smart_tourism_app/screens/Weather.dart';
import 'package:smart_tourism_app/screens/advice.dart';
import 'package:smart_tourism_app/screens/evaluations.dart';
import 'package:smart_tourism_app/screens/events.dart';
import 'package:smart_tourism_app/screens/notifications_page.dart';
import 'package:smart_tourism_app/screens/city_guide_page.dart';
import 'package:smart_tourism_app/repositories/user_repository.dart'; // <--- تأكد من هذا الاستيراد


// --- Global Theme Colors (Moved here for app-wide access) ---
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kDividerColor = Color(0xFFEAEAEA);
const Color kSuccessColor = Color(0xFF2ECC71);
const Color kErrorColor = Color(0xFFE74C3C);

// --- Global Theme Data Function (Moved here for app-wide application) ---
ThemeData _buildRedesignedTheme() {
  // ... (No changes here, it's the same theme definition) ...
  return ThemeData(
    fontFamily: 'Cairo',
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kBackgroundColor,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      accentColor: kAccentColor,
      backgroundColor: kBackgroundColor,
      cardColor: Colors.white,
      errorColor: kErrorColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: kPrimaryColor,
      secondary: kAccentColor,
      surface: kSurfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: kTextColor,
      onSurface: kTextColor,
      onError: Colors.white,
    ),
    hintColor: kSecondaryTextColor,
    dividerColor: kDividerColor,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: kBackgroundColor,
      foregroundColor: kTextColor,
      centerTitle: true,
      iconTheme: IconThemeData(color: kTextColor, size: 24),
      actionsIconTheme: IconThemeData(color: kTextColor, size: 24),
      titleTextStyle: TextStyle(
        color: kTextColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Cairo',
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: kSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 10.0,
      selectedIconTheme: IconThemeData(size: 26),
      unselectedIconTheme: IconThemeData(size: 24),
      showSelectedLabels: true,
      showUnselectedLabels: false,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'Cairo'),
      landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold, color: kTextColor, height: 1.2),
      headlineMedium: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: kTextColor, height: 1.2),
      headlineSmall: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: kTextColor, height: 1.3),
      titleLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: kTextColor, height: 1.3),
      titleMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: kTextColor, height: 1.3),
      titleSmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: kTextColor, height: 1.3),
      bodyLarge: TextStyle(fontSize: 15.0, color: kTextColor, height: 1.5, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 13.0, color: kTextColor, height: 1.5),
      bodySmall: TextStyle(fontSize: 11.0, color: kSecondaryTextColor, height: 1.4),
      labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'),
      labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: kPrimaryColor, fontFamily: 'Cairo'),
      labelSmall: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w500, color: kSecondaryTextColor, fontFamily: 'Cairo', letterSpacing: 0.5),
    ).apply(
        fontFamily: 'Cairo',
        bodyColor: kTextColor,
        displayColor: kTextColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide(color: kDividerColor, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
      ),
      hintStyle: TextStyle(color: kSecondaryTextColor.withOpacity(0.8), fontSize: 14, fontFamily: 'Cairo'),
    ),
    cardTheme: CardTheme(
      elevation: 3.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        elevation: 2,
      ),
    ),
     textButtonTheme: TextButtonThemeData(
       style: TextButton.styleFrom(
         foregroundColor: kPrimaryColor,
         textStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14),
         padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
       )
    ),
    iconTheme: const IconThemeData(
      color: kSecondaryTextColor,
      size: 24
    ),
    dividerTheme: const DividerThemeData(
      color: kDividerColor,
      space: 1,
      thickness: 0.8,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}


void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),

        ProxyProvider<ApiService, AuthRepository>(
          update: (_, apiService, __) => AuthRepository(apiService),
        ),
        ProxyProvider<ApiService, TourismRepository>(
          update: (_, apiService, __) => TourismRepository(apiService),
        ),
        ProxyProvider<ApiService, BookingRepository>(
          update: (_, apiService, __) => BookingRepository(apiService),
        ),
        ProxyProvider<ApiService, ShoppingCartRepository>(
          update: (_, apiService, __) => ShoppingCartRepository(apiService),
        ),
        ProxyProvider<ApiService, InteractionRepository>(
          update: (_, apiService, __) => InteractionRepository(apiService),
        ),
        ProxyProvider<ApiService, UserRepository>(
          update: (_, apiService, __) => UserRepository(apiService),
        ),
        ProxyProvider<ApiService, HotelRepository>( // <--- Add HotelRepository here
          update: (_, apiService, __) => HotelRepository(apiService),
        ),
        
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Tourism App',
      theme: _buildRedesignedTheme(),
      
      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
        '/profile': (context) => const ProfilePage(),
        '/invoices': (context) => const BookingHistoryPage(),
        '/planner': (context) => const TripPlannerPage(),
        '/questions': (context) => const FAQPage(),
        '/weather': (context) => const WeatherPage(),
        '/advice': (context) =>  TravelTipsPage(),
        '/evaluations': (context) => const ReviewsPage(),
        '/events': (context) => const EventsPage(),
        '/notifications': (context) =>  NotificationsPage(),
        '/city-guide': (context) => const CityGuidePage(), // Changed to lowercase for consistency
      },

      onGenerateRoute: (settings) {
        // Example for dynamic routes (e.g., details pages)
        // if (settings.name?.startsWith('/hotels/') == true) {
        //   final id = int.tryParse(settings.name!.split('/').last);
        //   if (id != null) {
        //     return MaterialPageRoute(builder: (context) => HotelDetailsPage(hotelId: id));
        //   }
        // }
        // For /evaluations with targetType and targetId
        // if (settings.name == '/evaluations_for_item') {
        //   final args = settings.arguments as Map<String, dynamic>;
        //   return MaterialPageRoute(builder: (context) => ReviewsPage(
        //     targetType: args['targetType'] as String,
        //     targetId: args['targetId'] as int,
        //   ));
        // }
        
        return null;
      },
    );
  }
}