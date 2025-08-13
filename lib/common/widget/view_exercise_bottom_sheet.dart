import 'package:flutter/material.dart';

import '../../utils/color_constant.dart';

class ViewExerciseBottomSheet extends StatelessWidget {
  const ViewExerciseBottomSheet({
    super.key,
    required this.exerciseName,
    required this.icon,
    this.description,
  });
  final String exerciseName;
  final String icon;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            exerciseName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: Image.asset(icon)),
          const SizedBox(height: 10),
          Text(
            description ??
                "This is a demonstration of the $exerciseName exercise. "
                    "You can perform this exercise by following the instructions provided in the image above.",
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

void showViewExerciseBottomSheet(
  BuildContext context,
  String exerciseName,
  String icon,
  String? description,
) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    backgroundColor: BackgroundColor.white,
    builder: (_) {
      return ViewExerciseBottomSheet(
        exerciseName: exerciseName,
        icon: icon,
        description: description,
      );
    },
  );
}
