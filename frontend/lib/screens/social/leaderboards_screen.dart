import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:daef/models/social_post.dart';
import 'package:daef/providers/social_provider.dart';
import 'package:daef/widgets/loading_indicator.dart';
import 'package:daef/widgets/post_card.dart';

class LeaderboardsScreen extends StatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  State<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends State<LeaderboardsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadLeaderboards();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SocialProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Evaluations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SocialProvider>().loadLeaderboards(),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Top Score', icon: Icon(Icons.star_outline, size: 18)),
            Tab(text: 'Most Liked', icon: Icon(Icons.favorite_border, size: 18)),
            Tab(text: 'Discussed', icon: Icon(Icons.chat_bubble_outline, size: 18)),
          ],
        ),
      ),
      body: provider.leaderboardLoading
          ? const LoadingIndicator(message: 'Loading leaderboards...')
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _LeaderboardList(posts: provider.topScore),
                _LeaderboardList(posts: provider.topLiked),
                _LeaderboardList(posts: provider.topCommented),
              ],
            ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<SocialPost> posts;
  const _LeaderboardList({required this.posts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text('No data yet', style: tt.titleMedium?.copyWith(color: cs.outline)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, right: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: index < 3
                      ? [
                          const Color(0xFFFFD700),
                          const Color(0xFFC0C0C0),
                          const Color(0xFFCD7F32),
                        ][index]
                      : cs.surfaceContainerHighest,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: index < 3 ? Colors.black : cs.onSurface,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PostCard(
                  post: post,
                  onTap: () => context.push('/social/posts/${post.id}'),
                  onLike: () => context.read<SocialProvider>().toggleLike(post.id),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
