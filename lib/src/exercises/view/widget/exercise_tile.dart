import 'package:flutter/material.dart';

import '../../../../data/app_database.dart';
import '../../../../utils/app_spacing.dart';

/// One exercise row: name, "muscle · equipment", custom/archived tags.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.exercise,
    this.onTap,
    this.trailing,
  });

  final Exercise exercise;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = [
      if (exercise.isCustom) 'Custom',
      if (exercise.archived) 'Archived',
    ];
    return ListTile(
      contentPadding: AppInsets.listTile,
      onTap: onTap,
      title: Text(exercise.name),
      subtitle: Text(
        [
          '${exercise.muscleGroup} · ${exercise.equipment}',
          ...tags,
        ].join(' · '),
      ),
      leading: ExcludeSemantics(
        child: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          child: Text(exercise.name.characters.first.toUpperCase()),
        ),
      ),
      trailing: trailing,
    );
  }
}
