import 'package:drift/drift.dart';

import '../app_database.dart';

part 'progress_dao.drift.dart';

/// Bests for one exercise. All values kg; null when nothing qualifying is logged.
class ExerciseBests {
  const ExerciseBests({
    this.bestWeightKg,
    this.bestE1rmKg,
    this.bestSessionVolumeKg,
    this.bestVolumeAt,
    this.sessionCount = 0,
  });
  final double? bestWeightKg;
  final double? bestE1rmKg;
  final double? bestSessionVolumeKg;
  final DateTime? bestVolumeAt;
  final int sessionCount;
}

/// One finished session's numbers for one exercise.
class ProgressPoint {
  const ProgressPoint({
    required this.sessionId,
    required this.at,
    required this.e1rmKg,
    required this.volumeKg,
    required this.topWeightKg,
  });
  final int sessionId;
  final DateTime at;
  final double? e1rmKg;
  final double volumeKg;
  final double topWeightKg;
}

class ExerciseWithHistory {
  const ExerciseWithHistory({
    required this.exercise,
    required this.sessionCount,
    required this.lastAt,
  });
  final Exercise exercise;
  final int sessionCount;
  final DateTime lastAt;
}

/// Epley e1RM in SQL. MUST match estimatedOneRepMax() in utils/workout_math.dart.
/// Only call it on rows already filtered by [_qualifies].
const _e1rm =
    '(CASE WHEN st.reps = 1 THEN st.weight_kg '
    'ELSE st.weight_kg * (1 + st.reps / 30.0) END)';

/// A set counts toward records when completed, with weight and reps above zero.
const _qualifies =
    'st.completed_at IS NOT NULL AND st.reps > 0 AND st.weight_kg > 0';

