import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';
import 'seed/exercise_seed.dart';

part 'database_provider.g.dart';

/// The single on-device database. Tests override this with an in-memory one.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(
    driftDatabase(name: 'workout_tracker'),
    seedLoader: loadBundledExerciseSeed,
  );
  ref.onDispose(db.close);
  return db;
}
