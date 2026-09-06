import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/learner_provider.dart';
import '../screens/communicate/communicate_screen.dart';
import '../screens/home/app_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/learn/lesson_detail_screen.dart';
import '../screens/learn/lesson_list_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/practice/practice_screen.dart';
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
///   /practice             → practice (full screen)
///   /communicate          → communication mode (full screen)
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isOnboarded = ref.read(learnerStateProvider).isOnboarded;
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      if (!isOnboarded && !goingToOnboarding) {
        return '/onboarding';
      }
      if (isOnboarded && goingToOnboarding) {
        return '/home';
      }
      return null;
    },
    routes: [
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
        builder: (context, state) => const PracticeScreen(),
      ),
      GoRoute(
        path: '/communicate',
        builder: (context, state) => const CommunicateScreen(),
      ),
    ],
  );
});