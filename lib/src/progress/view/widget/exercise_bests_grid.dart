import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/daos/progress_dao.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/units.dart';
import 'stat_tile.dart';

/// Best weight / best e1RM / best session volume. Wraps to one column at large text.
class ExerciseBestsGrid extends StatelessWidget {
  const ExerciseBestsGrid({super.key, required this.bests, required this.unit});

  final ExerciseBests bests;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    String w(double? kg) => kg == null ? '—' : formatWeight(kg, unit);
    final tiles = [
      StatTile(
        icon: Icons.fitness_center,
        label: 'Best weight',
        value: w(bests.bestWeightKg),
      ),
      StatTile(
        icon: Icons.emoji_events_outlined,
        label: 'Best e1RM',
        value: w(bests.bestE1rmKg),
        caption: 'Estimated 1-rep max',
      ),
      StatTile(
        icon: Icons.stacked_bar_chart,
        label: 'Best session volume',
        value: bests.bestSessionVolumeKg == null
            ? '—'
            : formatVolume(bests.bestSessionVolumeKg!, unit),
        caption: bests.bestVolumeAt == null
            ? null
            : DateFormat.yMMMd().format(bests.bestVolumeAt!),
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = (c.maxWidth / (AppSizes.statTileMinWidth * scale))
            .floor()
            .clamp(1, 3);
        final width = (c.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}
