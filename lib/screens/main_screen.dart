// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemUiOverlayStyle
import 'package:provider/provider.dart';
import 'package:smart_tourism_app/repositories/auth_repository.dart'; // Import auth repo for logout
import 'package:smart_tourism_app/repositories/user_repository.dart'; // Import user repo for user data in drawer (Optional, if not handled by auth_repository)
import 'package:smart_tourism_app/screens/HotelsPage.dart';
import 'package:smart_tourism_app/screens/articles_page.dart';
import 'package:smart_tourism_app/screens/shopping_cart_screen.dart';


// Import all necessary screens/pages
import 'package:smart_tourism_app/screens/home_page.dart';
import 'package:smart_tourism_app/screens/favorites_page.dart';
import 'package:smart_tourism_app/screens/products_page.dart';
import 'package:smart_tourism_app/screens/profile_page.dart'; // <<<--- هذا السطر تم فك تعليقه
import 'package:smart_tourism_app/screens/Invoices.dart'; // BookingHistoryPage (named Invoices.dart)
import 'package:smart_tourism_app/screens/Planner.dart'; // TripPlannerPage (named Planner.dart)
import 'package:smart_tourism_app/screens/Questions.dart'; // FAQPage (named Questions.dart)
import 'package:smart_tourism_app/screens/Weather.dart'; // WeatherPage (named Weather.dart)
import 'package:smart_tourism_app/screens/advice.dart'; // TravelTipsPage (named advice.dart)
import 'package:smart_tourism_app/screens/evaluations.dart'; // ReviewsPage (named evaluations.dart)
import 'package:smart_tourism_app/screens/events.dart'; // EventsPage (named events.dart)
import 'package:smart_tourism_app/screens/notifications_page.dart'; // <<<--- هذا السطر تم فك تعليقه
import 'package:smart_tourism_app/screens/city_guide_page.dart'; // <<<--- هذا السطر تم فك تعليقه
import 'package:smart_tourism_app/models/user.dart';
import 'package:smart_tourism_app/screens/tourist_sites_list_page.dart'; // Import User model to display user info in drawer

// --- REFINED THEME COLORS (Moved to main.dart for app-wide theme) ---
// If you moved these to a separate constants file (e.g., lib/constants/app_colors.dart),
// then import that file here and remove these definitions.
// Otherwise, keep them here or ensure they are imported from main.dart
const Color kPrimaryColor = Color(0xFF005B96); // Richer Blue
const Color kAccentColor = Color(0xFFF7931E); // Vibrant Orange
const Color kBackgroundColor = Color(0xFFFDFDFD); // Very light off-white
const Color kSurfaceColor = Color(0xFFF5F5F5); // Light Grey
const Color kTextColor = Color(0xFF2D3436); // Dark Grey/Black
const Color kSecondaryTextColor = Color(0xFF757575); // Medium Grey
const Color kDividerColor = Color(0xFFEAEAEA);
const Color kSuccessColor = Color(0xFF2ECC71); // Emerald Green
const Color kErrorColor = Color(0xFFE74C3C); // Alizarin Red


// --- Main Application Screen (Layout mostly unchanged, relies on Theme) ---
class MainScreen extends StatefulWidget {
  static const routeName = '/main';
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  User? _loggedInUser; // To store logged-in user data for drawer

  // Pages for the Bottom Navigation Bar
  final List<Widget> _pages = [
    const HomePage(),
    const FavoritesPage(),
    const ProfilePage(), // <<<--- تم التأكد من وجودها
  ];

  @override
  void initState() {
    super.initState();
    _fetchLoggedInUser();
  }

  // Fetch logged-in user details for the drawer header
  Future<void> _fetchLoggedInUser() async {
    try {
      // Assuming AuthRepository has a method to get the current user
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      final user = await authRepo.getAuthenticatedUser(); // This should fetch User with profile
      if (mounted) {
        setState(() {
          _loggedInUser = user;
        });
      }
    } catch (e) {
      print('Error fetching logged-in user: $e');
      // Handle error, e.g., if token is invalid, force logout
    }
  }


