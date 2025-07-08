// lib/models/article.dart
import 'package:smart_tourism_app/models/user.dart';

class Article {
  final int id;
  final String title;
  final String content;
  final String? excerpt; // ملخص قصير للمقالة
  final String? imageUrl;
  final DateTime publishedAt;
  final User? author; // كاتب المقالة (إذا كان مرتبطاً)
  final List<String>? tags; // قائمة بالكلمات المفتاحية أو التصنيفات

  Article({
    required this.id,
    required this.title,
    required this.content,
    this.excerpt,
    this.imageUrl,
    required this.publishedAt,
    this.author,
    this.tags,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      title: json['title'] ?? 'عنوان غير متوفر',
      content: json['content'] ?? 'محتوى غير متوفر',
      excerpt: json['excerpt'] as String?,
      imageUrl: json['image_url'] as String?,
      publishedAt: DateTime.parse(json['published_at'] ?? json['created_at']),
      author: json.containsKey('author') && json['author'] != null
          ? User.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      tags: json.containsKey('tags') && json['tags'] != null
          ? List<String>.from(json['tags'])
          : null,
    );
  }
}