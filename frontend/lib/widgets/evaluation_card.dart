import 'package:flutter/material.dart';
import 'package:daef/models/evaluation.dart';
import 'package:daef/utils/date_formatter.dart';
import 'package:daef/utils/helpers.dart';

class EvaluationCard extends StatelessWidget {
  final Evaluation evaluation;
  final VoidCallback? onTap;

  const EvaluationCard({required this.evaluation, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final e = evaluation;
    final statusColor = Helpers.statusColor(e.status, context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: domain + status chip
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.domain,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: e.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                e.taskDescription,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Footer: score + task type + date
              Row(
                children: [
                  if (e.overallScore != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Helpers.scoreColor(e.overallScore, context).withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        Helpers.formatScore(e.overallScore),
                        style: tt.labelLarge?.copyWith(
                          color: Helpers.scoreColor(e.overallScore, context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else if (e.isInProgress) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _TagChip(label: Helpers.taskTypeLabel(e.taskType)),
                  const Spacer(),
                  Text(
                    DateFormatter.relative(e.createdAt),
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Helpers.statusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            Helpers.statusLabel(status),
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      ),
    );
  }
}
