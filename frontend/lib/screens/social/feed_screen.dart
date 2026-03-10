import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:daef/providers/social_provider.dart';
import 'package:daef/widgets/loading_indicator.dart';
import 'package:daef/widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadFeed();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<SocialProvider>().loadMoreFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SocialProvider>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SocialProvider>().loadFeed(),
          ),
        ],
      ),
      body: _buildBody(provider, tt, cs),
    );
  }

  Widget _buildBody(SocialProvider provider, TextTheme tt, ColorScheme cs) {
    if (provider.feedLoading) return const LoadingIndicator(message: 'Loading feed...');

    if (provider.feed.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dynamic_feed_outlined, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text('No posts yet', style: tt.titleMedium?.copyWith(color: cs.outline)),
            const SizedBox(height: 8),
            Text(
              'Share an evaluation to get started',
              style: tt.bodyMedium?.copyWith(color: cs.outline),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SocialProvider>().loadFeed(),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(12),
        itemCount: provider.feed.length + (provider.feedLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.feed.length) return const InlineLoader();
          final post = provider.feed[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PostCard(
              post: post,
              onTap: () => context.push('/social/posts/${post.id}'),
              onLike: () => context.read<SocialProvider>().toggleLike(post.id),
            ),
          );
        },
      ),
    );
  }
}
