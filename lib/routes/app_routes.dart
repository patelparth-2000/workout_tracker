import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../src/exercises/view/exercises_screen.dart';
import '../src/history/view/history_screen.dart';
import '../src/progress/view/progress_screen.dart';
import '../src/settings/view/settings_screen.dart';
import '../src/shell/view/app_shell.dart';
import '../src/startup/view/startup_screen.dart';
import '../src/workout/view/workout_home_screen.dart';

// Do NOT use these for navigation.
class _AppPaths {
  static const String startup = '/startup';
  static const String workout = '/workout';
  static const String history = '/history';
  static const String exercises = '/exercises';
  static const String progress = '/progress';
  static const String settings = '/settings';
}

/// Use these for named navigation. Arguments travel as path parameters (ids), never as
/// objects in `extra:` (ARCHITECTURE §5).
class RouteNames {
  static const String startup = 'startup';
  static const String workout = 'workout';
  static const String history = 'history';
  static const String exercises = 'exercises';
  static const String progress = 'progress';
  static const String settings = 'settings';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The one hand-written provider in the app (house rule).
final goRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: _AppPaths.startup,
    routes: [
      GoRoute(
        path: _AppPaths.startup,
        name: RouteNames.startup,
        builder: (context, state) => const StartupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _AppPaths.workout,
                name: RouteNames.workout,
                builder: (context, state) => const WorkoutHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _AppPaths.history,
                name: RouteNames.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _AppPaths.exercises,
                name: RouteNames.exercises,
                builder: (context, state) => const ExercisesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _AppPaths.progress,
                name: RouteNames.progress,
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _AppPaths.settings,
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
