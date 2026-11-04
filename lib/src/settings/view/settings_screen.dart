import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widget/async_value_view.dart';
import '../../../common/widget/section_header.dart';
import '../../../data/app_database.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/units.dart';
import '../../../utils/workout_math.dart';
import '../viewmodel/settings_provider.dart';
import 'widget/backup_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AsyncValueView<AppSettingsData>(
        value: settings,
        onRetry: () => ref.invalidate(currentSettingsProvider),
        data: (s) => _SettingsList(settings: s),
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.settings});

  final AppSettingsData settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);
    final rest = restChoices.contains(settings.defaultRestSeconds)
        ? restChoices
        : ([...restChoices, settings.defaultRestSeconds]..sort());
    return ListView(
      children: [
        const SectionHeader(title: 'Units'),
        Padding(
          padding: AppInsets.screenH,
          child: SegmentedButton<WeightUnit>(
            segments: const [
              ButtonSegment(
                value: WeightUnit.kg,
                label: Text('Kilograms (kg)'),
              ),
              ButtonSegment(value: WeightUnit.lb, label: Text('Pounds (lb)')),
            ],
            selected: {WeightUnit.fromName(settings.unit)},
            onSelectionChanged: (s) => controller.setUnit(s.single),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Text(
            'Weights are always stored in kg; switching only changes how they are shown.',
          ),
        ),
        const SectionHeader(title: 'Rest timer'),
        ListTile(
          title: const Text('Default rest'),
          subtitle: const Text(
            'Used when a routine sets no rest for an exercise',
          ),
          trailing: DropdownButton<int>(
            value: settings.defaultRestSeconds,
            items: [
              for (final s in rest)
                DropdownMenuItem(
                  value: s,
                  child: Text(formatClock(Duration(seconds: s))),
                ),
            ],
            onChanged: (v) {
              if (v != null) controller.setDefaultRest(v);
            },
          ),
        ),
        const SectionHeader(title: 'Appearance'),
        Padding(
          padding: AppInsets.screenH,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', label: Text('System')),
              ButtonSegment(value: 'light', label: Text('Light')),
              ButtonSegment(value: 'dark', label: Text('Dark')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => controller.setThemeMode(s.single),
          ),
        ),
        const BackupSection(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
