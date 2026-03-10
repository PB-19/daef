import 'package:flutter/material.dart';
import 'package:daef/config/constants.dart';

class Helpers {
  // ── Score helpers ─────────────────────────────────────────────────────────────

  static Color scoreColor(double? score, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (score == null) return cs.outline;
    if (score >= 80) return const Color(0xFF2E7D32); // green
    if (score >= 60) return const Color(0xFFE65100); // amber/orange
    return cs.error;
  }

  static String scoreLabel(double? score) {
    if (score == null) return '—';
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 60) return 'Fair';
    if (score >= 40) return 'Poor';
    return 'Critical';
  }

  static String formatScore(double? score) {
    if (score == null) return '—';
    return score.toStringAsFixed(1);
  }

  // ── Evaluation status helpers ─────────────────────────────────────────────────

  static Color statusColor(String status, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      EvalStatus.completed => const Color(0xFF2E7D32),
      EvalStatus.failed => cs.error,
      EvalStatus.processing => cs.primary,
      _ => cs.outline, // pending
    };
  }

  static String statusLabel(String status) => switch (status) {
        EvalStatus.pending => 'Pending',
        EvalStatus.processing => 'Processing',
        EvalStatus.completed => 'Completed',
        EvalStatus.failed => 'Failed',
        _ => status,
      };

  static IconData statusIcon(String status) => switch (status) {
        EvalStatus.completed => Icons.check_circle_outline,
        EvalStatus.failed => Icons.error_outline,
        EvalStatus.processing => Icons.sync,
        _ => Icons.schedule, // pending
      };

  // ── Task type helpers ─────────────────────────────────────────────────────────

  static String taskTypeLabel(String? taskType) =>
      TaskTypes.displayNames[taskType] ?? taskType ?? '—';

  // ── Performance change helpers ────────────────────────────────────────────────

  static Color performanceColor(String? change, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (change) {
      PerformanceChange.better => const Color(0xFF2E7D32),
      PerformanceChange.worse => cs.error,
      _ => cs.outline,
    };
  }

  static IconData performanceIcon(String? change) => switch (change) {
        PerformanceChange.better => Icons.trending_up,
        PerformanceChange.worse => Icons.trending_down,
        _ => Icons.trending_flat,
      };

  // ── Notification type helpers ─────────────────────────────────────────────────

  static IconData notifIcon(String type) => switch (type) {
        NotifType.evalComplete => Icons.assessment_outlined,
        NotifType.like => Icons.favorite_border,
        NotifType.comment => Icons.chat_bubble_outline,
        _ => Icons.notifications_outlined,
      };
}
