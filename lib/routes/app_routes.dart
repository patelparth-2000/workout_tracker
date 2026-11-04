import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../src/active_workout/view/active_workout_screen.dart';
import '../src/exercises/view/exercise_detail_screen.dart';
import '../src/exercises/view/exercise_edit_screen.dart';
import '../src/exercises/view/exercise_picker_screen.dart';
import '../src/exercises/view/exercises_screen.dart';
import '../src/history/view/history_screen.dart';
import '../src/history/view/session_detail_screen.dart';
import '../src/progress/view/progress_screen.dart';
import '../src/settings/view/plate_calculator_screen.dart';
import '../src/settings/view/settings_screen.dart';
import '../src/shell/view/app_shell.dart';
import '../src/startup/view/startup_screen.dart';
import '../src/workout/view/routine_edit_screen.dart';
import '../src/workout/view/workout_home_screen.dart';

// Do NOT use these for navigation.
class _AppPaths {
  static const String startup = '/startup';
  static const String workout = '/workout';
  static const String history = '/history';
  static const String exercises = '/exercises';
  static const String progress = '/progress';
  static const String settings = '/settings';
  static const String exercisePicker = '/pick-exercise';
  static const String activeWorkout = '/active';
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
  static const String activeWorkout = 'activeWorkout';
  static const String routineNew = 'routineNew';
  static const String sessionDetail = 'sessionDetail';
  static const String plateCalculator = 'plateCalculator';
  static const String routineEdit = 'routineEdit';
  static const String exerciseNew = 'exerciseNew';
  static const String exerciseDetail = 'exerciseDetail';
  static const String exerciseEdit = 'exerciseEdit';

  /// Pops with the chosen exercise id: `await context.pushNamed<int>(exercisePicker)`.
  static const String exercisePicker = 'exercisePicker';
}

/// Reads an integer path parameter. Malformed ids become -1 (renders "not found").
int _id(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '') ?? -1;

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
      GoRoute(
        path: _AppPaths.exercisePicker,
        name: RouteNames.exercisePicker,
        builder: (context, state) => const ExercisePickerScreen(),
      ),
      GoRoute(
        path: _AppPaths.activeWorkout,
        name: RouteNames.activeWorkout,
        builder: (context, state) => const ActiveWorkoutScreen(),
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
                routes: [
                  GoRoute(
                    path: 'routine/new',
                    name: RouteNames.routineNew,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const RoutineEditScreen(),
                  ),
                  GoRoute(
                    path: 'routine/:routineId',
                    name: RouteNames.routineEdit,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        RoutineEditScreen(routineId: _id(state, 'routineId')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _AppPaths.history,
                name: RouteNames.history,
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':sessionId',
                    name: RouteNames.sessionDetail,
                    builder: (context, state) =>
                        SessionDetailScreen(sessionId: _id(state, 'sessionId')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _AppPaths.exercises,
                name: RouteNames.exercises,
                builder: (context, state) => const ExercisesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: RouteNames.exerciseNew,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ExerciseEditScreen(),
                  ),
                  GoRoute(
                    path: ':exerciseId',
                    name: RouteNames.exerciseDetail,
                    builder: (context, state) => ExerciseDetailScreen(
                      exerciseId: _id(state, 'exerciseId'),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: RouteNames.exerciseEdit,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => ExerciseEditScreen(
                          exerciseId: _id(state, 'exerciseId'),
                        ),
                      ),
                    ],
                  ),
                ],
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
                routes: [
                  GoRoute(
                    path: 'plates',
                    name: RouteNames.plateCalculator,
                    builder: (context, state) => const PlateCalculatorScreen(),
                  ),
                ],
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
