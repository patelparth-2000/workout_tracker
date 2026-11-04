import 'package:drift/drift.dart';

import '../app_database.dart';
import '../models.dart';

part 'routine_dao.g.dart';

@DriftAccessor(tables: [Routines, RoutineExercises, Exercises])
class RoutineDao extends DatabaseAccessor<AppDatabase> with _$RoutineDaoMixin {
  RoutineDao(super.db);

  /// All routines with their exercise counts: one grouped query.
  Stream<List<RoutineSummary>> watchRoutines() {
    final count = routineExercises.id.count();
    final q =
        select(routines).join([
            leftOuterJoin(
              routineExercises,
              routineExercises.routineId.equalsExp(routines.id),
            ),
          ])
          ..addColumns([count])
          ..groupBy([routines.id])
          ..orderBy([
            OrderingTerm(expression: routines.position),
            OrderingTerm(expression: routines.id),
          ]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          RoutineSummary(
            routine: r.readTable(routines),
            exerciseCount: r.read(count) ?? 0,
          ),
      ],
    );
  }

  Future<RoutineDetail?> getRoutine(int id) async {
    final routine = await (select(
      routines,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (routine == null) return null;
    final rows =
        await (select(routineExercises).join([
                innerJoin(
                  exercises,
                  exercises.id.equalsExp(routineExercises.exerciseId),
                ),
              ])
              ..where(routineExercises.routineId.equals(id))
              ..orderBy([OrderingTerm(expression: routineExercises.position)]))
            .get();
    return RoutineDetail(
      routine: routine,
      exercises: [
        for (final r in rows)
          RoutineExerciseDetail(
            entry: r.readTable(routineExercises),
            exercise: r.readTable(exercises),
          ),
      ],
    );
  }

  /// Creates (id == null) or replaces a routine and its exercise list atomically.
  Future<int> saveRoutine({
    int? id,
    required String name,
    String? notes,
    required List<RoutineExerciseDraft> items,
    required DateTime now,
  }) {
    return transaction(() async {
      final cleanNotes = (notes == null || notes.trim().isEmpty)
          ? null
          : notes.trim();
      int routineId;
      if (id == null) {
        final maxPos = routines.position.max();
        final row = await (selectOnly(
          routines,
        )..addColumns([maxPos])).getSingle();
        routineId = await into(routines).insert(
          RoutinesCompanion.insert(
            name: name.trim(),
            notes: Value(cleanNotes),
            position: Value((row.read(maxPos) ?? -1) + 1),
            createdAt: now,
          ),
        );
      } else {
        routineId = id;
        await (update(routines)..where((r) => r.id.equals(id))).write(
          RoutinesCompanion(name: Value(name.trim()), notes: Value(cleanNotes)),
        );
        await (delete(
          routineExercises,
        )..where((r) => r.routineId.equals(id))).go();
      }
      await batch((b) {
        b.insertAll(routineExercises, [
          for (var i = 0; i < items.length; i++)
            RoutineExercisesCompanion.insert(
              routineId: routineId,
              exerciseId: items[i].exerciseId,
              position: i,
              targetSets: Value(items[i].targetSets),
              targetReps: Value(items[i].targetReps),
              restSeconds: Value(items[i].restSeconds),
            ),
        ]);
      });
      return routineId;
    });
  }

  Future<void> deleteRoutine(int id) =>
      (delete(routines)..where((r) => r.id.equals(id))).go();
}
