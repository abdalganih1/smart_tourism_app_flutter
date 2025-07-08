import 'dart:async';
import 'dart:developer'; // <-- استيراد log للطباعة (أفضل من print للـ Debug)

import '../models/hotel_booking.dart';
import '../models/product_order.dart';
import '../models/pagination.dart';
import '../services/api_service.dart';

class BookingRepository {
  final ApiService _apiService;

  BookingRepository(this._apiService);

  // --- Hotel Bookings ---
  Future<PaginatedResponse<HotelBooking>> getMyHotelBookings({int page = 1}) async {
    final response = await _apiService.get('/my-bookings', queryParameters: {'page': page.toString()}, protected: true); // Protected endpoint
    
    // --- إضافة الطباعة هنا ---
    log('Raw API Response for /my-bookings (page $page): $response'); 
    // يمكنك أيضاً استخدام print(response.runtimeType) لمعرفة نوع الاستجابة إذا لم تكن متأكداً أنها Map

    // يجب أن تكون الاستجابة Map<String, dynamic> تحتوي على مفتاح 'data'
    if (response is Map<String, dynamic>) {
        return PaginatedResponse<HotelBooking>.fromJson(response, (json) => HotelBooking.fromJson(json));
    } else {
        // إذا كانت الاستجابة ليست بالصيغة المتوقعة، يمكنك طباعة رسالة خطأ أكثر تفصيلاً هنا
        log('Unexpected format for /my-bookings response: $response');
        throw FormatException('Expected a paginated response for hotel bookings, but received: $response');
    }
  }

  Future<HotelBooking> getMyHotelBookingDetails(int bookingId) async {
    final response = await _apiService.get('/my-bookings/$bookingId', protected: true); // Protected endpoint
    log('Raw API Response for /my-bookings/$bookingId: $response'); // طباعة استجابة التفاصيل
    // بما أن الـ OpenAPI يظهر أن هذا قد يكون ملفوفاً بـ 'data'، يجب التأكد من التعامل معه
    if (response is Map<String, dynamic> && response.containsKey('data')) {
        return HotelBooking.fromJson(response['data'] as Map<String, dynamic>);
    } else if (response is Map<String, dynamic>) {
        return HotelBooking.fromJson(response);
    } else {
        throw FormatException('Expected a single hotel booking object, but received: $response');
    }
  }

  Future<HotelBooking> placeHotelBooking(Map<String, dynamic> bookingData) async {
     // bookingData should contain: room_id, check_in_date, check_out_date, num_adults, num_children, special_requests
    final response = await _apiService.post('/bookings', bookingData, protected: true); // Protected endpoint
    log('Raw API Response for /bookings (place): $response');
    // بما أن الـ OpenAPI يظهر أن هذا قد يكون ملفوفاً بـ 'data'
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return HotelBooking.fromJson(response['data'] as Map<String, dynamic>);
    } else if (response is Map<String, dynamic>) {
      return HotelBooking.fromJson(response);
    } else {
      throw FormatException('Expected a hotel booking object after placing booking, but received: $response');
    }
  }

  Future<HotelBooking> cancelHotelBooking(int bookingId) async {
    // Assuming an endpoint like POST /my-bookings/{hotelBooking}/cancel
    final response = await _apiService.post('/my-bookings/$bookingId/cancel', {}, protected: true); // Protected endpoint
    log('Raw API Response for /my-bookings/$bookingId/cancel: $response');
    // بما أن الـ OpenAPI يظهر أن هذا قد يكون ملفوفاً بـ 'data'
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return HotelBooking.fromJson(response['data'] as Map<String, dynamic>);
    } else if (response is Map<String, dynamic>) {
      return HotelBooking.fromJson(response);
    } else {
      throw FormatException('Expected a hotel booking object after cancelling, but received: $response');
    }
  }


  // --- Product Orders ---
   Future<PaginatedResponse<ProductOrder>> getMyProductOrders({int page = 1}) async {
     final response = await _apiService.get('/my-orders', queryParameters: {'page': page.toString()}, protected: true); // Protected endpoint
    
    // --- إضافة الطباعة هنا ---
    log('Raw API Response for /my-orders (page $page): $response');
    
    if (response is Map<String, dynamic>) {
        return PaginatedResponse<ProductOrder>.fromJson(response, (json) => ProductOrder.fromJson(json));
    } else {
        log('Unexpected format for /my-orders response: $response');
        throw FormatException('Expected a paginated response for product orders, but received: $response');
    }
  }

  Future<ProductOrder> getMyProductOrderDetails(int orderId) async {
    final response = await _apiService.get('/my-orders/$orderId', protected: true); // Protected endpoint
    log('Raw API Response for /my-orders/$orderId: $response'); // طباعة استجابة التفاصيل
    // بما أن الـ OpenAPI يظهر أن هذا قد يكون ملفوفاً بـ 'data'
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return ProductOrder.fromJson(response['data'] as Map<String, dynamic>);
    } else if (response is Map<String, dynamic>) {
      return ProductOrder.fromJson(response);
    } else {
      throw FormatException('Expected a single product order object, but received: $response');
    }
  }

  Future<ProductOrder> placeProductOrder(Map<String, dynamic> orderData) async {
     // orderData should contain: shipping_address_line1, shipping_city, etc. (from PlaceOrderRequest schema)
     // The API expects to create order items from the user's cart.
    final response = await _apiService.post('/orders', orderData, protected: true); // Protected endpoint
    log('Raw API Response for /orders (place): $response');
    // بما أن الـ OpenAPI يظهر أن هذا قد يكون ملفوفاً بـ 'data'
    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return ProductOrder.fromJson(response['data'] as Map<String, dynamic>);
    } else if (response is Map<String, dynamic>) {
      return ProductOrder.fromJson(response);
    } else {
      throw FormatException('Expected a product order object after placing order, but received: $response');
    }
  }

  // Note: API does not have update/delete for orders by user based on YAML
}