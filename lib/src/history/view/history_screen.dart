import 'package:flutter/material.dart';

import '../../../common/widget/empty_state.dart';

/// Tab placeholder until the feature lands.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: const EmptyState(
        icon: Icons.history,
        title: 'No workouts yet',
        message: 'Coming soon.',
      ),
    );
  }
}
