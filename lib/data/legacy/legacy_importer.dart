import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../daos/workout_dao.dart' show maxReps, maxWeightKg;
import 'legacy_store.dart';

/// The v1 data could not be understood. Nothing was written and the v1 data is untouched.
class LegacyImportException implements Exception {
  const LegacyImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum LegacyImportOutcome { alreadyImported, nothingToImport, imported }

class LegacyImportResult {
  const LegacyImportResult(this.outcome, {this.entryCount = 0});
  final LegacyImportOutcome outcome;
  final int entryCount;
}

/// One v1 entry after validation. Raw text is kept for anything unparseable.
class LegacyEntry {
  const LegacyEntry({
    required this.type,
    required this.weightKg,
    required this.reps,
    required this.sets,
    required this.notes,
  });
  final String type;
  final double weightKg;
  final int reps;
  final int sets;
  final List<String> notes;
}

/// Upper bound on sets created from one v1 entry: a typo like "3000" must not create
/// thousands of rows (standard 4). The raw value is kept in the notes.
const maxImportedSetsPerEntry = 50;
const _maxNameLength = 80;
const importedSessionName = 'Imported workouts';

/// Decodes and validates the v1 JSON. Throws [LegacyImportException] when the data is not
/// a list of objects each carrying a non-empty "type" (the shape v1 itself required).
List<LegacyEntry> decodeLegacyEntries(String raw) {
  final Object? root;
  try {
    root = jsonDecode(raw);
  } on FormatException catch (e) {
    throw LegacyImportException(
      'Saved workouts are not valid JSON (${e.message})',
    );
  }
  if (root is! List) {
    throw const LegacyImportException('Saved workouts are not a list');
  }
  final out = <LegacyEntry>[];
  for (final (i, item) in root.indexed) {
    if (item is! Map) {
      throw LegacyImportException('Saved workout ${i + 1} is not an object');
    }
    final type = item['type'];
    if (type is! String || type.trim().isEmpty) {
      throw LegacyImportException(
        'Saved workout ${i + 1} has no exercise type',
      );
    }
    final notes = <String>[];

    num? number(String key) {
      final v = item[key];
      if (v is num) return v;
      if (v is String) return num.tryParse(v.trim());
      return null;
    }

    void keep(String label, String key) =>
        notes.add('$label: "${item[key] ?? ''}"');

    var weight = number('weight')?.toDouble();
    if (weight == null ||
        !weight.isFinite ||
        weight < 0 ||
        weight > maxWeightKg) {
      keep('Weight', 'weight');
      weight = 0;
    }

    var reps = 0;
    final r = number('reps');
    if (r != null && r == r.roundToDouble() && r >= 0 && r <= maxReps) {
      reps = r.toInt();
    } else {
      keep('Reps', 'reps');
    }

    var sets = 1;
    final s = number('sets');
    if (s != null &&
        s == s.roundToDouble() &&
        s >= 1 &&
        s <= maxImportedSetsPerEntry) {
      sets = s.toInt();
    } else {
      keep('Sets', 'sets');
    }

    var name = type.trim();
    if (name.length > _maxNameLength) {
      notes.add('Exercise: "$name"');
      name = name.substring(0, _maxNameLength).trim();
    }

    out.add(
      LegacyEntry(
        type: name,
        weightKg: weight,
        reps: reps,
        sets: sets,
        notes: notes,
      ),
    );
  }
  return out;
}

/// One-shot v1 -> v2 import (ARCHITECTURE §6). Atomic and idempotent: the import and the
/// "done" flag are written in the same transaction.
class LegacyImporter {
  LegacyImporter(this.db, {required this.readLegacy, required this.now});

  final AppDatabase db;
  final LegacyReader readLegacy;
  final DateTime Function() now;

  Future<LegacyImportResult> run() async {
    final settings = await db.settingsDao.getSettings();
    if (settings.legacyImportedAt != null) {
      return const LegacyImportResult(LegacyImportOutcome.alreadyImported);
    }
    final raw = await readLegacy();
    final at = now();
    if (raw == null) {
      await db.settingsDao.markLegacyImported(at);
      return const LegacyImportResult(LegacyImportOutcome.nothingToImport);
    }
    final entries = decodeLegacyEntries(raw); // throws before any write
    await db.transaction(() async {
      if (entries.isNotEmpty) await _write(entries, at);
      await db.settingsDao.markLegacyImported(at);
    });
    return entries.isEmpty
        ? const LegacyImportResult(LegacyImportOutcome.nothingToImport)
        : LegacyImportResult(
            LegacyImportOutcome.imported,
            entryCount: entries.length,
          );
  }

  Future<void> _write(List<LegacyEntry> entries, DateTime at) async {
    final sessionId = await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            name: importedSessionName,
            startedAt: at,
            endedAt: Value(at),
            notes: const Value(
              'Imported from the previous version of the app, which did not record dates.',
            ),
          ),
        );
    final exerciseIds = <String, int>{};
    final sets = <SetEntriesCompanion>[];
    for (final (i, e) in entries.indexed) {
      final key = e.type.toLowerCase();
      var exId = exerciseIds[key];
      if (exId == null) {
        exId =
            (await db.exerciseDao.findByName(e.type))?.id ??
            await db
                .into(db.exercises)
                .insert(
                  ExercisesCompanion.insert(
                    name: e.type,
                    muscleGroup: 'Other',
                    equipment: 'Other',
                    isCustom: const Value(true),
                  ),
                );
        exerciseIds[key] = exId;
      }
      final seId = await db
          .into(db.sessionExercises)
          .insert(
            SessionExercisesCompanion.insert(
              sessionId: sessionId,
              exerciseId: exId,
              position: i,
              notes: Value(e.notes.isEmpty ? null : e.notes.join('; ')),
            ),
          );
      for (var n = 0; n < e.sets; n++) {
        sets.add(
          SetEntriesCompanion.insert(
            sessionExerciseId: seId,
            position: n,
            weightKg: Value(e.weightKg),
            reps: Value(e.reps),
            completedAt: Value(at),
          ),
        );
      }
    }
    await db.batch((b) => b.insertAll(db.setEntries, sets));
  }
}
