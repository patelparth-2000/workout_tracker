import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_tracker/src/workout_screen/model/workout_model.dart';

import '../../../../common/widget/view_exercise_bottom_sheet.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/color_constant.dart';
import '../../../../utils/images.dart';
import 'button_widget.dart';
import 'list_text_wigdet.dart';

class ListWidget extends StatelessWidget {
  const ListWidget({
    super.key,
    required this.workouts,
    required this.onDeleteButtonPressed,
  });
  final List<WorkoutModel> workouts;
  final Function() onDeleteButtonPressed;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return ListTile(
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ButtonWidget(
                icon: Images().editIcon,
                color: IconColor.blue,
                onPressed: () {
                  context.pushNamed(RouteNames.workoutScreen, extra: workout);
                },
              ),
              ButtonWidget(
                icon: Images().viewIcon,
                color: IconColor.green,
                onPressed: () => showViewExerciseBottomSheet(
                  context,
                  workout.type,
                  workout.icon,
                  workout.description,
                ),
              ),
              ButtonWidget(
                icon: Images().deleteIcon,
                color: IconColor.red,
                onPressed: onDeleteButtonPressed,
              ),
            ],
          ),
          title: Text(
            workout.type,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: TextColor.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            children: [
              ListTextWigdet(text: 'Weight', value: workout.weight),
              ListTextWigdet(text: 'Repetitions', value: workout.reps),
              ListTextWigdet(text: 'Sets', value: workout.sets),
            ],
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Divider(color: BorderColor.grey, height: 1),
        );
      },
    );
  }
}
