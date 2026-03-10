import 'package:go_router/go_router.dart';
import 'package:daef/providers/auth_provider.dart';
import 'package:daef/screens/auth/login_screen.dart';
import 'package:daef/screens/auth/register_screen.dart';
import 'package:daef/screens/evaluation/evaluation_list_screen.dart';
import 'package:daef/screens/evaluation/create_evaluation_screen.dart';
import 'package:daef/screens/evaluation/evaluation_detail_screen.dart';
import 'package:daef/screens/evaluation/evaluation_versions_screen.dart';
import 'package:daef/screens/evaluation/comparison_screen.dart';
import 'package:daef/screens/social/feed_screen.dart';
import 'package:daef/screens/social/leaderboards_screen.dart';
import 'package:daef/screens/social/post_detail_screen.dart';
import 'package:daef/screens/profile/profile_screen.dart';
import 'package:daef/screens/profile/settings_screen.dart';
import 'package:daef/screens/notifications/notifications_screen.dart';
import 'package:daef/screens/home/home_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final path = state.matchedLocation;
      final isAuthPath = path == '/login' || path == '/register';

      // Still determining auth state — don't redirect
      if (status == AuthStatus.unknown) return null;

      if (status == AuthStatus.unauthenticated && !isAuthPath) return '/login';
      if (status == AuthStatus.authenticated && isAuthPath) return '/';

      return null;
    },
    routes: [
      // ── Auth (full-screen, no shell) ───────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Full-screen routes (no bottom nav) ─────────────────────────────────
      GoRoute(
        path: '/evaluations/create',
        builder: (context, state) => const CreateEvaluationScreen(),
      ),
      GoRoute(
        path: '/evaluations/:id',
        builder: (context, state) => EvaluationDetailScreen(
          evaluationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/evaluations/:evalId/versions',
        builder: (context, state) => EvaluationVersionsScreen(
          evalId: state.pathParameters['evalId']!,
        ),
      ),
      GoRoute(
        path: '/comparisons/:id',
        builder: (context, state) => ComparisonScreen(
          versionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/social/posts/:id',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => ProfileScreen(
          userId: state.pathParameters['userId'],
        ),
      ),

      // ── Shell with bottom NavigationBar ────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const EvaluationListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/feed',
              builder: (context, state) => const FeedScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/leaderboards',
              builder: (context, state) => const LeaderboardsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/my-profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}
