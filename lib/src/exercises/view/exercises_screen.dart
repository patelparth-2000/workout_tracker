import 'package:flutter/material.dart';

import '../../../common/widget/empty_state.dart';

/// Tab placeholder until the feature lands.
class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: const EmptyState(
        icon: Icons.list_alt,
        title: 'Exercise library',
        message: 'Coming soon.',
      ),
    );
  }
}
