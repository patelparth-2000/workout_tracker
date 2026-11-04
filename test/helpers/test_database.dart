import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:workout_tracker/data/app_database.dart';

/// Fresh in-memory database. Seeds the given exercises (default: a small fixed set).
AppDatabase testDatabase({List<ExercisesCompanion>? seed}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    NativeDatabase.memory(),
    seedLoader: () async => seed ?? defaultTestSeed,
  );
}

final defaultTestSeed = <ExercisesCompanion>[
  ExercisesCompanion.insert(
    name: 'Squat',
    muscleGroup: 'Quads',
    equipment: 'Barbell',
  ),
  ExercisesCompanion.insert(
    name: 'Bench press',
    muscleGroup: 'Chest',
    equipment: 'Barbell',
  ),
  ExercisesCompanion.insert(
    name: 'Bicep curl',
    muscleGroup: 'Biceps',
    equipment: 'Dumbbell',
  ),
];

Future<int> exerciseId(AppDatabase db, String name) async =>
    (await db.exerciseDao.findByName(name))!.id;

/// Logs and finishes a session with the given (weightKg, reps) sets for one exercise.
Future<int> logFinishedSession(
  AppDatabase db, {
  required String exercise,
  required DateTime at,
  required List<(double, int)> sets,
  bool completed = true,
}) async {
  final dao = db.workoutDao;
  final sessionId = await dao.startSession(name: 'W', now: at);
  final seId = await db
      .into(db.sessionExercises)
      .insert(
        SessionExercisesCompanion.insert(
          sessionId: sessionId,
          exerciseId: await exerciseId(db, exercise),
          position: 0,
        ),
      );
  for (var i = 0; i < sets.length; i++) {
    await db
        .into(db.setEntries)
        .insert(
          SetEntriesCompanion.insert(
            sessionExerciseId: seId,
            position: i,
            weightKg: Value(sets[i].$1),
            reps: Value(sets[i].$2),
            completedAt: Value(completed ? at : null),
          ),
        );
  }
  await dao.finishSession(sessionId, at.add(const Duration(hours: 1)));
  return sessionId;
}
