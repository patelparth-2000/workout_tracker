import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/app_database.dart';
import 'package:workout_tracker/data/seed/exercise_seed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('bundled seed asset', () {
    late List<ExercisesCompanion> seed;
    setUpAll(() async => seed = await loadBundledExerciseSeed());

    test('has at least 60 exercises with unique names', () {
      expect(seed.length, greaterThanOrEqualTo(60));
      final names = seed.map((e) => e.name.value.toLowerCase()).toSet();
      expect(names, hasLength(seed.length));
    });

    test(
      'the five v1 exercises keep their exact names, GIFs and descriptions',
      () {
        const v1 = [
          'Barbell row',
          'Bench press',
          'Shoulder press',
          'Deadlift',
          'Squat',
        ];
        for (final name in v1) {
          final e = seed.singleWhere((s) => s.name.value == name);
          expect(e.gifAsset.value, isNotNull, reason: name);
          expect(File(e.gifAsset.value!).existsSync(), isTrue, reason: name);
          expect(
            e.description.value,
            contains(name.split(' ').last.toLowerCase()),
          );
        }
      },
    );
  });

  group('parseExerciseSeed', () {
    test('rejects malformed input', () {
      expect(() => parseExerciseSeed('[]'), throwsFormatException);
      expect(
        () => parseExerciseSeed(
          '{"exercises":[{"name":"","muscle_group":"a","equipment":"b"}]}',
        ),
        throwsFormatException,
      );
      expect(
        () => parseExerciseSeed(
          '{"exercises":[{"name":"A","muscle_group":1,"equipment":"b"}]}',
        ),
        throwsFormatException,
      );
      expect(
        () => parseExerciseSeed(
          '{"exercises":[{"name":"A","muscle_group":"a","equipment":"b"},'
          '{"name":"a","muscle_group":"a","equipment":"b"}]}',
        ),
        throwsFormatException,
      );
    });
  });

  test('seeds on creation only, never again on reopen', () async {
    final dir = await Directory.systemTemp.createTemp('wt_seed_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    var calls = 0;
    Future<List<ExercisesCompanion>> loader() async {
      calls++;
      return [
        ExercisesCompanion.insert(
          name: 'Squat',
          muscleGroup: 'Quads',
          equipment: 'Barbell',
        ),
      ];
    }

    var db = AppDatabase(NativeDatabase(file), seedLoader: loader);
    expect(await db.select(db.exercises).get(), hasLength(1));
    await db.exerciseDao.setArchived(1, true);
    await db.close();

    db = AppDatabase(NativeDatabase(file), seedLoader: loader);
    final rows = await db.select(db.exercises).get();
    expect(rows.single.archived, isTrue);
    expect(calls, 1);
    await db.close();
  });
}
