class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? relatedEvaluationId;
  final String? relatedPostId;
  final String? relatedUserId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.relatedEvaluationId,
    this.relatedPostId,
    this.relatedUserId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        relatedEvaluationId: json['related_evaluation_id'] as String?,
        relatedPostId: json['related_post_id'] as String?,
        relatedUserId: json['related_user_id'] as String?,
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        relatedEvaluationId: relatedEvaluationId,
        relatedPostId: relatedPostId,
        relatedUserId: relatedUserId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
