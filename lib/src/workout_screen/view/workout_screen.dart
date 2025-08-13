import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/common_function.dart';
import '../../../common/widget/show_toast.dart';
import '../../../utils/color_constant.dart';
import '../../workout_list_screen/viewmodel/workout_list_provider.dart';
import '../model/workout_model.dart';
import '../viewmodel/workout_provider.dart';
import 'widget/list_widget.dart';
import 'widget/text_field_widget.dart';
import 'widget/text_widget.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key, this.workout});
  final WorkoutModel? workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(workoutProviderProvider);
    final workoutListNotifier = ref.read(workoutListProvider.notifier);
    final workoutNotifier = ref.read(workoutProviderProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (workout != null && selectedIndex == null) {
        final typeIndex = workoutTypes.indexWhere(
          (type) => type['name'] == workout!.type,
        );
        if (typeIndex != -1) {
          workoutNotifier.selectWorkout(typeIndex);
        }
        workoutNotifier.weightController.text = workout!.weight;
        workoutNotifier.repsController.text = workout!.reps;
        workoutNotifier.setsController.text = workout!.sets;
      }
    });

    return Scaffold(
      backgroundColor: BackgroundColor.white,
      appBar: AppBar(
        title: Text(
          workout != null ? 'Edit Workout' : 'Add Workout',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: TextColor.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: BackgroundColor.white,
        scrolledUnderElevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextWidget(text: "Select a workout type:"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: BackgroundColor.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: BorderColor.black, width: 1),
                  ),
                  child: ListWidget(
                    workoutTypes: workoutTypes,
                    selectedIndex: selectedIndex ?? -1,
                    onSelectWorkout: (index) {
                      workoutNotifier.selectWorkout(index);
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextWidget(text: "Select weight:"),
            TextFieldWidget(
              controller: workoutNotifier.weightController,
              hintText: 'Enter weight',
              labelText: 'Weight (kg)',
            ),
            SizedBox(height: 16),
            TextWidget(text: "Select Repetitions:"),
            TextFieldWidget(
              controller: workoutNotifier.repsController,
              hintText: 'Repetitions',
              labelText: 'Enter number of repetitions',
            ),
            SizedBox(height: 16),
            TextWidget(text: "Select Sets:"),
            TextFieldWidget(
              controller: workoutNotifier.setsController,
              hintText: 'Sets',
              labelText: 'Enter number of sets',
            ),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(350, 50),
                backgroundColor: BackgroundColor.blue,
                foregroundColor: IconColor.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: BorderColor.grey, width: 1),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                if (selectedIndex == null || selectedIndex < 0) {
                  showToast(message: 'Please select a workout type');
                  return;
                }
                if (workoutNotifier.weightController.text.isEmpty ||
                    workoutNotifier.repsController.text.isEmpty ||
                    workoutNotifier.setsController.text.isEmpty) {
                  showToast(message: 'Please fill in all fields');
                  return;
                }

                final newWorkout = WorkoutModel(
                  description: workoutTypes[selectedIndex]['description'] ?? '',
                  icon: workoutTypes[selectedIndex]['icon'] ?? '',
                  type: workoutTypes[selectedIndex]['name'] ?? '',
                  weight: workoutNotifier.weightController.text,
                  reps: workoutNotifier.repsController.text,
                  sets: workoutNotifier.setsController.text,
                );

                if (workout != null) {
                  workoutListNotifier.updateWorkout(workout!, newWorkout);
                  showToast(message: 'Workout updated successfully');
                } else {
                  workoutListNotifier.addWorkout(newWorkout);
                  showToast(message: 'Workout added successfully');
                }

                workoutNotifier.selectWorkout(-1);
                workoutNotifier.weightController.clear();
                workoutNotifier.repsController.clear();
                workoutNotifier.setsController.clear();

                context.pop();
              },
              child: Text(workout != null ? 'Update Workout' : 'Save Workout'),
            ),
          ],
        ),
      ),
    );
  }
}
