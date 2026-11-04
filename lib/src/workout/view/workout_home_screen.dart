import 'package:flutter/material.dart';

import '../../../common/widget/empty_state.dart';

/// Tab placeholder until the feature lands.
class WorkoutHomeScreen extends StatelessWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: const EmptyState(
        icon: Icons.fitness_center,
        title: 'Start a workout',
        message: 'Coming soon.',
      ),
    );
  }
}
