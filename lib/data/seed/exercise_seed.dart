import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../../utils/images.dart';
import '../app_database.dart';

/// Parses the bundled exercise seed. Throws [FormatException] on any malformed entry, so a
/// broken asset fails loudly at first launch instead of seeding half a library.
List<ExercisesCompanion> parseExerciseSeed(String source) {
  final root = jsonDecode(source);
  if (root is! Map || root['exercises'] is! List) {
    throw const FormatException('Seed must be {"exercises": [...]}');
  }
  final seen = <String>{};
  final out = <ExercisesCompanion>[];
  for (final (i, e) in (root['exercises'] as List).indexed) {
    String field(String key, {bool optional = false}) {
      final v = e is Map ? e[key] : null;
      if (v == null && optional) return '';
      if (v is! String || (!optional && v.trim().isEmpty)) {
        throw FormatException(
          'Seed entry $i: "$key" must be a non-empty string',
        );
      }
      return v.trim();
    }

    final name = field('name');
    if (!seen.add(name.toLowerCase())) {
      throw FormatException('Seed entry $i: duplicate name "$name"');
    }
    final gif = field('gif_asset', optional: true);
    out.add(
      ExercisesCompanion.insert(
        name: name,
        muscleGroup: field('muscle_group'),
        equipment: field('equipment'),
        description: Value(field('description', optional: true)),
        gifAsset: Value(gif.isEmpty ? null : gif),
      ),
    );
  }
  return out;
}

Future<List<ExercisesCompanion>> loadBundledExerciseSeed() async =>
    parseExerciseSeed(await rootBundle.loadString(DataAssets.exerciseSeed));
