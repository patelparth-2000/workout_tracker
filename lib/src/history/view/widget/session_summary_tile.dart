import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models.dart';
import '../../../../utils/app_spacing.dart';
import '../../../../utils/units.dart';
import '../../../../utils/workout_math.dart';

/// One finished workout: name, date, duration, completed sets, volume.
class SessionSummaryTile extends StatelessWidget {
  const SessionSummaryTile({
    super.key,
    required this.summary,
    required this.unit,
    this.onTap,
  });

  final SessionSummary summary;
  final WeightUnit unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = summary.session;
    final d = summary.duration;
    final sets = summary.completedSetCount;
    final parts = [
      DateFormat.yMMMEd().format(s.startedAt),
      if (d != null) formatDuration(d),
      '$sets set${sets == 1 ? '' : 's'}',
      formatVolume(summary.volumeKg, unit),
    ];
    return Card(
      child: ListTile(
        contentPadding: AppInsets.listTile,
        onTap: onTap,
        title: Text(s.name),
        subtitle: Text(parts.join(' · ')),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
