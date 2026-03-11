import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:daef/models/user.dart';
import 'package:daef/models/social_post.dart';
import 'package:daef/providers/auth_provider.dart';
import 'package:daef/providers/social_provider.dart';
import 'package:daef/services/auth_service.dart';
import 'package:daef/services/social_service.dart';
import 'package:daef/utils/date_formatter.dart';
import 'package:daef/widgets/loading_indicator.dart';
import 'package:daef/widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({this.userId, super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _profileUser;
  bool _loadingUser = false;
  String? _error;

  bool get _isOwnProfile {
    final currentUserId = context.read<AuthProvider>().user?.id;
    return widget.userId == null || widget.userId == currentUserId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loadingUser = true);
    try {
      if (_isOwnProfile) {
        _profileUser = context.read<AuthProvider>().user;
      } else {
        _profileUser = await AuthService.instance.getUserById(widget.userId!);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loadingUser = false);
    }

  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final user = _isOwnProfile ? currentUser : _profileUser;

    if (_loadingUser) return const Scaffold(body: LoadingIndicator());
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading: _isOwnProfile ? null : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text(_error!)),
      );
    }
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isOwnProfile ? 'My Profile' : user.displayName),
        leading: _isOwnProfile
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        actions: [
          if (_isOwnProfile) ...[
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/notifications'),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 56),
          children: [
            // Avatar + name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      user.initials,
                      style: tt.headlineMedium?.copyWith(
                          color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName,
                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '@${user.username}',
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Member since ${DateFormatter.formatted(user.createdAt)}',
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats / posts section
            Text(
              'Posts',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _UserPostsList(userId: user.id, isOwn: _isOwnProfile),
          ],
        ),
      ),
    );
  }
}

class _UserPostsList extends StatefulWidget {
  final String userId;
  final bool isOwn;

  const _UserPostsList({required this.userId, required this.isOwn});

  @override
  State<_UserPostsList> createState() => _UserPostsListState();
}

class _UserPostsListState extends State<_UserPostsList> {
  List<SocialPost> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await SocialService.instance.getUserPosts(userId: widget.userId);
      setState(() => _posts = result.items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) return const InlineLoader();
    if (_error != null) {
      return Text(_error!, style: TextStyle(color: cs.error));
    }
    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(Icons.post_add_outlined, size: 48, color: cs.outline),
              const SizedBox(height: 12),
              Text(
                widget.isOwn
                    ? 'You haven\'t shared any evaluations yet'
                    : 'No posts yet',
                style: tt.bodyMedium?.copyWith(color: cs.outline),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _posts.map((post) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PostCard(
            post: post,
            onTap: () => context.push('/social/posts/${post.id}'),
            onLike: () => context.read<SocialProvider>().toggleLike(post.id),
          ),
        );
      }).toList(),
    );
  }
}
