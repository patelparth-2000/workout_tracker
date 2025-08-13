import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_provider.g.dart';

@riverpod
class WorkoutProvider extends _$WorkoutProvider {
  late final TextEditingController weightController;
  late final TextEditingController repsController;
  late final TextEditingController setsController;

  @override
  int? build() {
    weightController = TextEditingController();
    repsController = TextEditingController();
    setsController = TextEditingController();
    ref.onDispose(() {
      weightController.dispose();
      repsController.dispose();
      setsController.dispose();
    });
    return null; // Initially, no workout is selected
  }

  void selectWorkout(int index) {
    state = index;
  }
}