  void _onItemTapped(int index) {
    if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close drawer if open
    }
    // Prevent rebuilding if the same tab is tapped
    if (_selectedIndex != index) {
        setState(() {
          _selectedIndex = index;
        });
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer first
    Navigator.push(context, MaterialPageRoute(
        builder: (context) => page,
        // Consider adding transitions
        // transitionsBuilder: (context, animation, secondaryAnimation, child) {
        //   return FadeTransition(opacity: animation, child: child);
        // }
    ));
  }

  // Helper to build styled Drawer ListTiles (Refined style)
  Widget _buildDrawerItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor, // Allow override, defaults to theme
    Color? textColor, // Allow override
    bool isSelected = false, // Highlight selected item
  }) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? (isSelected ? theme.primaryColor : kSecondaryTextColor);
    final effectiveTextColor = textColor ?? (isSelected ? theme.primaryColor : kTextColor);

    return Container(
      // Padding applied by ListTile contentPadding
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: effectiveIconColor, size: 22),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith( // Slightly larger text in drawer
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: effectiveTextColor
          ),
        ),
        onTap: onTap,
        dense: true,
        // Consistent padding inside the ListTile
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Match container shape for ripple
      ),
    );
  }

   Future<void> _logout() async {
    try {
      final authRepo = Provider.of<AuthRepository>(context, listen: false);
      await authRepo.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل الخروج بنجاح'), backgroundColor: kSuccessColor),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Logout failed: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تسجيل الخروج: ${e.toString()}'), backgroundColor: kErrorColor),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Apply SystemUiOverlayStyle for status bar theming (can also be done in main.dart's ThemeData)
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness: Brightness.dark, // Dark icons for light status bar background
      systemNavigationBarColor: Colors.white, // Keep bottom nav bar white explicitly (or use kBackgroundColor if it matches)
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    // The Theme.of(context) now gets the redesigned theme from main.dart
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl, // Keep RTL
      child: Scaffold(
        // AppBar is now styled by the theme
        appBar: AppBar(
          title: const Text('اكتشف سوريا'),
           leading: Builder( // Keep drawer button
             builder: (context) => IconButton(
               icon: const Icon(Icons.menu_rounded),
               onPressed: () => Scaffold.of(context).openDrawer(),
               tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
             ),
           ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              tooltip: 'Shopping Cart',
              onPressed: () {
                Navigator.of(context).pushNamed(ShoppingCartScreen.routeName);
              },
            ),
            IconButton( // Keep notifications
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'الإشعارات',
              onPressed: () {
                _navigateTo(context, NotificationsPage()); // <<<--- تم فك تعليقها
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: Drawer(
          child: SafeArea( // Ensure content doesn't overlap status bar
            child: ListView(
              padding: EdgeInsets.zero, // Remove default padding
              children: [
                // --- Drawer Header (Slightly enhanced) ---
                Padding(
                  // Padding for the header content
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                       CircleAvatar(
                        radius: 32, // Slightly larger
                         backgroundColor: kPrimaryColor.withOpacity(0.2),
                         child: CircleAvatar(
                            radius: 29,
                            // Dynamic user profile picture
                            backgroundImage: (_loggedInUser?.profile?.imageUrl != null && _loggedInUser!.profile!.imageUrl!.isNotEmpty)
                                ? NetworkImage(_loggedInUser!.profile!.imageUrl!) as ImageProvider
                                : const AssetImage('assets/user.png'), // Default asset image
                            backgroundColor: kSurfaceColor,
                            onBackgroundImageError: (exception, stackTrace) {
                                print('Error loading drawer profile image: $exception');
                            },
                         ),
                       ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loggedInUser?.profile?.firstName != null && _loggedInUser!.profile!.lastName != null
                                  ? '${_loggedInUser!.profile!.firstName!} ${_loggedInUser!.profile!.lastName!}'
                                  : _loggedInUser?.username ?? 'زائر', // Display full name or username
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _loggedInUser?.email ?? 'info@app.com', // Display user email
                               style: theme.textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 20, endIndent: 20, thickness: 0.5), // Thinner divider

                // --- Drawer Items (Using new builder) ---
                 _buildDrawerItem(context: context, title: 'الرئيسية', icon: Icons.home_outlined, onTap: () => _onItemTapped(0), isSelected: _selectedIndex == 0),
                 _buildDrawerItem(context: context, title: 'المفضلة', icon: Icons.favorite_border_rounded, onTap: () => _onItemTapped(1), isSelected: _selectedIndex == 1),
                 _buildDrawerItem(context: context, title: 'الملف الشخصي', icon: Icons.person_outline_rounded, onTap: () => _onItemTapped(2), isSelected: _selectedIndex == 2),
                 const Divider(indent: 20, endIndent: 20, thickness: 0.5),
                 _buildDrawerItem(context: context, title: 'الفواتير والحجوزات', icon: Icons.receipt_long_outlined, onTap: () => _navigateTo(context,  const BookingHistoryPage())), // <<<--- تم فك تعليقها
                 _buildDrawerItem(context: context, title: 'الدليل السياحي', icon: Icons.map_outlined, onTap: () => _navigateTo(context, const CityGuidePage())), // <<<--- تم فك تعليقها
                 _buildDrawerItem(context: context, title: 'الأحداث والفعاليات', icon: Icons.event_available_outlined, onTap: () => _navigateTo(context,  const EventsPage())), // <<<--- تم فك تعليقها
                 _buildDrawerItem(context: context, title: 'نصائح السفر', icon: Icons.lightbulb_outline_rounded, onTap: () => _navigateTo(context,    TravelTipsPage())), // <<<--- تم فك تعليقها
                 _buildDrawerItem(context: context, title: 'الطقس', icon: Icons.wb_sunny_outlined, onTap: () => _navigateTo(context,  const WeatherPage())), // <<<--- تم فك تعليقها
                 _buildDrawerItem(context: context, title: 'مخطط الرحلات', icon: Icons.edit_calendar_outlined, onTap: () => _navigateTo(context,  const TripPlannerPage())), 
                          // في lib/screens/main_screen.dart ضمن _buildDrawerItem
_buildDrawerItem(
  context: context,
  title: 'المنتجات والحرف اليدوية',
  icon: Icons.shopping_bag_outlined,
  onTap: () => _navigateTo(context, const ProductsPage()),
),
                                  _buildDrawerItem(context: context, title: ' ا��وجهات السياحية', icon: Icons.edit_calendar_outlined, onTap: () => _navigateTo(context,  const TouristSitesListPage())),
_buildDrawerItem(context: context, title: ' الفنادق ', icon: Icons.edit_calendar_outlined, onTap: () => _navigateTo(context, const HotelsPage())), // <<<--- تم فك تعليقها
// <<<--- تم فك تعليقها
                 const Divider(indent: 20, endIndent: 20, thickness: 0.5),
                 _buildDrawerItem(context: context, title: 'الأسئلة الشائعة', icon: Icons.quiz_outlined, onTap: () => _navigateTo(context,  const FAQPage())), // <<<--- تم فك تعليقها
                 _buildDrawerItem(context: context, title: 'التقييمات', icon: Icons.reviews_outlined, onTap: () => _navigateTo(context,   const ReviewsPage())), // <<<--- تم فك تعليقها
                 _buildDrawerItem(context: context, title: 'المقالات', icon: Icons.notifications_none_rounded, onTap: () => _navigateTo(context,  ArticlesPage())), // <<<--- تم فك تعليقها
                 const Divider(indent: 20, endIndent: 20, thickness: 0.5),
                 _buildDrawerItem(
                  context: context,
                  title: 'تسجيل الخروج',
                  icon: Icons.logout_rounded,
                  iconColor: kErrorColor, // Use error color
                  textColor: kErrorColor,
                  onTap: _logout, // Call the logout method
                ),
                 const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        body: IndexedStack( // Keeps state of inactive tabs
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          // Styling handled by Theme
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'استكشف',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'المفضلة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPLETE THEME REDESIGN (This function should ideally be in main.dart) ---
  // If your main.dart already applies this theme, you can remove this function.
  // It's kept here based on your provided file structure, but it's redundant if MaterialApp applies it.
  ThemeData _buildRedesignedTheme() {
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
}