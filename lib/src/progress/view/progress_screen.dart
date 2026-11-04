import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/widget/async_value_view.dart';
import '../../../common/widget/empty_state.dart';
import '../../../common/widget/section_header.dart';
import '../../../data/daos/progress_dao.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/units.dart';
import '../../settings/viewmodel/settings_provider.dart';
import '../viewmodel/progress_providers.dart';
import 'widget/exercise_bests_grid.dart';
import 'widget/progress_chart.dart';

/// Progress tab: per-exercise records and trends.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trained = ref.watch(trainedExercisesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: AsyncValueView<List<ExerciseWithHistory>>(
        value: trained,
        onRetry: () => ref.invalidate(trainedExercisesProvider),
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(
          icon: Icons.insights,
          title: 'No progress yet',
          message:
              'Finish a workout with completed sets to see records and trends.',
          action: FilledButton(
            onPressed: () => context.goNamed(RouteNames.workout),
            child: const Text('Start a workout'),
          ),
        ),
        data: (list) => _ProgressBody(trained: list),
      ),
    );
  }
}

class _ProgressBody extends ConsumerWidget {
  const _ProgressBody({required this.trained});

  final List<ExerciseWithHistory> trained;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(progressSelectionProvider);
    final notifier = ref.read(progressSelectionProvider.notifier);
    final unit = ref.watch(weightUnitProvider);
    final current = trained.firstWhere(
      (t) => t.exercise.id == sel.exerciseId,
      orElse: () => trained.first,
    );
    final id = current.exercise.id;
    final bests = ref.watch(exerciseBestsProvider(id));
    final series = ref.watch(progressSeriesProvider(id, sel.range));
    final metricLabel = sel.metric == ProgressMetric.e1rm
        ? 'Estimated 1-rep max'
        : 'Session volume';

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Padding(
          padding: AppInsets.screen,
          child: DropdownButtonFormField<int>(
            initialValue: id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Exercise'),
            items: [
              for (final t in trained)
                DropdownMenuItem(
                  value: t.exercise.id,
                  child: Text(
                    '${t.exercise.name} (${t.sessionCount})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) notifier.selectExercise(v);
            },
          ),
        ),
        Padding(
          padding: AppInsets.screenH,
          child: switch (bests) {
            AsyncData(:final value) => ExerciseBestsGrid(
              bests: value,
              unit: unit,
            ),
            AsyncError(:final error) => Text('Could not load records: $error'),
            _ => const SizedBox(height: AppSizes.minTapTarget),
          },
        ),
        const SectionHeader(title: 'Trend'),
        Padding(
          padding: AppInsets.screenH,
          child: SegmentedButton<ProgressMetric>(
            segments: const [
              ButtonSegment(value: ProgressMetric.e1rm, label: Text('e1RM')),
              ButtonSegment(
                value: ProgressMetric.volume,
                label: Text('Volume'),
              ),
            ],
            selected: {sel.metric},
            onSelectionChanged: (s) => notifier.setMetric(s.single),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final r in ProgressRange.values)
                ChoiceChip(
                  label: Text(r.label),
                  selected: sel.range == r,
                  onSelected: (_) => notifier.setRange(r),
                ),
            ],
          ),
        ),
        AsyncValueView<List<ProgressPoint>>(
          value: series,
          onRetry: () => ref.invalidate(progressSeriesProvider(id, sel.range)),
          isEmpty: (p) => p.isEmpty,
          empty: const Padding(
            padding: AppInsets.screen,
            child: Text('No workouts with this exercise in this range.'),
          ),
          data: (points) {
            final values = [
              for (final p in points)
                if (sel.metric == ProgressMetric.volume)
                  (p.at, p.volumeKg)
                else if (p.e1rmKg != null)
                  (p.at, p.e1rmKg!),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (values.length < 2)
                  const Padding(
                    padding: AppInsets.screen,
                    child: Text(
                      'Log this exercise in more workouts to see a trend line.',
                    ),
                  ),
                ProgressChart(
                  points: values,
                  unit: unit,
                  metricLabel: metricLabel,
                ),
                SectionHeader(title: 'Workouts ($metricLabel)'),
                for (final p in points.reversed.take(20))
                  ListTile(
                    dense: true,
                    title: Text(DateFormat.yMMMEd().format(p.at)),
                    subtitle: Text(
                      'Top set ${formatWeight(p.topWeightKg, unit)}',
                    ),
                    trailing: Text(
                      sel.metric == ProgressMetric.volume
                          ? formatVolume(p.volumeKg, unit)
                          : (p.e1rmKg == null
                                ? '—'
                                : formatWeight(p.e1rmKg!, unit)),
                    ),
                    onTap: () => context.goNamed(
                      RouteNames.sessionDetail,
                      pathParameters: {'sessionId': '${p.sessionId}'},
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
