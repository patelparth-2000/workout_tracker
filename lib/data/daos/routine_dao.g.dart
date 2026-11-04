// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_dao.dart';

// ignore_for_file: type=lint
mixin _$RoutineDaoMixin on DatabaseAccessor<AppDatabase> {
  $RoutinesTable get routines => attachedDatabase.routines;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $RoutineExercisesTable get routineExercises =>
      attachedDatabase.routineExercises;
  RoutineDaoManager get managers => RoutineDaoManager(this);
}

class RoutineDaoManager {
  final _$RoutineDaoMixin _db;
  RoutineDaoManager(this._db);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db.attachedDatabase, _db.routines);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$RoutineExercisesTableTableManager get routineExercises =>
      $$RoutineExercisesTableTableManager(
        _db.attachedDatabase,
        _db.routineExercises,
      );
}
