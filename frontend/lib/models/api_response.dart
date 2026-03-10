class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      PaginatedResponse(
        items: (json['items'] as List)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['page_size'] as int,
        totalPages: json['total_pages'] as int,
      );

  bool get hasMore => page < totalPages;
}

class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final String? detail;

  const ApiError({required this.message, this.statusCode, this.detail});

  @override
  String toString() => detail ?? message;
}
