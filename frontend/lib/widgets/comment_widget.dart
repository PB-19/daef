import 'package:flutter/material.dart';
import 'package:daef/models/social_post.dart';
import 'package:daef/utils/date_formatter.dart';

class CommentWidget extends StatelessWidget {
  final Comment comment;
  final bool canDelete;
  final VoidCallback? onDelete;

  const CommentWidget({
    required this.comment,
    this.canDelete = false,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.secondaryContainer,
            child: Text(
              comment.username.isNotEmpty
                  ? comment.username[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: cs.onSecondaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.relative(comment.createdAt),
                      style: tt.bodySmall?.copyWith(color: cs.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.content, style: tt.bodyMedium),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
