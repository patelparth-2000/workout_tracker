import 'package:drift/drift.dart';

import '../app_database.dart';
import '../models.dart';

part 'workout_dao.g.dart';

/// Only one workout may be in progress at a time.
class ActiveSessionExistsException implements Exception {
  const ActiveSessionExistsException(this.sessionId);
  final int sessionId;
  @override
  String toString() => 'A workout is already in progress';
}

/// Hard bounds for a single set. Anything outside is a typo, not a lift.
const double maxWeightKg = 2000;
const int maxReps = 1000;

void validateSetValues(double weightKg, int reps) {
  if (weightKg.isNaN || weightKg < 0 || weightKg > maxWeightKg) {
    throw RangeError('Weight must be between 0 and $maxWeightKg kg');
  }
  if (reps < 0 || reps > maxReps) {
    throw RangeError('Reps must be between 0 and $maxReps');
  }
}

@DriftAccessor(
  tables: [
    Exercises,
    Routines,
    RoutineExercises,
    WorkoutSessions,
    SessionExercises,
    SetEntries,
  ],
)
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // ---------------------------------------------------------------- sessions

  Future<WorkoutSession?> getActiveSession() =>
      (select(workoutSessions)
            ..where((s) => s.endedAt.isNull())
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
            ..limit(1))
          .getSingleOrNull();

  Stream<WorkoutSession?> watchActiveSession() =>
      (select(workoutSessions)
            ..where((s) => s.endedAt.isNull())
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
            ..limit(1))
          .watchSingleOrNull();

  /// Starts a session, empty or from a routine (exercises + target sets, prefilled
  /// from the previous time each exercise was done). Throws if one is active.
  Future<int> startSession({
    required String name,
    int? routineId,
    required DateTime now,
  }) {
    return transaction(() async {
      final active = await getActiveSession();
      if (active != null) throw ActiveSessionExistsException(active.id);

      final sessionId = await into(workoutSessions).insert(
        WorkoutSessionsCompanion.insert(
          name: name.trim().isEmpty ? 'Workout' : name.trim(),
          routineId: Value(routineId),
          startedAt: now,
        ),
      );
      if (routineId == null) return sessionId;

      final items =
          await (select(routineExercises)
                ..where((r) => r.routineId.equals(routineId))
                ..orderBy([(r) => OrderingTerm(expression: r.position)]))
              .get();
      final previous = await previousSetsFor(
        items.map((e) => e.exerciseId).toSet().toList(),
        excludeSessionId: sessionId,
      );
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final seId = await into(sessionExercises).insert(
          SessionExercisesCompanion.insert(
            sessionId: sessionId,
            exerciseId: item.exerciseId,
            position: i,
            restSeconds: Value(item.restSeconds),
          ),
        );
        await _insertPrefilledSets(
          seId,
          count: item.targetSets < 1 ? 1 : item.targetSets,
          previous: previous[item.exerciseId] ?? const [],
          targetReps: item.targetReps,
        );
      }
      return sessionId;
    });
  }

  Future<void> _insertPrefilledSets(
    int sessionExerciseId, {
    required int count,
    required List<SetEntry> previous,
    int? targetReps,
  }) async {
    await batch((b) {
      b.insertAll(setEntries, [
        for (var i = 0; i < count; i++)
          SetEntriesCompanion.insert(
            sessionExerciseId: sessionExerciseId,
            position: i,
            weightKg: Value(_pick(previous, i)?.weightKg ?? 0),
            reps: Value(targetReps ?? _pick(previous, i)?.reps ?? 0),
          ),
      ]);
    });
  }

  static SetEntry? _pick(List<SetEntry> previous, int i) => previous.isEmpty
      ? null
      : previous[i < previous.length ? i : previous.length - 1];

  Future<void> finishSession(int sessionId, DateTime now) =>
      (update(workoutSessions)..where((s) => s.id.equals(sessionId))).write(
        WorkoutSessionsCompanion(endedAt: Value(now)),
      );

  /// Deletes a session and (by cascade) its exercises and sets.
  Future<void> deleteSession(int sessionId) =>
      (delete(workoutSessions)..where((s) => s.id.equals(sessionId))).go();

  Future<void> renameSession(int sessionId, String name) {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Name must not be empty');
    return (update(workoutSessions)..where((s) => s.id.equals(sessionId)))
        .write(WorkoutSessionsCompanion(name: Value(clean)));
  }

  /// One query: session + exercises + sets, ordered.
  Stream<SessionDetail?> watchSessionDetail(int sessionId) {
    final q =
        select(workoutSessions).join([
            leftOuterJoin(
              sessionExercises,
              sessionExercises.sessionId.equalsExp(workoutSessions.id),
            ),
            leftOuterJoin(
              exercises,
              exercises.id.equalsExp(sessionExercises.exerciseId),
            ),
            leftOuterJoin(
              setEntries,
              setEntries.sessionExerciseId.equalsExp(sessionExercises.id),
            ),
          ])
          ..where(workoutSessions.id.equals(sessionId))
          ..orderBy([
            OrderingTerm(expression: sessionExercises.position),
            OrderingTerm(expression: sessionExercises.id),
            OrderingTerm(expression: setEntries.position),
            OrderingTerm(expression: setEntries.id),
          ]);
    return q.watch().map((rows) {
      if (rows.isEmpty) return null;
      final session = rows.first.readTable(workoutSessions);
      final order = <int>[];
      final entries = <int, SessionExercise>{};
      final exerciseById = <int, Exercise>{};
      final sets = <int, List<SetEntry>>{};
      for (final r in rows) {
        final se = r.readTableOrNull(sessionExercises);
        if (se == null) continue;
        if (!entries.containsKey(se.id)) {
          order.add(se.id);
          entries[se.id] = se;
          exerciseById[se.id] = r.readTable(exercises);
          sets[se.id] = [];
        }
        final set = r.readTableOrNull(setEntries);
        if (set != null) sets[se.id]!.add(set);
      }
      return SessionDetail(
        session: session,
        exercises: [
          for (final id in order)
            SessionExerciseDetail(
              entry: entries[id]!,
              exercise: exerciseById[id]!,
              sets: sets[id]!,
            ),
        ],
      );
    });
  }

  // --------------------------------------------------------------- exercises

  Future<int> addExercise(int sessionId, int exerciseId) {
    return transaction(() async {
      final maxPos = sessionExercises.position.max();
      final row =
          await (selectOnly(sessionExercises)
                ..addColumns([maxPos])
                ..where(sessionExercises.sessionId.equals(sessionId)))
              .getSingle();
      final seId = await into(sessionExercises).insert(
        SessionExercisesCompanion.insert(
          sessionId: sessionId,
          exerciseId: exerciseId,
          position: (row.read(maxPos) ?? -1) + 1,
        ),
      );
      final previous = await previousSetsFor([
        exerciseId,
      ], excludeSessionId: sessionId);
      final prev = previous[exerciseId] ?? const <SetEntry>[];
      await _insertPrefilledSets(
        seId,
        count: prev.isEmpty ? 1 : prev.length,
        previous: prev,
      );
      return seId;
    });
  }

  Future<void> removeSessionExercise(int sessionExerciseId) {
    return transaction(() async {
      final se = await (select(
        sessionExercises,
      )..where((s) => s.id.equals(sessionExerciseId))).getSingleOrNull();
      if (se == null) return;
      await (delete(
        sessionExercises,
      )..where((s) => s.id.equals(sessionExerciseId))).go();
      await _renumberExercises(se.sessionId);
    });
  }

  /// Moves the exercise at [from] to [to] (indices in the current order).
  Future<void> moveSessionExercise(int sessionId, int from, int to) {
    return transaction(() async {
      final ids = await _orderedExerciseIds(sessionId);
      if (from < 0 || from >= ids.length) return;
      final target = to.clamp(0, ids.length - 1);
      final id = ids.removeAt(from);
      ids.insert(target, id);
      await _writeExercisePositions(ids);
    });
  }

  Future<List<int>> _orderedExerciseIds(int sessionId) async {
    final rows =
        await (select(sessionExercises)
              ..where((s) => s.sessionId.equals(sessionId))
              ..orderBy([
                (s) => OrderingTerm(expression: s.position),
                (s) => OrderingTerm(expression: s.id),
              ]))
            .get();
    return rows.map((r) => r.id).toList();
  }

  Future<void> _renumberExercises(int sessionId) async =>
      _writeExercisePositions(await _orderedExerciseIds(sessionId));

  Future<void> _writeExercisePositions(List<int> ids) async {
    await batch((b) {
      for (var i = 0; i < ids.length; i++) {
        b.update(
          sessionExercises,
          SessionExercisesCompanion(position: Value(i)),
          where: (s) => s.id.equals(ids[i]),
        );
      }
    });
  }

  // -------------------------------------------------------------------- sets

  /// Adds a set copying the last set's weight and reps.
  Future<int> addSet(int sessionExerciseId) {
    return transaction(() async {
      final last =
          await (select(setEntries)
                ..where((s) => s.sessionExerciseId.equals(sessionExerciseId))
                ..orderBy([(s) => OrderingTerm.desc(s.position)])
                ..limit(1))
              .getSingleOrNull();
      return into(setEntries).insert(
        SetEntriesCompanion.insert(
          sessionExerciseId: sessionExerciseId,
          position: (last?.position ?? -1) + 1,
          weightKg: Value(last?.weightKg ?? 0),
          reps: Value(last?.reps ?? 0),
        ),
      );
    });
  }

  Future<void> removeSet(int setId) {
    return transaction(() async {
      final set = await (select(
        setEntries,
      )..where((s) => s.id.equals(setId))).getSingleOrNull();
      if (set == null) return;
      await (delete(setEntries)..where((s) => s.id.equals(setId))).go();
      final rest =
          await (select(setEntries)
                ..where(
                  (s) => s.sessionExerciseId.equals(set.sessionExerciseId),
                )
                ..orderBy([
                  (s) => OrderingTerm(expression: s.position),
                  (s) => OrderingTerm(expression: s.id),
                ]))
              .get();
      await batch((b) {
        for (var i = 0; i < rest.length; i++) {
          b.update(
            setEntries,
            SetEntriesCompanion(position: Value(i)),
            where: (s) => s.id.equals(rest[i].id),
          );
        }
      });
    });
  }

  Future<void> updateSet(
    int setId, {
    required double weightKg,
    required int reps,
  }) {
    validateSetValues(weightKg, reps);
    return (update(setEntries)..where((s) => s.id.equals(setId))).write(
      SetEntriesCompanion(weightKg: Value(weightKg), reps: Value(reps)),
    );
  }

  Future<void> setCompleted(
    int setId, {
    required bool completed,
    required DateTime now,
  }) => (update(setEntries)..where((s) => s.id.equals(setId))).write(
    SetEntriesCompanion(completedAt: Value(completed ? now : null)),
  );

  // --------------------------------------------------------- previous values

  /// For each exercise id, the sets of the most recent FINISHED session that
  /// contains it (excluding [excludeSessionId]). One query for all ids.
  Future<Map<int, List<SetEntry>>> previousSetsFor(
    List<int> exerciseIds, {
    int? excludeSessionId,
  }) async {
    if (exerciseIds.isEmpty) return {};
    final placeholders = List.filled(exerciseIds.length, '?').join(', ');
    final rows = await customSelect(
      _previousSql('se.exercise_id IN ($placeholders)'),
      variables: [
        for (final id in exerciseIds) Variable.withInt(id),
        Variable.withInt(excludeSessionId ?? -1),
      ],
      readsFrom: {sessionExercises, workoutSessions, setEntries},
    ).get();
    return _groupPrevious(rows);
  }

  /// Reactive "previous values" for every exercise in [sessionId].
  Stream<Map<int, List<SetEntry>>> watchPreviousSetsForSession(int sessionId) {
    return customSelect(
      _previousSql(
        'se.exercise_id IN (SELECT exercise_id FROM session_exercises WHERE session_id = ?)',
      ),
      variables: [Variable.withInt(sessionId), Variable.withInt(sessionId)],
      readsFrom: {sessionExercises, workoutSessions, setEntries},
    ).watch().map(_groupPrevious);
  }

  static String _previousSql(String exerciseFilter) =>
      '''
WITH latest AS (
  SELECT se.exercise_id AS ex_id, se.id AS se_id,
         ROW_NUMBER() OVER (
           PARTITION BY se.exercise_id ORDER BY ws.started_at DESC, se.id DESC
         ) AS rn
  FROM session_exercises se
  JOIN workout_sessions ws ON ws.id = se.session_id
  WHERE ws.ended_at IS NOT NULL AND $exerciseFilter AND ws.id <> ?
)
SELECT latest.ex_id AS ex_id, st.*
FROM latest JOIN set_entries st ON st.session_exercise_id = latest.se_id
WHERE latest.rn = 1
ORDER BY latest.ex_id, st.position, st.id
''';

  Map<int, List<SetEntry>> _groupPrevious(List<QueryRow> rows) {
    final out = <int, List<SetEntry>>{};
    for (final r in rows) {
      out
          .putIfAbsent(r.read<int>('ex_id'), () => [])
          .add(setEntries.map(r.data));
    }
    return out;
  }

  // ----------------------------------------------------------------- history

  /// Finished sessions, newest first, keyset-paged. One grouped query per page.
  Future<List<SessionSummary>> historyPage({
    HistoryCursor? before,
    int limit = 30,
  }) async {
    final rows = await customSelect(
      '''
SELECT ws.*,
       COUNT(DISTINCT se.id) AS exercise_count,
       COUNT(st.completed_at) AS completed_set_count,
       COALESCE(SUM(CASE WHEN st.completed_at IS NOT NULL
                         THEN st.weight_kg * st.reps END), 0.0) AS volume_kg
FROM workout_sessions ws
LEFT JOIN session_exercises se ON se.session_id = ws.id
LEFT JOIN set_entries st ON st.session_exercise_id = se.id
WHERE ws.ended_at IS NOT NULL
  AND (? IS NULL OR ws.started_at < ? OR (ws.started_at = ? AND ws.id < ?))
GROUP BY ws.id
ORDER BY ws.started_at DESC, ws.id DESC
LIMIT ?
''',
      variables: [
        Variable<DateTime>(before?.startedAt),
        Variable<DateTime>(before?.startedAt),
        Variable<DateTime>(before?.startedAt),
        Variable.withInt(before?.id ?? 0),
        Variable.withInt(limit),
      ],
      readsFrom: {workoutSessions, sessionExercises, setEntries},
    ).get();
    return [
      for (final r in rows)
        SessionSummary(
          session: workoutSessions.map(r.data),
          exerciseCount: r.read<int>('exercise_count'),
          completedSetCount: r.read<int>('completed_set_count'),
          volumeKg: r.read<double>('volume_kg'),
        ),
    ];
  }

  /// Emits whenever anything history depends on changes (used to refresh pages).
  Stream<void> watchHistoryChanges() => tableUpdates(
    TableUpdateQuery.onAllTables([
      workoutSessions,
      sessionExercises,
      setEntries,
    ]),
  );
}
