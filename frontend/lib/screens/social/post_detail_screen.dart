import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:daef/providers/auth_provider.dart';
import 'package:daef/providers/social_provider.dart';
import 'package:daef/utils/date_formatter.dart';
import 'package:daef/utils/helpers.dart';
import 'package:daef/widgets/comment_widget.dart';
import 'package:daef/widgets/loading_indicator.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({required this.postId, super.key});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SocialProvider>();
      provider.loadPost(widget.postId);
      provider.loadComments(widget.postId);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    context.read<SocialProvider>().clearCurrentPost();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<SocialProvider>().loadMoreComments(widget.postId);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    final success = await context
        .read<SocialProvider>()
        .addComment(postId: widget.postId, content: content);
    if (success) _commentCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SocialProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final post = provider.currentPost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (post != null && post.userId == currentUserId)
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              onPressed: () async {
                final nav = GoRouter.of(context);
                final provider = context.read<SocialProvider>();
                final ok = await provider.deletePost(post.id);
                if (ok) nav.pop();
              },
            ),
        ],
      ),
      body: post == null
          ? const LoadingIndicator()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Post header
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              post.username.isNotEmpty ? post.username[0].toUpperCase() : '?',
                              style: TextStyle(
                                  color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => context.push('/profile/${post.userId}'),
                                  child: Text(
                                    post.username,
                                    style: tt.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold, color: cs.primary),
                                  ),
                                ),
                                Text(
                                  DateFormatter.formatted(post.createdAt),
                                  style: tt.bodySmall?.copyWith(color: cs.outline),
                                ),
                              ],
                            ),
                          ),
                          if (post.overallScore != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Helpers.scoreColor(post.overallScore, context).withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                Helpers.formatScore(post.overallScore),
                                style: tt.titleMedium?.copyWith(
                                  color: Helpers.scoreColor(post.overallScore, context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (post.title != null && post.title!.isNotEmpty)
                        Text(post.title!,
                            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      if (post.description != null && post.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(post.description!, style: tt.bodyLarge),
                      ],
                      const SizedBox(height: 16),

                      // Tags
                      Row(
                        children: [
                          if (post.domain != null) _Tag(post.domain!),
                          if (post.taskType != null) ...[
                            const SizedBox(width: 8),
                            _Tag(Helpers.taskTypeLabel(post.taskType)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Like + comment counts
                      Row(
                        children: [
                          InkWell(
                            onTap: () =>
                                context.read<SocialProvider>().toggleLike(post.id),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Icon(
                                    post.isLikedByCurrentUser
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: post.isLikedByCurrentUser ? cs.error : cs.outline,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Text('${post.likesCount}', style: tt.bodyMedium),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.chat_bubble_outline, color: cs.outline, size: 22),
                          const SizedBox(width: 6),
                          Text('${post.commentsCount}', style: tt.bodyMedium),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('View Evaluation'),
                            onPressed: () => context.push('/evaluations/${post.evaluationId}'),
                          ),
                        ],
                      ),
                      const Divider(),

                      // Comments
                      Text('Comments',
                          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (provider.commentsLoading)
                        const InlineLoader()
                      else if (provider.comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No comments yet. Be the first!',
                            style: tt.bodyMedium?.copyWith(color: cs.outline),
                          ),
                        )
                      else ...[
                        ...provider.comments.map(
                          (c) => CommentWidget(
                            comment: c,
                            canDelete: c.userId == currentUserId,
                            onDelete: () => context.read<SocialProvider>().deleteComment(
                                  commentId: c.id,
                                  postId: widget.postId,
                                ),
                          ),
                        ),
                        if (provider.commentsLoadingMore) const InlineLoader(),
                      ],
                    ],
                  ),
                ),
                // Comment input
                Container(
                  padding: EdgeInsets.fromLTRB(
                      16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(top: BorderSide(color: cs.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send, color: cs.primary),
                        onPressed: _submitComment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
    );
  }
}
