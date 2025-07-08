// lib/models/pagination.dart

class PaginatedResponse<T> {
  final List<T> data;
  final Meta meta;
  final Map<String, dynamic>? extra; // يمكن أن يحتوي على بيانات إضافية مثل متوسط التقييم

  PaginatedResponse({
    required this.data,
    required this.meta,
    this.extra,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(dynamic json) fromJsonT) {
    return PaginatedResponse<T>(
      data: (json['data'] as List<dynamic>).map((item) => fromJsonT(item)).toList(),
      meta: Meta.fromJson(json['meta']),
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }
}

class Meta {
  final int currentPage;
  final int? from;
  final int lastPage;
  final List<Link> links; // <<-- الروابط هنا داخل Meta
  final String path;
  final int perPage;
  final int? to;
  final int total;

  Meta({
    required this.currentPage,
    this.from,
    required this.lastPage,
    required this.links,
    required this.path,
    required this.perPage,
    this.to,
    required this.total,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      currentPage: json['current_page'],
      from: json['from'],
      lastPage: json['last_page'],
      links: (json['links'] as List<dynamic>).map((link) => Link.fromJson(link)).toList(),
      path: json['path'],
      perPage: json['per_page'],
      to: json['to'],
      total: json['total'],
    );
  }
}

class Link {
  final String? url;
  final String label;
  final bool active;

  Link({
    this.url,
    required this.label,
    required this.active,
  });

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      url: json['url'],
      label: json['label'],
      active: json['active'],
    );
  }
}