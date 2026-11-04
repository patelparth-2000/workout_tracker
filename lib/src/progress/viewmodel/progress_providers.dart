import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/daos/progress_dao.dart';
import '../../../data/database_provider.dart';
import '../../../utils/clock.dart';

part 'progress_providers.g.dart';

enum ProgressRange {
  month('30 days', Duration(days: 30)),
  quarter('90 days', Duration(days: 90)),
  year('1 year', Duration(days: 365)),
  all('All time', null);

  const ProgressRange(this.label, this.span);
  final String label;
  final Duration? span;
}

enum ProgressMetric { e1rm, volume }

class ProgressSelection {
  const ProgressSelection({
    this.exerciseId,
    this.range = ProgressRange.quarter,
    this.metric = ProgressMetric.e1rm,
  });

  /// null = the most recently trained exercise.
  final int? exerciseId;
  final ProgressRange range;
  final ProgressMetric metric;

  ProgressSelection copyWith({
    int? exerciseId,
    ProgressRange? range,
    ProgressMetric? metric,
  }) => ProgressSelection(
    exerciseId: exerciseId ?? this.exerciseId,
    range: range ?? this.range,
    metric: metric ?? this.metric,
  );
}

@Riverpod(keepAlive: true)
class ProgressSelectionNotifier extends _$ProgressSelectionNotifier {
  @override
  ProgressSelection build() => const ProgressSelection();

  void selectExercise(int id) => state = state.copyWith(exerciseId: id);
  void setRange(ProgressRange r) => state = state.copyWith(range: r);
  void setMetric(ProgressMetric m) => state = state.copyWith(metric: m);
}

@riverpod
Stream<List<ExerciseWithHistory>> trainedExercises(Ref ref) =>
    ref.watch(appDatabaseProvider).progressDao.watchExercisesWithHistory();

@riverpod
Stream<ExerciseBests> exerciseBests(Ref ref, int exerciseId) =>
    ref.watch(appDatabaseProvider).progressDao.watchBests(exerciseId);

@riverpod
Stream<List<ProgressPoint>> progressSeries(
  Ref ref,
  int exerciseId,
  ProgressRange range,
) {
  final span = range.span;
  final since = span == null ? null : ref.read(clockProvider)().subtract(span);
  return ref
      .watch(appDatabaseProvider)
      .progressDao
      .watchSeries(exerciseId, since: since);
}

/// Set ids that are personal records within a session (live or finished).
@riverpod
Stream<Set<int>> recordSetIds(Ref ref, int sessionId) =>
    ref.watch(appDatabaseProvider).progressDao.watchRecordSetIds(sessionId);
