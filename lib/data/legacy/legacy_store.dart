import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'legacy_store.g.dart';

/// GetStorage key under which v1 kept the whole workout list as one JSON string.
const legacyWorkoutListKey = 'workoutList';

/// Reads the raw v1 JSON, or null when there is none. Read-only by design: the v2 importer
/// must never be able to delete or overwrite the legacy data (ARCHITECTURE §6).
typedef LegacyReader = Future<String?> Function();

Future<String?> readLegacyWorkoutJson() async {
  await GetStorage.init();
  final value = GetStorage().read<Object?>(legacyWorkoutListKey);
  if (value == null || value is String) return value as String?;
  // v1 always wrote a String; anything else is handed to the validator as JSON.
  return jsonEncode(value);
}

@Riverpod(keepAlive: true)
LegacyReader legacyReader(Ref ref) => readLegacyWorkoutJson;
