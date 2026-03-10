import 'package:daef/models/notification.dart';
import 'package:daef/services/api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _client = ApiClient.instance;

  // ── Get notifications ─────────────────────────────────────────────────────────

  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    final response = await _client.get('/notifications', params: {
      'unread_only': unreadOnly,
      'limit': limit,
    });
    return (response.data as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Get unread count ──────────────────────────────────────────────────────────

  Future<int> getUnreadCount() async {
    final response = await _client.get('/notifications/unread-count');
    return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
  }

  // ── Mark single notification as read ─────────────────────────────────────────

  Future<void> markRead(String notificationId) async {
    await _client.patch('/notifications/$notificationId/read');
  }

  // ── Mark all notifications as read ───────────────────────────────────────────

  Future<void> markAllRead() async {
    await _client.patch('/notifications/read-all');
  }
}
