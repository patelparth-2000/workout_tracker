import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_provider.dart';
import '../../../data/models.dart';
import '../../../utils/clock.dart';

part 'routine_providers.g.dart';

@riverpod
Stream<List<RoutineSummary>> routines(Ref ref) =>
    ref.watch(appDatabaseProvider).routineDao.watchRoutines();

/// Routine writes (keepAlive: only ever `ref.read`).
@Riverpod(keepAlive: true)
class RoutineController extends _$RoutineController {
  @override
  void build() {}

  Future<RoutineDetail?> load(int id) =>
      ref.read(appDatabaseProvider).routineDao.getRoutine(id);

  Future<int> save({
    int? id,
    required String name,
    String? notes,
    required List<RoutineExerciseDraft> items,
  }) => ref
      .read(appDatabaseProvider)
      .routineDao
      .saveRoutine(
        id: id,
        name: name,
        notes: notes,
        items: items,
        now: ref.read(clockProvider)(),
      );

  Future<void> delete(int id) =>
      ref.read(appDatabaseProvider).routineDao.deleteRoutine(id);
}
