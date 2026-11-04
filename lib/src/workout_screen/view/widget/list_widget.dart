import 'package:flutter/material.dart';
import 'package:workout_tracker/utils/color_constant.dart';

import '../../../../common/widget/view_exercise_bottom_sheet.dart';
import '../../../../utils/images.dart';

/// This widget displays a list of workout types with options to view details.
class ListWidget extends StatelessWidget {
  const ListWidget({
    super.key,
    required this.workoutTypes,
    required this.selectedIndex,
    required this.onSelectWorkout,
  });
  final List<Map<String, String>> workoutTypes;
  final int selectedIndex;
  final Function(int) onSelectWorkout;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: workoutTypes.length,
      itemBuilder: (context, index) {
        final isSelected = selectedIndex == index;
        return GestureDetector(
          onTap: () => onSelectWorkout(index),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? BackgroundColor.blue : BackgroundColor.white,
              borderRadius: index == 0
                  ? BorderRadius.vertical(top: Radius.circular(20))
                  : index == workoutTypes.length - 1
                  ? BorderRadius.vertical(bottom: Radius.circular(20))
                  : BorderRadius.zero,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  workoutTypes[index]['name']!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isSelected ? TextColor.white : TextColor.black,
                  ),
                ),
                Spacer(),
                IconButton(
                  tooltip: "view exercise",
                  onPressed: () => showViewExerciseBottomSheet(
                    context,
                    workoutTypes[index]['name']!,
                    workoutTypes[index]['icon']!,
                    workoutTypes[index]['description'],
                  ),
                  icon: Icon(Images.viewIcon, color: IconColor.green),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(color: DividerColor.black, height: 1);
      },
    );
  }
}
