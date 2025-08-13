import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_tracker/common/widget/show_toast.dart';
import 'package:workout_tracker/routes/app_routes.dart';
import 'package:workout_tracker/src/workout_list_screen/view/widget/button_widget.dart';
import 'package:workout_tracker/utils/color_constant.dart';

import '../../../utils/images.dart';
import '../viewmodel/workout_list_provider.dart';
import 'widget/list_widget.dart';

class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutListProvider);
    return Scaffold(
      backgroundColor: BackgroundColor.white,
      appBar: AppBar(
        title: Text(
          'Workout List',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: TextColor.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: BackgroundColor.white,

        scrolledUnderElevation: 2,
        actions: [
          if (workouts.isNotEmpty)
            ButtonWidget(
              text: 'Clear All',
              color: IconColor.red,
              onPressed: () {
                ref.read(workoutListProvider.notifier).clearWorkouts();
                showToast(message: 'All workouts cleared');
              },
            ),
        ],
      ),
      body: workouts.isEmpty
          ? Center(
              child: Text(
                'No workouts added yet.',
                style: TextStyle(fontSize: 20, color: TextColor.black),
              ),
            )
          : ListWidget(
              workouts: workouts,
              onDeleteButtonPressed: (index) {
                ref.read(workoutListProvider.notifier).deleteWorkout(index);
                showToast(message: 'Workout deleted');
              },
            ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: BackgroundColor.blue,
        foregroundColor: IconColor.white,
        onPressed: () {
          context.pushNamed(RouteNames.workoutScreen);
        },
        child: Icon(Images().addIcon, size: 30),
      ),
    );
  }
}
