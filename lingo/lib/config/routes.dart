import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/camera/detection_camera_screen.dart';
import '../screens/communicate/communicate_screen.dart';
import '../screens/home/app_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/learn/lesson_detail_screen.dart';
import '../screens/learn/lesson_list_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/progress/progress_screen.dart';

/// Application router.
///
/// Route structure:
///   /                     → shell (tabs)
///   / (branch 0)          → lesson list
///   / (branch 1)          → home
///   / (branch 2)          → progress
///   /onboarding           → onboarding (redirects to / when onboarded)
///   /learn/:lessonId      → lesson detail
///   /practice?sign=:id    → practice (full screen, live camera)
///   /communicate          → communication mode (full screen, live camera)
final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects as Firebase restores or changes the user session.
  ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final signedIn = ref.read(authServiceProvider).currentUser != null;
      final onAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      if (!signedIn && !onAuthPage) return '/login';
      if (signedIn && onAuthPage) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(isSignUp: false),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const AuthScreen(isSignUp: true),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/learn',
              builder: (context, state) => const LessonListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/learn/:lessonId',
        builder: (context, state) =>
            LessonDetailScreen(lessonId: state.pathParameters['lessonId']!),
      ),
      GoRoute(
        path: '/practice',
        builder: (context, state) => DetectionCameraScreen(
          expectedSignId: state.uri.queryParameters['sign'],
        ),
      ),
      GoRoute(
        path: '/communicate',
        builder: (context, state) => const CommunicateScreen(),
      ),
    ],
  );
});
