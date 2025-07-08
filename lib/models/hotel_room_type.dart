// lib/models/hotel_room_type.dart
class HotelRoomType {
  final int id;
  final String name;
  final String? description;

  HotelRoomType({
    required this.id,
    required this.name,
    this.description,
  });

  factory HotelRoomType.fromJson(Map<String, dynamic> json) {
    return HotelRoomType(
      id: json['id'] as int, // يجب أن يكون موجوداً دائماً
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}