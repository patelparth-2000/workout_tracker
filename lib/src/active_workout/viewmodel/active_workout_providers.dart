import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/app_database.dart';
import '../../../data/database_provider.dart';
import '../../../data/models.dart';
import '../../../utils/clock.dart';
import '../../settings/viewmodel/settings_provider.dart';
import 'rest_timer_provider.dart';

part 'active_workout_providers.g.dart';

/// The in-progress session, or null.
@Riverpod(keepAlive: true)
Stream<WorkoutSession?> activeSession(Ref ref) =>
    ref.watch(appDatabaseProvider).workoutDao.watchActiveSession();

/// A session with its exercises and sets (active or finished).
@riverpod
Stream<SessionDetail?> sessionDetail(Ref ref, int sessionId) =>
    ref.watch(appDatabaseProvider).workoutDao.watchSessionDetail(sessionId);

/// exerciseId -> the sets logged the previous time that exercise was done.
@riverpod
Stream<Map<int, List<SetEntry>>> previousSets(Ref ref, int sessionId) => ref
    .watch(appDatabaseProvider)
    .workoutDao
    .watchPreviousSetsForSession(sessionId);

/// Commands for starting and running a workout (keepAlive: only ever `ref.read`).
@Riverpod(keepAlive: true)
class ActiveWorkoutController extends _$ActiveWorkoutController {
  @override
  void build() {}

  AppDatabase get _db => ref.read(appDatabaseProvider);
  DateTime _now() => ref.read(clockProvider)();

  Future<int> startEmpty() =>
      _db.workoutDao.startSession(name: 'Workout', now: _now());

  Future<int> startFromRoutine(Routine routine) => _db.workoutDao.startSession(
    name: routine.name,
    routineId: routine.id,
    now: _now(),
  );

  Future<void> rename(int sessionId, String name) =>
      _db.workoutDao.renameSession(sessionId, name);

  Future<void> addExercise(int sessionId, int exerciseId) =>
      _db.workoutDao.addExercise(sessionId, exerciseId);

  Future<void> removeExercise(int sessionExerciseId) =>
      _db.workoutDao.removeSessionExercise(sessionExerciseId);

  Future<void> moveExercise(int sessionId, int from, int to) =>
      _db.workoutDao.moveSessionExercise(sessionId, from, to);

  Future<void> addSet(int sessionExerciseId) =>
      _db.workoutDao.addSet(sessionExerciseId);

  Future<void> removeSet(int setId) => _db.workoutDao.removeSet(setId);

  Future<void> updateSet(int setId, double weightKg, int reps) =>
      _db.workoutDao.updateSet(setId, weightKg: weightKg, reps: reps);

  /// Toggles completion. Completing a set starts the rest timer with the exercise's rest
  /// (copied from the routine) or the settings default.
  Future<void> toggleComplete(
    SetEntry set, {
    required int? restSeconds,
    bool startTimer = true,
  }) async {
    final completing = set.completedAt == null;
    await _db.workoutDao.setCompleted(
      set.id,
      completed: completing,
      now: _now(),
    );
    if (completing && startTimer) {
      final int seconds = restSeconds ?? ref.read(defaultRestSecondsProvider);
      ref.read(restTimerProvider.notifier).start(Duration(seconds: seconds));
    }
  }

  Future<void> finish(int sessionId) async {
    await _db.workoutDao.finishSession(sessionId, _now());
    ref.read(restTimerProvider.notifier).skip();
  }

  Future<void> discard(int sessionId) async {
    await _db.workoutDao.deleteSession(sessionId);
    ref.read(restTimerProvider.notifier).skip();
  }
}
