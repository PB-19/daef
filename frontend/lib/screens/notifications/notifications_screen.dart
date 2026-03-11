import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:daef/providers/notification_provider.dart';
import 'package:daef/utils/date_formatter.dart';
import 'package:daef/utils/helpers.dart';
import 'package:daef/widgets/loading_indicator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (provider.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => context.read<NotificationProvider>().markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _buildBody(provider, cs, tt),
    );
  }

  Widget _buildBody(NotificationProvider provider, ColorScheme cs, TextTheme tt) {
    if (provider.loading) return const LoadingIndicator(message: 'Loading notifications...');

    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text('No notifications', style: tt.titleMedium?.copyWith(color: cs.outline)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<NotificationProvider>().load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 56),
        itemCount: provider.notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notif = provider.notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: notif.isRead ? cs.surfaceContainerHighest : cs.primaryContainer,
              child: Icon(
                Helpers.notifIcon(notif.type),
                color: notif.isRead ? cs.outline : cs.primary,
                size: 20,
              ),
            ),
            title: Text(
              notif.title,
              style: tt.titleSmall?.copyWith(
                fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.message, style: tt.bodySmall),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.relative(notif.createdAt),
                  style: tt.bodySmall?.copyWith(color: cs.outline),
                ),
              ],
            ),
            isThreeLine: true,
            tileColor: notif.isRead ? null : cs.primaryContainer.withAlpha(30),
            onTap: () {
              if (!notif.isRead) {
                context.read<NotificationProvider>().markRead(notif.id);
              }
              // Navigate to related content
              if (notif.relatedEvaluationId != null) {
                context.push('/evaluations/${notif.relatedEvaluationId}');
              } else if (notif.relatedPostId != null) {
                context.push('/social/posts/${notif.relatedPostId}');
              }
            },
          );
        },
      ),
    );
  }
}
