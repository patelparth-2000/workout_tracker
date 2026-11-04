import 'app_database.dart';

/// Read models returned by the DAOs. Plain immutable values; ids, never object identity.

class RoutineSummary {
  const RoutineSummary({required this.routine, required this.exerciseCount});
  final Routine routine;
  final int exerciseCount;
}

class RoutineExerciseDetail {
  const RoutineExerciseDetail({required this.entry, required this.exercise});
  final RoutineExercise entry;
  final Exercise exercise;
}

class RoutineDetail {
  const RoutineDetail({required this.routine, required this.exercises});
  final Routine routine;
  final List<RoutineExerciseDetail> exercises;
}

/// One exercise of a routine being saved. Position is its index in the list.
class RoutineExerciseDraft {
  const RoutineExerciseDraft({
    required this.exerciseId,
    this.targetSets = 3,
    this.targetReps,
    this.restSeconds,
  });
  final int exerciseId;
  final int targetSets;
  final int? targetReps;
  final int? restSeconds;

  RoutineExerciseDraft copyWith({
    int? targetSets,
    int? Function()? targetReps,
    int? Function()? restSeconds,
  }) => RoutineExerciseDraft(
    exerciseId: exerciseId,
    targetSets: targetSets ?? this.targetSets,
    targetReps: targetReps != null ? targetReps() : this.targetReps,
    restSeconds: restSeconds != null ? restSeconds() : this.restSeconds,
  );
}

class SessionExerciseDetail {
  const SessionExerciseDetail({
    required this.entry,
    required this.exercise,
    required this.sets,
  });
  final SessionExercise entry;
  final Exercise exercise;
  final List<SetEntry> sets;
}

class SessionDetail {
  const SessionDetail({required this.session, required this.exercises});
  final WorkoutSession session;
  final List<SessionExerciseDetail> exercises;

  /// Volume (kg) of completed sets only.
  double get volumeKg => exercises.fold(
    0,
    (sum, e) =>
        sum +
        e.sets
            .where((s) => s.completedAt != null)
            .fold<double>(0, (s2, set) => s2 + set.weightKg * set.reps),
  );
}

class SessionSummary {
  const SessionSummary({
    required this.session,
    required this.exerciseCount,
    required this.completedSetCount,
    required this.volumeKg,
  });
  final WorkoutSession session;
  final int exerciseCount;
  final int completedSetCount;
  final double volumeKg;

  Duration? get duration => session.endedAt?.difference(session.startedAt);
}

/// Keyset cursor for history paging: everything strictly older than this.
class HistoryCursor {
  const HistoryCursor({required this.startedAt, required this.id});
  final DateTime startedAt;
  final int id;
}
