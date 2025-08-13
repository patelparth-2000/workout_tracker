import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_tracker/src/workout_list_screen/view/workout_list_screen.dart';
import 'package:workout_tracker/src/workout_screen/model/workout_model.dart';
import 'package:workout_tracker/src/workout_screen/view/workout_screen.dart';

import '../src/splash_screen/splash_screen.dart';

// Do NOT use these for navigation
class _AppPaths {
  static const String workoutScreen = '/workoutScreen';
  static const String workoutListScreen = '/workoutListScreen';
  static const String splashScreen = '/splashScreen';
}

// Use these for named navigation
class RouteNames {
  static const String workoutScreen = 'workoutScreen';
  static const String workoutListScreen = 'workoutListScreen';
  static const String splashScreen = 'splashScreen';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: _AppPaths.splashScreen,
    routes: [
      // Define routes here
      GoRoute(
        path: _AppPaths.splashScreen,
        name: RouteNames.splashScreen,
        builder: (context, state) => SplashScreen(),
      ),
      GoRoute(
        path: _AppPaths.workoutScreen,
        name: RouteNames.workoutScreen,
        builder: (context, state) =>
            WorkoutScreen(workout: state.extra as WorkoutModel?),
      ),
      GoRoute(
        path: _AppPaths.workoutListScreen,
        name: RouteNames.workoutListScreen,
        builder: (context, state) => WorkoutListScreen(),
      ),
    ],
  );
});
