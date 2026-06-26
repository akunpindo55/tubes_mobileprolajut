import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/forum/presentation/screens/forum_detail_screen.dart';
import '../features/forum/presentation/screens/topic_detail_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/report/presentation/screens/report_screen.dart';
import '../features/notification/presentation/screens/notification_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!authState.isAuthenticated) {
        // If not logged in and trying to access protected routes, redirect to login
        return isLoggingIn ? null : '/login';
      }

      // If logged in and trying to access login/register, redirect to dashboard
      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ChatScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: '/forum/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ForumDetailScreen(forumId: id);
        },
      ),
      GoRoute(
        path: '/topic/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return TopicDetailScreen(topicId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:username',
        builder: (context, state) {
          final username = state.pathParameters['username'] ?? '';
          return ProfileScreen(username: username);
        },
      ),
      GoRoute(
        path: '/report/:type/:id',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'post';
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ReportScreen(reportableType: type, reportableId: id);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
});
