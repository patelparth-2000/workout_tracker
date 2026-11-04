import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/app_database.dart';
import 'package:workout_tracker/data/backup/backup_codec.dart';
import 'package:workout_tracker/data/models.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  final t0 = DateTime(2026, 5, 1, 7, 30);
  final exportedAt = DateTime.utc(2026, 11, 4);

  setUp(() => db = testDatabase());
  tearDown(() => db.close());

  Future<void> seedRich(AppDatabase d) async {
    await d.exerciseDao.createCustom(
      name: 'Zercher, "front"',
      muscleGroup: 'Quads',
      equipment: 'Barbell',
      description: 'Line 1\nLine 2',
    );
    final routine = await d.routineDao.saveRoutine(
      name: 'Legs',
      notes: 'heavy',
      items: [
        RoutineExerciseDraft(
          exerciseId: await exerciseId(d, 'Squat'),
          targetSets: 4,
          targetReps: 5,
          restSeconds: 180,
        ),
      ],
      now: t0,
    );
    await logFinishedSession(
      d,
      exercise: 'Squat',
      at: t0,
      sets: [(100, 5), (102.5, 3)],
    );
    await d.workoutDao.startSession(
      name: 'Now',
      routineId: routine,
      now: t0.add(const Duration(days: 1)),
    );
    await d.settingsDao.setUnit('lb');
    await d.settingsDao.markLegacyImported(t0);
  }

  Future<String> export(AppDatabase d) async =>
      encodeBackup(await readBackupData(d), exportedAt: exportedAt);

  test(
    'export -> import into a fresh database -> export is identical',
    () async {
      await seedRich(db);
      final first = await export(db);

      final other = testDatabase(seed: const []);
      addTearDown(other.close);
      await replaceAllData(other, decodeBackup(first));
      expect(await export(other), first);

      final s = await other.settingsDao.getSettings();
      expect(s.unit, 'lb');
      expect((await other.workoutDao.getActiveSession())!.name, 'Now');
      // Autoincrement continues after restored ids.
      final newId = await other.exerciseDao.createCustom(
        name: 'New',
        muscleGroup: 'Core',
        equipment: 'Other',
      );
      expect(
        newId,
        greaterThan((await other.select(other.exercises).get()).length - 1),
      );
    },
  );

  test('the file carries the format marker and version', () async {
    final json = jsonDecode(await export(db)) as Map<String, Object?>;
    expect(json['format'], backupFormat);
    expect(json['version'], backupVersion);
    expect(json['exported_at'], '2026-11-04T00:00:00.000Z');
  });

  group('rejects, leaving existing data intact', () {
    late String valid;
    setUp(() async {
      await seedRich(db);
      valid = await export(db);
    });

    String mutate(void Function(Map<String, dynamic> root) f) {
      final root = jsonDecode(valid) as Map<String, dynamic>;
      f(root);
      return jsonEncode(root);
    }

    Map<String, dynamic> tables(Map<String, dynamic> r) =>
        r['tables'] as Map<String, dynamic>;
    Map<String, dynamic> firstRow(Map<String, dynamic> r, String t) =>
        (tables(r)[t] as List).first as Map<String, dynamic>;

    final cases =
        <
          String,
          String Function(
            String Function(void Function(Map<String, dynamic>)) m,
          )
        >{
          'not JSON': (_) => '{oops',
          'another app\'s file': (m) =>
              m((r) => r['format'] = 'something_else'),
          'newer version': (m) => m((r) => r['version'] = backupVersion + 1),
          'version 0': (m) => m((r) => r['version'] = 0),
          'missing table': (m) => m((r) => tables(r).remove('set_entries')),
          'weight as text': (m) =>
              m((r) => firstRow(r, 'set_entries')['weight_kg'] = '100'),
          'negative reps': (m) =>
              m((r) => firstRow(r, 'set_entries')['reps'] = -1),
          'weight above bound': (m) =>
              m((r) => firstRow(r, 'set_entries')['weight_kg'] = 1e9),
          'bad date': (m) => m(
            (r) => firstRow(r, 'workout_sessions')['started_at'] = 'yesterday',
          ),
          'unknown unit': (m) =>
              m((r) => (tables(r)['settings'] as Map)['unit'] = 'stone'),
          'dangling foreign key': (m) => m(
            (r) => firstRow(r, 'set_entries')['session_exercise_id'] = 9999,
          ),
          'duplicate id': (m) => m((r) {
            final list = tables(r)['exercises'] as List;
            list.add(
              Map<String, dynamic>.from(list.first as Map)
                ..['name'] = 'Other name',
            );
          }),
          'duplicate exercise name': (m) => m((r) {
            final list = tables(r)['exercises'] as List;
            list.add(
              Map<String, dynamic>.from(list.first as Map)..['id'] = 777,
            );
          }),
          'two workouts in progress': (m) => m((r) {
            for (final s in tables(r)['workout_sessions'] as List) {
              (s as Map)['ended_at'] = null;
            }
          }),
        };

    for (final entry in cases.entries) {
      test(entry.key, () async {
        final before = await export(db);
        final bad = entry.value(mutate);
        expect(() => decodeBackup(bad), throwsA(isA<BackupFormatException>()));
        expect(await export(db), before);
      });
    }

    test('oversized file is rejected before decoding', () {
      final huge = ' ' * (maxBackupBytes + 1);
      expect(
        () => decodeBackup(huge),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.message,
            'message',
            contains('too large'),
          ),
        ),
      );
    });

    test('non-bundled GIF paths are dropped', () {
      final d = decodeBackup(
        mutate(
          (r) => firstRow(r, 'exercises')['gif_asset'] = '../../etc/passwd',
        ),
      );
      expect(d.exercises.first.gifAsset, isNull);
    });

    test('a failure during the replace rolls back to the old data', () async {
      final before = await export(db);
      final data = decodeBackup(valid);
      await db.customStatement('DROP TABLE set_entries');
      await expectLater(replaceAllData(db, data), throwsA(anything));
      final exercises = await db.select(db.exercises).get();
      expect(exercises.map((e) => e.name), contains('Zercher, "front"'));
      expect(before, isNotEmpty);
    });
  });

  test(
    'an insert failing AFTER the deletes still rolls back everything',
    () async {
      await seedRich(db);
      final before = await export(db);
      final good = decodeBackup(before);
      // Bypass the decoder's checks: a set pointing at a missing exercise row makes the
      // batch insert fail after every table has already been emptied.
      final broken = BackupData(
        exercises: good.exercises,
        routines: good.routines,
        routineExercises: good.routineExercises,
        sessions: good.sessions,
        sessionExercises: good.sessionExercises,
        sets: [
          ...good.sets,
          good.sets.first.copyWith(id: 9999, sessionExerciseId: 9999),
        ],
        settings: good.settings,
      );
      await expectLater(replaceAllData(db, broken), throwsA(anything));
      expect(await export(db), before);
    },
  );

  group('CSV', () {
    test('header, one row per set, quoting', () async {
      await seedRich(db);
      final csv = await exportSetsCsv(db);
      final lines = const LineSplitter().convert(csv);
      expect(
        lines.first,
        'date,workout,exercise,set,weight_kg,reps,set_type,rpe,completed',
      );
      expect(
        lines,
        hasLength(1 + 2 + 4),
      ); // header + finished + in-progress (4 targets)
      expect(lines[1], endsWith(',W,Squat,1,100.0,5,normal,,yes'));
      expect(lines[2], contains(',2,102.5,3,'));
    });

    test('fields are quoted and formulas neutralised', () {
      expect(csvField('a,b'), '"a,b"');
      expect(csvField('say "hi"'), '"say ""hi"""');
      expect(csvField('two\nlines'), '"two\nlines"');
      expect(csvField('=HYPERLINK("x")'), '"\'=HYPERLINK(""x"")"');
      expect(csvField('+1'), "'+1");
      expect(csvField('-5'), "'-5");
      expect(csvField('@sum'), "'@sum");
      expect(csvField(-5), '-5'); // numbers are numbers
      expect(csvField(null), '');
    });
  });
}
