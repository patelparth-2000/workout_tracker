import 'package:flutter/material.dart';

import '../../../common/widget/empty_state.dart';

/// Tab placeholder until the feature lands.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const EmptyState(
        icon: Icons.settings,
        title: 'Settings',
        message: 'Coming soon.',
      ),
    );
  }
}
