import 'package:drift/drift.dart';

// Schema version 1. See docs/ARCHITECTURE.md §3 for the reasoning behind every column.
// Weights are kg (REAL), reps INTEGER. Never store display units.

@DataClassName('Exercise')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()
      .withLength(min: 1, max: 80)
      .customConstraint('NOT NULL UNIQUE COLLATE NOCASE')();
  TextColumn get muscleGroup => text().withLength(min: 1, max: 40)();
  TextColumn get equipment => text().withLength(min: 1, max: 40)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get gifAsset => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

@DataClassName('Routine')
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get notes => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('RoutineExercise')
class RoutineExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId =>
      integer().references(Routines, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get position => integer()();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get targetReps => integer().nullable()();
  IntColumn get restSeconds => integer().nullable()();
  IntColumn get supersetGroup => integer().nullable()();
}

@DataClassName('WorkoutSession')
@TableIndex(name: 'idx_workout_sessions_started_at', columns: {#startedAt})
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().nullable().references(
    Routines,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('SessionExercise')
@TableIndex(name: 'idx_session_exercises_session_id', columns: {#sessionId})
@TableIndex(name: 'idx_session_exercises_exercise_id', columns: {#exerciseId})
class SessionExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get position => integer()();
  IntColumn get supersetGroup => integer().nullable()();
  TextColumn get notes => text().nullable()();

  /// Rest copied from the routine when the session started from one; null means
  /// "use the settings default". Deviation from the v2 brief, see ARCHITECTURE §3.
  IntColumn get restSeconds => integer().nullable()();
}

@DataClassName('SetEntry')
@TableIndex(
  name: 'idx_set_entries_session_exercise_id',
  columns: {#sessionExerciseId},
)
class SetEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionExerciseId => integer().references(
    SessionExercises,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get position => integer()();
  RealColumn get weightKg => real().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  RealColumn get rpe => real().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// Single row (id = 1).
@DataClassName('AppSettingsData')
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  IntColumn get defaultRestSeconds =>
      integer().withDefault(const Constant(90))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  DateTimeColumn get legacyImportedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
