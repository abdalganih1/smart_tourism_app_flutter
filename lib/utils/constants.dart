// lib/utils/constants.dart
// Define constants like user types, booking statuses etc.
class UserTypes {
  static const String admin = 'Admin';
  static const String employee = 'Employee';
  static const String hotelBookingManager = 'HotelBookingManager';
  static const String articleWriter = 'ArticleWriter';
  static const String tourist = 'Tourist';
  static const String vendor = 'Vendor';
}

class BookingStatuses {
  static const String pendingConfirmation = 'PendingConfirmation';
  static const String confirmed = 'Confirmed';
  static const String cancelledByUser = 'CancelledByUser';
  static const String cancelledByHotel = 'CancelledByHotel';
  static const String completed = 'Completed';
  static const String noShow = 'NoShow';
}

class PaymentStatuses {
  static const String unpaid = 'Unpaid';
  static const String paid = 'Paid';
  static const String paymentFailed = 'PaymentFailed';
  static const String refunded = 'Refunded';
}

class TargetTypes {
  static const String touristSite = 'TouristSite';
  static const String product = 'Product';
  static const String article = 'Article';
  static const String hotel = 'Hotel';
  static const String siteExperience = 'SiteExperience';
  static const String touristActivity = 'TouristActivity'; // <--- أضف هذا السطر
  static const String user = 'User'; // إذا احتجت User كـ Target
}
