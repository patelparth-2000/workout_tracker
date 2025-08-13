import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/src/workout_screen/viewmodel/workout_provider.dart';

void main() {
  group('WorkoutProvider', () {
    test('should initialize with null state and controllers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(workoutProviderProvider.notifier);
      final state = container.read(workoutProviderProvider);

      expect(state, isNull);
      expect(provider.weightController, isNotNull);
      expect(provider.repsController, isNotNull);
      expect(provider.setsController, isNotNull);
    });

    test('should update state when selectWorkout is called', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(workoutProviderProvider.notifier);

      provider.selectWorkout(2);

      expect(container.read(workoutProviderProvider), 2);
    });
  });
}