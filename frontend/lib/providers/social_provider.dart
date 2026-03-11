import 'package:flutter/foundation.dart';
import 'package:daef/models/api_response.dart';
import 'package:daef/models/social_post.dart';
import 'package:daef/services/social_service.dart';

class SocialProvider extends ChangeNotifier {
  // Feed
  List<SocialPost> _feed = [];
  bool _feedLoading = false;
  bool _feedLoadingMore = false;
  int _feedPage = 1;
  bool _feedHasMore = true;

  // Leaderboards
  List<SocialPost> _topScore = [];
  List<SocialPost> _topLiked = [];
  List<SocialPost> _topCommented = [];
  bool _leaderboardLoading = false;

  // Current post + its comments
  SocialPost? _currentPost;
  List<Comment> _comments = [];
  bool _commentsLoading = false;
  bool _commentsLoadingMore = false;
  int _commentsPage = 1;
  bool _commentsHasMore = true;

  String? _error;

  // Feed getters
  List<SocialPost> get feed => _feed;
  bool get feedLoading => _feedLoading;
  bool get feedLoadingMore => _feedLoadingMore;
  bool get feedHasMore => _feedHasMore;

  // Leaderboard getters
  List<SocialPost> get topScore => _topScore;
  List<SocialPost> get topLiked => _topLiked;
  List<SocialPost> get topCommented => _topCommented;
  bool get leaderboardLoading => _leaderboardLoading;

  // Post + comment getters
  SocialPost? get currentPost => _currentPost;
  List<Comment> get comments => _comments;
  bool get commentsLoading => _commentsLoading;
  bool get commentsLoadingMore => _commentsLoadingMore;
  bool get commentsHasMore => _commentsHasMore;

  String? get error => _error;

  // ── Feed ──────────────────────────────────────────────────────────────────────

