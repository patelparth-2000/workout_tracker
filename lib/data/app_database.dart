import 'package:drift/drift.dart';

import 'daos/exercise_dao.dart';
import 'daos/progress_dao.dart';
import 'daos/routine_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/workout_dao.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.drift.dart';

/// Supplies the exercises inserted when the database is first created.
typedef ExerciseSeedLoader = Future<List<ExercisesCompanion>> Function();

@DriftDatabase(
  tables: [
    Exercises,
    Routines,
    RoutineExercises,
    WorkoutSessions,
    SessionExercises,
    SetEntries,
    AppSettings,
  ],
  daos: [ExerciseDao, RoutineDao, WorkoutDao, SettingsDao, ProgressDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor, {ExerciseSeedLoader? seedLoader})
    : _seedLoader = seedLoader;

  final ExerciseSeedLoader? _seedLoader;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(appSettings).insert(const AppSettingsCompanion());
      final loader = _seedLoader;
      if (loader != null) {
        final seeds = await loader();
        await batch((b) => b.insertAll(exercises, seeds));
      }
    },
    onUpgrade: (m, from, to) async {
      // v1 is the first schema. Add stepwise migrations here (from < 2 ...).
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