/// Records and progress. Everything is aggregated in SQL (ARCHITECTURE §3), and only
/// FINISHED sessions count.
@DriftAccessor(
  tables: [Exercises, WorkoutSessions, SessionExercises, SetEntries],
)
class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  Set<ResultSetImplementation<dynamic, dynamic>> get _reads => {
    workoutSessions,
    sessionExercises,
    setEntries,
  };

  Stream<ExerciseBests> watchBests(int exerciseId) {
    return customSelect(
      '''
WITH qualifying AS (
  SELECT ws.id AS session_id, ws.started_at, st.weight_kg, st.reps, $_e1rm AS e1rm
  FROM set_entries st
  JOIN session_exercises se ON se.id = st.session_exercise_id
  JOIN workout_sessions ws ON ws.id = se.session_id
  WHERE se.exercise_id = ? AND ws.ended_at IS NOT NULL AND $_qualifies
),
per_session AS (
  SELECT session_id, started_at, SUM(weight_kg * reps) AS volume
  FROM qualifying GROUP BY session_id
),
top_volume AS (
  SELECT volume, started_at FROM per_session
  ORDER BY volume DESC, started_at ASC LIMIT 1
)
SELECT
  (SELECT MAX(weight_kg) FROM qualifying) AS best_weight,
  (SELECT MAX(e1rm) FROM qualifying) AS best_e1rm,
  (SELECT volume FROM top_volume) AS best_volume,
  (SELECT started_at FROM top_volume) AS best_volume_at,
  (SELECT COUNT(*) FROM per_session) AS session_count
''',
      variables: [Variable.withInt(exerciseId)],
      readsFrom: _reads,
    ).watchSingle().map((r) {
      return ExerciseBests(
        bestWeightKg: r.readNullable<double>('best_weight'),
        bestE1rmKg: r.readNullable<double>('best_e1rm'),
        bestSessionVolumeKg: r.readNullable<double>('best_volume'),
        bestVolumeAt: r.readNullable<DateTime>('best_volume_at'),
        sessionCount: r.read<int>('session_count'),
      );
    });
  }

  /// Per finished session (oldest first) since [since] (null = all time).
  Stream<List<ProgressPoint>> watchSeries(int exerciseId, {DateTime? since}) {
    return customSelect(
      '''
SELECT ws.id AS session_id, ws.started_at,
       MAX(CASE WHEN st.reps > 0 AND st.weight_kg > 0 THEN $_e1rm END) AS e1rm,
       SUM(st.weight_kg * st.reps) AS volume,
       MAX(st.weight_kg) AS top_weight
FROM set_entries st
JOIN session_exercises se ON se.id = st.session_exercise_id
JOIN workout_sessions ws ON ws.id = se.session_id
WHERE se.exercise_id = ? AND ws.ended_at IS NOT NULL
  AND st.completed_at IS NOT NULL
  AND (? IS NULL OR ws.started_at >= ?)
GROUP BY ws.id
ORDER BY ws.started_at ASC, ws.id ASC
''',
      variables: [
        Variable.withInt(exerciseId),
        Variable<DateTime>(since),
        Variable<DateTime>(since),
      ],
      readsFrom: _reads,
    ).watch().map(
      (rows) => [
        for (final r in rows)
          ProgressPoint(
            sessionId: r.read<int>('session_id'),
            at: r.read<DateTime>('started_at'),
            e1rmKg: r.readNullable<double>('e1rm'),
            volumeKg: r.read<double>('volume'),
            topWeightKg: r.read<double>('top_weight'),
          ),
      ],
    );
  }

  /// Exercises with at least one completed set in a finished session, most recent first.
  Stream<List<ExerciseWithHistory>> watchExercisesWithHistory() {
    return customSelect(
      '''
SELECT e.*, COUNT(DISTINCT ws.id) AS session_count, MAX(ws.started_at) AS last_at
FROM exercises e
JOIN session_exercises se ON se.exercise_id = e.id
JOIN workout_sessions ws ON ws.id = se.session_id
JOIN set_entries st ON st.session_exercise_id = se.id
WHERE ws.ended_at IS NOT NULL AND st.completed_at IS NOT NULL
GROUP BY e.id
ORDER BY last_at DESC, e.name
''',
      readsFrom: {..._reads, exercises},
    ).watch().map(
      (rows) => [
        for (final r in rows)
          ExerciseWithHistory(
            exercise: exercises.map(r.data),
            sessionCount: r.read<int>('session_count'),
            lastAt: r.read<DateTime>('last_at'),
          ),
      ],
    );
  }

  /// Ids of the sets in [sessionId] that are personal records (ARCHITECTURE §3): the
  /// best qualifying set of its exercise in this session, strictly above the best e1RM
  /// of every FINISHED session that started before this one. First-ever logs set a
  /// baseline and are not records.
  Stream<Set<int>> watchRecordSetIds(int sessionId) {
    return customSelect(
      '''
WITH me AS (SELECT id, started_at FROM workout_sessions WHERE id = ?),
cur AS (
  SELECT st.id AS set_id, se.exercise_id, $_e1rm AS e1rm,
         ROW_NUMBER() OVER (
           PARTITION BY se.exercise_id
           ORDER BY $_e1rm DESC, se.position, st.position, st.id
         ) AS rn
  FROM set_entries st
  JOIN session_exercises se ON se.id = st.session_exercise_id
  WHERE se.session_id = (SELECT id FROM me) AND $_qualifies
),
prior AS (
  SELECT se.exercise_id, MAX($_e1rm) AS best
  FROM set_entries st
  JOIN session_exercises se ON se.id = st.session_exercise_id
  JOIN workout_sessions ws ON ws.id = se.session_id
  WHERE ws.ended_at IS NOT NULL AND $_qualifies
    AND ws.id <> (SELECT id FROM me)
    AND (ws.started_at < (SELECT started_at FROM me)
         OR (ws.started_at = (SELECT started_at FROM me) AND ws.id < (SELECT id FROM me)))
    AND se.exercise_id IN (SELECT exercise_id FROM cur)
  GROUP BY se.exercise_id
)
SELECT cur.set_id FROM cur JOIN prior ON prior.exercise_id = cur.exercise_id
WHERE cur.rn = 1 AND cur.e1rm > prior.best + 1e-9
''',
      variables: [Variable.withInt(sessionId)],
      readsFrom: _reads,
    ).watch().map((rows) => {for (final r in rows) r.read<int>('set_id')});
  }
}
