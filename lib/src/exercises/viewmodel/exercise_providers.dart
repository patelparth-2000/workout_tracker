import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/app_database.dart';
import '../../../data/database_provider.dart';
import '../model/exercise_options.dart';

part 'exercise_providers.g.dart';

/// Filter state per screen ("library" tab, "picker").
@riverpod
class ExerciseFilter extends _$ExerciseFilter {
  @override
  ExerciseFilterState build(String scope) => const ExerciseFilterState();

  void setQuery(String q) => state = state.copyWith(query: q);
  void setMuscleGroup(String? g) =>
      state = state.copyWith(muscleGroup: () => g);
  void setEquipment(String? e) => state = state.copyWith(equipment: () => e);
  void setShowArchived(bool v) => state = state.copyWith(showArchived: v);
  void clear() => state = const ExerciseFilterState();
}

@riverpod
Stream<List<Exercise>> exerciseList(Ref ref, String scope) {
  final f = ref.watch(exerciseFilterProvider(scope));
  return ref
      .watch(appDatabaseProvider)
      .exerciseDao
      .watchExercises(
        query: f.query,
        muscleGroup: f.muscleGroup,
        equipment: f.equipment,
        includeArchived: f.showArchived,
      );
}

@riverpod
Stream<List<String>> muscleGroups(Ref ref) =>
    ref.watch(appDatabaseProvider).exerciseDao.watchMuscleGroups();

@riverpod
Stream<List<String>> equipmentTypes(Ref ref) =>
    ref.watch(appDatabaseProvider).exerciseDao.watchEquipment();

@riverpod
Stream<Exercise?> exerciseById(Ref ref, int id) =>
    ref.watch(appDatabaseProvider).exerciseDao.watchById(id);

/// Exercise writes (keepAlive: command controllers are only read, never watched).
@Riverpod(keepAlive: true)
class ExerciseController extends _$ExerciseController {
  @override
  void build() {}

  Future<int> create({
    required String name,
    required String muscleGroup,
    required String equipment,
    String description = '',
  }) => ref
      .read(appDatabaseProvider)
      .exerciseDao
      .createCustom(
        name: name,
        muscleGroup: muscleGroup,
        equipment: equipment,
        description: description,
      );

  Future<void> update({
    required int id,
    required String name,
    required String muscleGroup,
    required String equipment,
    String description = '',
  }) => ref
      .read(appDatabaseProvider)
      .exerciseDao
      .updateCustom(
        id: id,
        name: name,
        muscleGroup: muscleGroup,
        equipment: equipment,
        description: description,
      );

  Future<void> setArchived(int id, bool archived) =>
      ref.read(appDatabaseProvider).exerciseDao.setArchived(id, archived);
}
