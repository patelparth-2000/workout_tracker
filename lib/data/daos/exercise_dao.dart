import 'package:drift/drift.dart';

import '../app_database.dart';

part 'exercise_dao.g.dart';

/// Thrown when a name collides (case-insensitively) with an existing exercise.
class DuplicateExerciseNameException implements Exception {
  const DuplicateExerciseNameException(this.name);
  final String name;
  @override
  String toString() => 'An exercise named "$name" already exists';
}

@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  /// Filtered library, sorted by name. Filtering runs in SQL.
  Stream<List<Exercise>> watchExercises({
    String query = '',
    String? muscleGroup,
    String? equipment,
    bool includeArchived = false,
  }) {
    final q = select(exercises);
    final trimmed = query.trim();
    q.where((e) {
      Expression<bool> cond = const Constant(true);
      if (!includeArchived) cond = cond & e.archived.equals(false);
      if (trimmed.isNotEmpty) {
        cond =
            cond & e.name.like('%${_escapeLike(trimmed)}%', escapeChar: r'\');
      }
      if (muscleGroup != null) cond = cond & e.muscleGroup.equals(muscleGroup);
      if (equipment != null) cond = cond & e.equipment.equals(equipment);
      return cond;
    });
    q.orderBy([(e) => OrderingTerm(expression: e.name)]);
    return q.watch();
  }

  Stream<List<String>> watchMuscleGroups() => _distinct(exercises.muscleGroup);
  Stream<List<String>> watchEquipment() => _distinct(exercises.equipment);

  Stream<List<String>> _distinct(GeneratedColumn<String> column) {
    final q = selectOnly(exercises, distinct: true)
      ..addColumns([column])
      ..where(exercises.archived.equals(false))
      ..orderBy([OrderingTerm(expression: column)]);
    return q.map((row) => row.read(column)!).watch();
  }

  Stream<Exercise?> watchById(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).watchSingleOrNull();

  Future<Exercise?> getById(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  /// Case-insensitive exact match (the column is COLLATE NOCASE).
  Future<Exercise?> findByName(String name) => (select(
    exercises,
  )..where((e) => e.name.equals(name.trim()))).getSingleOrNull();

  Future<int> createCustom({
    required String name,
    required String muscleGroup,
    required String equipment,
    String description = '',
  }) async {
    final clean = name.trim();
    if (await findByName(clean) != null) {
      throw DuplicateExerciseNameException(clean);
    }
    return into(exercises).insert(
      ExercisesCompanion.insert(
        name: clean,
        muscleGroup: muscleGroup.trim(),
        equipment: equipment.trim(),
        description: Value(description.trim()),
        isCustom: const Value(true),
      ),
    );
  }

  /// Only custom exercises are editable; built-ins can only be archived.
  Future<void> updateCustom({
    required int id,
    required String name,
    required String muscleGroup,
    required String equipment,
    String description = '',
  }) async {
    final clean = name.trim();
    final clash = await findByName(clean);
    if (clash != null && clash.id != id) {
      throw DuplicateExerciseNameException(clean);
    }
    await (update(
      exercises,
    )..where((e) => e.id.equals(id) & e.isCustom.equals(true))).write(
      ExercisesCompanion(
        name: Value(clean),
        muscleGroup: Value(muscleGroup.trim()),
        equipment: Value(equipment.trim()),
        description: Value(description.trim()),
      ),
    );
  }

  Future<void> setArchived(int id, bool archived) =>
      (update(exercises)..where((e) => e.id.equals(id))).write(
        ExercisesCompanion(archived: Value(archived)),
      );

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}
