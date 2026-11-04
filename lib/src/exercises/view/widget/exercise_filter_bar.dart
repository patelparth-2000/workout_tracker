import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../utils/app_spacing.dart';
import '../../viewmodel/exercise_providers.dart';

/// Search field + muscle group / equipment filters for one filter [scope].
class ExerciseFilterBar extends ConsumerStatefulWidget {
  const ExerciseFilterBar({
    super.key,
    required this.scope,
    this.showArchivedToggle = true,
  });

  final String scope;
  final bool showArchivedToggle;

  @override
  ConsumerState<ExerciseFilterBar> createState() => _ExerciseFilterBarState();
}

class _ExerciseFilterBarState extends ConsumerState<ExerciseFilterBar> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(exerciseFilterProvider(widget.scope)).query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(exerciseFilterProvider(widget.scope));
    final notifier = ref.read(exerciseFilterProvider(widget.scope).notifier);
    final groups = ref.watch(muscleGroupsProvider).value ?? const <String>[];
    final equipment =
        ref.watch(equipmentTypesProvider).value ?? const <String>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            onChanged: notifier.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Search exercises',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filter.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        notifier.setQuery('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterMenu(
                label: 'Muscle',
                value: filter.muscleGroup,
                options: groups,
                onChanged: notifier.setMuscleGroup,
              ),
              _FilterMenu(
                label: 'Equipment',
                value: filter.equipment,
                options: equipment,
                onChanged: notifier.setEquipment,
              ),
              if (widget.showArchivedToggle)
                FilterChip(
                  label: const Text('Show archived'),
                  selected: filter.showArchived,
                  onSelected: notifier.setShowArchived,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      tooltip: 'Filter by ${label.toLowerCase()}',
      onSelected: (v) => onChanged(v == '' ? null : v),
      itemBuilder: (context) => [
        PopupMenuItem(value: '', child: Text('Any ${label.toLowerCase()}')),
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Chip(
        avatar: Icon(
          value == null ? Icons.filter_list : Icons.check,
          size: AppSizes.iconSm,
        ),
        label: Text('$label: ${value ?? 'Any'}'),
      ),
    );
  }
}
