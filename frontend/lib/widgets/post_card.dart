import 'package:flutter/material.dart';
import 'package:daef/models/social_post.dart';
import 'package:daef/utils/date_formatter.dart';
import 'package:daef/utils/helpers.dart';

class PostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;

  const PostCard({required this.post, this.onTap, this.onLike, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = post;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author + date
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      p.username.isNotEmpty ? p.username[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.username,
                          style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          DateFormatter.relative(p.createdAt),
                          style: tt.bodySmall?.copyWith(color: cs.outline),
                        ),
                      ],
                    ),
                  ),
                  if (p.overallScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Helpers.scoreColor(p.overallScore, context).withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        Helpers.formatScore(p.overallScore),
                        style: tt.labelLarge?.copyWith(
                          color: Helpers.scoreColor(p.overallScore, context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Title + description
              if (p.title != null && p.title!.isNotEmpty) ...[
                Text(
                  p.title!,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              if (p.description != null && p.description!.isNotEmpty)
                Text(
                  p.description!,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 10),
              // Tags + engagement
              Row(
                children: [
                  if (p.domain != null)
                    _TagChip(label: p.domain!),
                  if (p.taskType != null) ...[
                    const SizedBox(width: 6),
                    _TagChip(label: Helpers.taskTypeLabel(p.taskType)),
                  ],
                  const Spacer(),
                  // Like button
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            p.isLikedByCurrentUser
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: p.isLikedByCurrentUser ? cs.error : cs.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.likesCount}',
                            style: tt.bodySmall?.copyWith(
                              color: p.isLikedByCurrentUser ? cs.error : cs.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 18, color: cs.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${p.commentsCount}',
                        style: tt.bodySmall?.copyWith(color: cs.outline),
                      ),
                    ],
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
