import 'package:flutter/foundation.dart';
import 'package:daef/models/notification.dart';
import 'package:daef/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  String? get error => _error;

  // ── Fetch unread count only (used for badge in shell) ────────────────────────

  Future<void> refreshUnreadCount() async {
    try {
      _unreadCount = await NotificationService.instance.getUnreadCount();
      notifyListeners();
    } catch (_) {
      // Silently ignore — badge will just show stale count
    }
  }

  // ── Load full notification list ───────────────────────────────────────────────

  Future<void> load({bool unreadOnly = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await NotificationService.instance.getNotifications(
        unreadOnly: unreadOnly,
      );
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Mark single notification read ─────────────────────────────────────────────

  Future<void> markRead(String id) async {
    try {
      await NotificationService.instance.markRead(id);
      _notifications = _notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (_) {}
  }

  // ── Mark all read ─────────────────────────────────────────────────────────────

  Future<void> markAllRead() async {
    try {
      await NotificationService.instance.markAllRead();
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
