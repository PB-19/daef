// Matches backend SocialPostResponse schema exactly
class SocialPost {
  final String id;
  final String evaluationId;
  final String userId;
  final String username;
  final String? title;
  final String? description;
  final double? overallScore;
  final String? domain;   // Optional in backend schema
  final String? taskType; // Optional in backend schema
  final int likesCount;
  final int commentsCount;
  final bool isLikedByCurrentUser;
  final DateTime createdAt;

  const SocialPost({
    required this.id,
    required this.evaluationId,
    required this.userId,
    required this.username,
    this.title,
    this.description,
    this.overallScore,
    this.domain,
    this.taskType,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByCurrentUser,
    required this.createdAt,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) => SocialPost(
        id: json['id'] as String,
        evaluationId: json['evaluation_id'] as String,
        userId: json['user_id'] as String,
        username: json['username'] as String,
        title: json['title'] as String?,
        description: json['description'] as String?,
        overallScore: json['overall_score'] != null
            ? (json['overall_score'] as num).toDouble()
            : null,
        domain: json['domain'] as String?,
        taskType: json['task_type'] as String?,
        likesCount: json['likes_count'] as int? ?? 0,
        commentsCount: json['comments_count'] as int? ?? 0,
        isLikedByCurrentUser:
            json['is_liked_by_current_user'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get displayTitle =>
      title?.isNotEmpty == true ? title! : 'Evaluation in ${domain ?? 'Unknown'}';

  SocialPost copyWith({
    bool? isLikedByCurrentUser,
    int? likesCount,
    int? commentsCount,
  }) =>
      SocialPost(
        id: id,
        evaluationId: evaluationId,
        userId: userId,
        username: username,
        title: title,
        description: description,
        overallScore: overallScore,
        domain: domain,
        taskType: taskType,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        isLikedByCurrentUser:
            isLikedByCurrentUser ?? this.isLikedByCurrentUser,
        createdAt: createdAt,
      );
}

// Matches backend CommentResponse schema exactly
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        userId: json['user_id'] as String,
        username: json['username'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
