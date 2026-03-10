import 'package:daef/models/api_response.dart';
import 'package:daef/models/social_post.dart';
import 'package:daef/services/api_client.dart';

class SocialService {
  SocialService._();
  static final SocialService instance = SocialService._();

  final _client = ApiClient.instance;

  // ── Share an evaluation as a post ────────────────────────────────────────────

  Future<SocialPost> createPost({
    required String evaluationId,
    String? title,
    String? description,
  }) async {
    final response = await _client.post('/social/posts', data: {
      'evaluation_id': evaluationId,
      if (title != null && title.isNotEmpty) 'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return SocialPost.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Feed (recent, paginated) ──────────────────────────────────────────────────

  Future<PaginatedResponse<SocialPost>> getFeed({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get('/social/posts/feed', params: {
      'page': page,
      'page_size': pageSize,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      SocialPost.fromJson,
    );
  }

  // ── Leaderboard: top by score ─────────────────────────────────────────────────

  Future<List<SocialPost>> getTopByScore({int limit = 10}) async {
    final response = await _client.get('/social/posts/top-score', params: {'limit': limit});
    return (response.data as List)
        .map((e) => SocialPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Leaderboard: top by likes ─────────────────────────────────────────────────

  Future<List<SocialPost>> getTopByLikes({int limit = 10}) async {
    final response = await _client.get('/social/posts/top-liked', params: {'limit': limit});
    return (response.data as List)
        .map((e) => SocialPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Leaderboard: top by comments ──────────────────────────────────────────────

  Future<List<SocialPost>> getTopByComments({int limit = 10}) async {
    final response = await _client.get('/social/posts/top-commented', params: {'limit': limit});
    return (response.data as List)
        .map((e) => SocialPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Get single post ───────────────────────────────────────────────────────────

  Future<SocialPost> getPost(String postId) async {
    final response = await _client.get('/social/posts/$postId');
    return SocialPost.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Delete own post ───────────────────────────────────────────────────────────

  Future<void> deletePost(String postId) async {
    await _client.delete('/social/posts/$postId');
  }

  // ── Get posts by a specific user ──────────────────────────────────────────────

  Future<PaginatedResponse<SocialPost>> getUserPosts({
    required String userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get('/social/posts/user/$userId', params: {
      'page': page,
      'page_size': pageSize,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      SocialPost.fromJson,
    );
  }

  // ── Like a post ───────────────────────────────────────────────────────────────

  Future<void> likePost(String postId) async {
    await _client.post('/interactions/posts/$postId/like');
  }

  // ── Unlike a post ─────────────────────────────────────────────────────────────

  Future<void> unlikePost(String postId) async {
    await _client.delete('/interactions/posts/$postId/like');
  }

  // ── Add a comment ─────────────────────────────────────────────────────────────

  Future<Comment> addComment({
    required String postId,
    required String content,
  }) async {
    final response = await _client.post(
      '/interactions/posts/$postId/comments',
      data: {'content': content},
    );
    return Comment.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Get comments (paginated) ──────────────────────────────────────────────────

  Future<PaginatedResponse<Comment>> getComments({
    required String postId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/interactions/posts/$postId/comments',
      params: {'page': page, 'page_size': pageSize},
    );
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      Comment.fromJson,
    );
  }

  // ── Delete own comment ────────────────────────────────────────────────────────

  Future<void> deleteComment(String commentId) async {
    await _client.delete('/interactions/comments/$commentId');
  }
}
