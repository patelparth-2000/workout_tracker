import 'package:flutter/material.dart';

import '../../../../data/app_database.dart';
import '../../../../data/models.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/units.dart';
import 'set_row.dart';

/// One exercise of the live workout: header + menu, column headers, set rows, add set.
class SessionExerciseCard extends StatelessWidget {
  const SessionExerciseCard({
    super.key,
    required this.detail,
    required this.unit,
    required this.previous,
    required this.isFirst,
    required this.isLast,
    required this.onSetChanged,
    required this.onToggleComplete,
    required this.onDeleteSet,
    required this.onAddSet,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    this.recordSetIds = const {},
  });

  final SessionExerciseDetail detail;
  final WeightUnit unit;
  final List<SetEntry> previous;
  final bool isFirst;
  final bool isLast;
  final Set<int> recordSetIds;
  final void Function(SetEntry set, double weightKg, int reps) onSetChanged;
  final void Function(SetEntry set) onToggleComplete;
  final void Function(SetEntry set) onDeleteSet;
  final VoidCallback onAddSet;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = detail.exercise.name;
    final labelStyle = theme.textTheme.labelSmall;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              0,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(name, style: theme.textTheme.titleMedium),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Options for $name',
                  onSelected: (v) => switch (v) {
                    'up' => onMoveUp(),
                    'down' => onMoveDown(),
                    _ => onRemove(),
                  },
                  itemBuilder: (context) => [
                    if (!isFirst)
                      const PopupMenuItem(value: 'up', child: Text('Move up')),
                    if (!isLast)
                      const PopupMenuItem(
                        value: 'down',
                        child: Text('Move down'),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove exercise'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (detail.entry.notes != null)
            Padding(
              padding: AppInsets.screenH,
              child: Text(
                detail.entry.notes!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: SetRowLayout.setNumber,
                    child: Text(
                      'Set',
                      style: labelStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: SetRowLayout.previous,
                    child: Text('Previous', style: labelStyle),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: SetRowLayout.done,
                    child: Text(
                      'Done',
                      style: labelStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final (i, set) in detail.sets.indexed)
            SetRow(
              key: ValueKey(set.id),
              index: i,
              set: set,
              unit: unit,
              previous: previous.isEmpty
                  ? null
                  : (i < previous.length ? previous[i] : null),
              isRecord: recordSetIds.contains(set.id),
              onChanged: (kg, reps) => onSetChanged(set, kg, reps),
              onToggleComplete: () => onToggleComplete(set),
              onDelete: () => onDeleteSet(set),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add),
                label: Text('Add set to $name'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
