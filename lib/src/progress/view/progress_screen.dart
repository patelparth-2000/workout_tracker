import 'package:flutter/material.dart';

import '../../../common/widget/empty_state.dart';

/// Tab placeholder until the feature lands.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const EmptyState(
        icon: Icons.insights,
        title: 'No progress yet',
        message: 'Coming soon.',
      ),
    );
  }
}