  Future<void> loadFeed() async {
    _feedLoading = true;
    _error = null;
    _feedPage = 1;
    notifyListeners();
    try {
      final result = await SocialService.instance.getFeed(page: 1);
      _feed = result.items;
      _feedHasMore = result.hasMore;
    } on ApiError catch (e) {
      _error = e.toString();
    } finally {
      _feedLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreFeed() async {
    if (_feedLoadingMore || !_feedHasMore) return;
    _feedLoadingMore = true;
    notifyListeners();
    try {
      final result = await SocialService.instance.getFeed(page: _feedPage + 1);
      _feedPage++;
      _feed = [..._feed, ...result.items];
      _feedHasMore = result.hasMore;
    } on ApiError catch (e) {
      _error = e.toString();
    } finally {
      _feedLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Leaderboards ──────────────────────────────────────────────────────────────

  Future<void> loadLeaderboards() async {
    _leaderboardLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        SocialService.instance.getTopByScore(),
        SocialService.instance.getTopByLikes(),
        SocialService.instance.getTopByComments(),
      ]);
      _topScore = results[0];
      _topLiked = results[1];
      _topCommented = results[2];
    } on ApiError catch (e) {
      _error = e.toString();
    } finally {
      _leaderboardLoading = false;
      notifyListeners();
    }
  }

  // ── Single post ───────────────────────────────────────────────────────────────

  Future<void> loadPost(String postId) async {
    _error = null;
    try {
      _currentPost = await SocialService.instance.getPost(postId);
    } on ApiError catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // ── Like / unlike (optimistic update) ────────────────────────────────────────

  Future<void> toggleLike(String postId) async {
    final feedIdx = _feed.indexWhere((p) => p.id == postId);
    final topScoreIdx = _topScore.indexWhere((p) => p.id == postId);
    final topLikedIdx = _topLiked.indexWhere((p) => p.id == postId);
    final topCommentedIdx = _topCommented.indexWhere((p) => p.id == postId);
    final isCurrentPost = _currentPost?.id == postId;

    final post = feedIdx != -1
        ? _feed[feedIdx]
        : topScoreIdx != -1
            ? _topScore[topScoreIdx]
            : topLikedIdx != -1
                ? _topLiked[topLikedIdx]
                : topCommentedIdx != -1
                    ? _topCommented[topCommentedIdx]
                    : _currentPost;
    if (post == null) return;

    final wasLiked = post.isLikedByCurrentUser;
    final updated = post.copyWith(
      isLikedByCurrentUser: !wasLiked,
      likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
    );

    // Optimistic update across all lists
    if (feedIdx != -1) _feed = List.from(_feed)..[feedIdx] = updated;
    if (topScoreIdx != -1) _topScore = List.from(_topScore)..[topScoreIdx] = updated;
    if (topLikedIdx != -1) _topLiked = List.from(_topLiked)..[topLikedIdx] = updated;
    if (topCommentedIdx != -1) _topCommented = List.from(_topCommented)..[topCommentedIdx] = updated;
    if (isCurrentPost) _currentPost = updated;
    notifyListeners();

    try {
      if (wasLiked) {
        await SocialService.instance.unlikePost(postId);
      } else {
        await SocialService.instance.likePost(postId);
      }
    } on ApiError {
      // Revert on failure across all lists
      if (feedIdx != -1) _feed = List.from(_feed)..[feedIdx] = post;
      if (topScoreIdx != -1) _topScore = List.from(_topScore)..[topScoreIdx] = post;
      if (topLikedIdx != -1) _topLiked = List.from(_topLiked)..[topLikedIdx] = post;
      if (topCommentedIdx != -1) _topCommented = List.from(_topCommented)..[topCommentedIdx] = post;
      if (isCurrentPost) _currentPost = post;
      notifyListeners();
    }
  }

  // ── Share evaluation as post ──────────────────────────────────────────────────

  Future<SocialPost?> shareEvaluation({
    required String evaluationId,
    String? title,
    String? description,
  }) async {
    _error = null;
    try {
      final post = await SocialService.instance.createPost(
        evaluationId: evaluationId,
        title: title,
        description: description,
      );
      _feed = [post, ..._feed];
      notifyListeners();
      return post;
    } on ApiError catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Delete post ───────────────────────────────────────────────────────────────

  Future<bool> deletePost(String postId) async {
    try {
      await SocialService.instance.deletePost(postId);
      _feed.removeWhere((p) => p.id == postId);
      if (_currentPost?.id == postId) _currentPost = null;
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Comments ──────────────────────────────────────────────────────────────────

  Future<void> loadComments(String postId) async {
    _commentsLoading = true;
    _commentsPage = 1;
    _error = null;
    notifyListeners();
    try {
      final result = await SocialService.instance.getComments(
        postId: postId,
        page: 1,
      );
      _comments = result.items;
      _commentsHasMore = result.hasMore;
    } on ApiError catch (e) {
      _error = e.toString();
    } finally {
      _commentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreComments(String postId) async {
    if (_commentsLoadingMore || !_commentsHasMore) return;
    _commentsLoadingMore = true;
    notifyListeners();
    try {
      final result = await SocialService.instance.getComments(
        postId: postId,
        page: _commentsPage + 1,
      );
      _commentsPage++;
      _comments = [..._comments, ...result.items];
      _commentsHasMore = result.hasMore;
    } on ApiError catch (e) {
      _error = e.toString();
    } finally {
      _commentsLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final comment = await SocialService.instance.addComment(
        postId: postId,
        content: content,
      );
      _comments = [..._comments, comment];
      // Optimistically increment commentsCount on current post
      if (_currentPost?.id == postId) {
        _currentPost = _currentPost!.copyWith(
          commentsCount: _currentPost!.commentsCount + 1,
        );
      }
      final idx = _feed.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _feed = List.from(_feed)
          ..[idx] = _feed[idx].copyWith(commentsCount: _feed[idx].commentsCount + 1);
      }
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    try {
      await SocialService.instance.deleteComment(commentId);
      _comments.removeWhere((c) => c.id == commentId);
      notifyListeners();
      return true;
    } on ApiError catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearCurrentPost() {
    _currentPost = null;
    _comments = [];
    _commentsPage = 1;
    _commentsHasMore = true;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
