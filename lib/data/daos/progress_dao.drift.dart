// dart format width=80
// ignore_for_file: type=lint
part of 'progress_dao.dart';

mixin _$ProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $RoutinesTable get routines => attachedDatabase.routines;
  $WorkoutSessionsTable get workoutSessions => attachedDatabase.workoutSessions;
  $SessionExercisesTable get sessionExercises =>
      attachedDatabase.sessionExercises;
  $SetEntriesTable get setEntries => attachedDatabase.setEntries;
  ProgressDaoManager get managers => ProgressDaoManager(this);
}

class ProgressDaoManager {
  final _$ProgressDaoMixin _db;
  ProgressDaoManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db.attachedDatabase, _db.routines);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(
        _db.attachedDatabase,
        _db.workoutSessions,
      );
  $$SessionExercisesTableTableManager get sessionExercises =>
      $$SessionExercisesTableTableManager(
        _db.attachedDatabase,
        _db.sessionExercises,
      );
  $$SetEntriesTableTableManager get setEntries =>
      $$SetEntriesTableTableManager(_db.attachedDatabase, _db.setEntries);
}
