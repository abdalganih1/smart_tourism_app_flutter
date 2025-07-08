// lib/screens/notifications_page.dart
import 'package:flutter/material.dart';

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


class NotificationsPage extends StatelessWidget {
  // بيانات وهمية للإشعارات
  final List<Map<String, String>> notifications = [
    {
      "title": "عرض خاص! خصم 30% على الفنادق في دمشق",
      "subtitle": "فنادق مختارة في قلب العاصمة لفترة محدودة.",
      "type": "promotion",
      "date": "2025-05-20",
    },
    {
      "title": "تأكيد حجزك لفندق الشيراتون",
      "subtitle": "تم تأكيد حجز غرفتك رقم 305 من تاريخ 10/6 حتى 15/6.",
      "type": "booking",
      "date": "2025-05-18",
    },
    {
      "title": "فعالية ثقافية: مهرجان الموسيقى العربية بحلب",
      "subtitle": "انضم إلينا في أمسيات موسيقية رائعة من 1 إلى 5 يوليو.",
      "type": "event",
      "date": "2025-05-15",
    },
    {
      "title": "تحديث هام بخصوص رحلتك إلى تدمر",
      "subtitle": "تم تغيير موعد الانطلاق إلى الساعة 9:00 صباحاً.",
      "type": "update",
      "date": "2025-05-12",
    },
    {
      "title": "تنبيه: محتوى جديد في المدونة",
      "subtitle": "اكتشف 'أجمل 10 شلالات في ريف اللاذقية'.",
      "type": "content",
      "date": "2025-05-10",
    },
  ];

  NotificationsPage({super.key}); // Add key

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'التنبيهات والإشعارات',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor: kBackgroundColor, // Use theme color
          foregroundColor: kTextColor, // Use theme color
          elevation: 0, // Flat design
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'إعدادات الإشعارات',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsPage()));
              },
            ),
          ],
        ),
        body: notifications.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                      const SizedBox(height: 20),
                      Text(
                        'لا توجد إشعارات جديدة',
                        style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'عندما يكون هناك شيء جديد، سيظهر هنا.',
                        style: textTheme.bodyLarge?.copyWith(color: kSecondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: Text(
                      'أحدث الإشعارات',
                      style: textTheme.headlineSmall, // Use theme text style
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationItem(context, notifications[index]);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, String> notification) {
    final textTheme = Theme.of(context).textTheme;

    IconData getIconForNotificationType(String type) {
      switch (type) {
        case 'promotion': return Icons.local_offer_outlined;
        case 'booking': return Icons.calendar_month_outlined;
        case 'event': return Icons.event_note_outlined;
        case 'update': return Icons.info_outline;
        case 'content': return Icons.article_outlined;
        default: return Icons.notifications_none_outlined;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: InkWell( // Make card tappable with ripple
        onTap: () {
          // TODO: Implement logic to open notification details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فتح إشعار: ${notification['title']}')),
          );
        },
        borderRadius: BorderRadius.circular(16), // Match card shape for ripple
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(getIconForNotificationType(notification['type'] ?? ''), size: 24, color: kPrimaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'] ?? 'إشعار جديد',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['subtitle'] ?? '',
                      style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        notification['date'] ?? '', // You might want to format this date
                        style: textTheme.bodySmall?.copyWith(color: kSecondaryTextColor.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: kSecondaryTextColor.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Notification Settings Page ---
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key}); // Add key

  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // هذه القيم يجب أن يتم حفظها وتحميلها من SharedPreferences أو API
  bool _isPromotionsEnabled = true;
  bool _isEventsEnabled = true;
  bool _isBookingUpdatesEnabled = true;
  bool _isArticleUpdatesEnabled = true; // New setting
  bool _isGeneralUpdatesEnabled = true; // New setting

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إعدادات الإشعارات',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'تخصيص التنبيهات',
                  style: textTheme.headlineSmall, // Use theme text style
                ),
              ),
              _buildSwitchTile(
                context,
                'العروض الخاصة',
                _isPromotionsEnabled,
                (bool value) {
                  setState(() {
                    _isPromotionsEnabled = value;
                  });
                  // TODO: Save setting to SharedPreferences or API
                },
              ),
              _buildSwitchTile(
                context,
                'الفعاليات والعروض',
                _isEventsEnabled,
                (bool value) {
                  setState(() {
                    _isEventsEnabled = value;
                  });
                  // TODO: Save setting to SharedPreferences or API
                },
              ),
              _buildSwitchTile(
                context,
                'تحديثات الحجوزات',
                _isBookingUpdatesEnabled,
                (bool value) {
                  setState(() {
                    _isBookingUpdatesEnabled = value;
                  });
                  // TODO: Save setting to SharedPreferences or API
                },
              ),
              _buildSwitchTile(
                context,
                'تحديثات المقالات', // New setting
                _isArticleUpdatesEnabled,
                (bool value) {
                  setState(() {
                    _isArticleUpdatesEnabled = value;
                  });
                  // TODO: Save setting to SharedPreferences or API
                },
              ),
              _buildSwitchTile(
                context,
                'إشعارات عامة', // New setting
                _isGeneralUpdatesEnabled,
                (bool value) {
                  setState(() {
                    _isGeneralUpdatesEnabled = value;
                  });
                  // TODO: Save setting to SharedPreferences or API
                },
              ),
              // Add more settings as needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      BuildContext context, String title, bool value, Function(bool) onChanged) {
    final textTheme = Theme.of(context).textTheme;
    return SwitchListTile(
      title: Text(title, style: textTheme.bodyLarge), // Use theme text style
      value: value,
      onChanged: onChanged,
      activeColor: kPrimaryColor, // Use theme color
      contentPadding: const EdgeInsets.symmetric(horizontal: 0), // Adjust padding
    );
  }
}