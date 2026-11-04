import 'package:flutter/material.dart';

import '../../../../data/models.dart';
import '../../../../utils/app_spacing.dart';

/// One routine with Start and an overflow menu (edit, delete).
class RoutineCard extends StatelessWidget {
  const RoutineCard({
    super.key,
    required this.summary,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
    this.startEnabled = true,
  });

  final RoutineSummary summary;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool startEnabled;

  @override
  Widget build(BuildContext context) {
    final n = summary.exerciseCount;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onEdit,
        child: Padding(
          padding: AppInsets.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.routine.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('$n exercise${n == 1 ? '' : 's'}'),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More options for ${summary.routine.name}',
                    onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: startEnabled ? onStart : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Semantics(
                    label: 'Start ${summary.routine.name}',
                    excludeSemantics: true,
                    child: const Text('Start'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
