import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:workout_tracker/data/app_database.dart';
import 'package:workout_tracker/data/legacy/legacy_importer.dart';
import 'package:workout_tracker/data/legacy/legacy_store.dart';

import '../helpers/test_database.dart';

String _v1(List<Map<String, Object?>> entries) => jsonEncode([
  for (final e in entries)
    {'icon': 'images/gifs/x.gif', 'description': 'd', ...e},
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  final now = DateTime(2026, 11, 4, 9);

  setUp(() => db = testDatabase());
  tearDown(() => db.close());

  LegacyImporter importer(String? raw) =>
      LegacyImporter(db, readLegacy: () async => raw, now: () => now);

  Future<List<(String, String?, String)>> imported() async {
    final sessions = await db.select(db.workoutSessions).get();
    if (sessions.isEmpty) return [];
    final d = (await db.workoutDao
        .watchSessionDetail(sessions.single.id)
        .first)!;
    return [
      for (final e in d.exercises)
        (
          e.exercise.name,
          e.entry.notes,
          e.sets.map((s) => '${s.weightKg}x${s.reps}').join(' '),
        ),
    ];
  }

  test(
    'clean data: one finished session dated now, sets = N rows, flag set',
    () async {
      final r = await importer(
        _v1([
          {'type': 'Squat', 'weight': '100', 'reps': '5', 'sets': '3'},
          {'type': 'Bench press', 'weight': '60.5', 'reps': '8', 'sets': '2'},
        ]),
      ).run();
      expect(r.outcome, LegacyImportOutcome.imported);
      expect(r.entryCount, 2);
      final session = (await db.select(db.workoutSessions).get()).single;
      expect(session.name, importedSessionName);
      expect(session.startedAt, now);
      expect(session.endedAt, now);
      expect(await imported(), [
        ('Squat', null, '100.0x5 100.0x5 100.0x5'),
        ('Bench press', null, '60.5x8 60.5x8'),
      ]);
      final sets = await db.select(db.setEntries).get();
      expect(sets.every((s) => s.completedAt == now), isTrue);
      expect((await db.settingsDao.getSettings()).legacyImportedAt, now);
      // It shows up in history.
      expect(await db.workoutDao.historyPage(), hasLength(1));
    },
  );

  test(
    'messy strings are trimmed, unparseable values kept as notes, never dropped',
    () async {
      await importer(
        _v1([
          {'type': ' squat ', 'weight': '10 ', 'reps': 'abc', 'sets': ''},
          {'type': 'Squat', 'weight': '-5', 'reps': '8.5', 'sets': '0'},
          {'type': 'Squat', 'weight': 'NaN', 'reps': '3', 'sets': '9999'},
          {'type': 'Squat', 'weight': 20, 'reps': 4, 'sets': 2},
        ]),
      ).run();
      final rows = await imported();
      expect(rows[0], ('Squat', 'Reps: "abc"; Sets: ""', '10.0x0'));
      expect(rows[1], (
        'Squat',
        'Weight: "-5"; Reps: "8.5"; Sets: "0"',
        '0.0x0',
      ));
      expect(rows[2], ('Squat', 'Weight: "NaN"; Sets: "9999"', '0.0x3'));
      expect(rows[3], ('Squat', null, '20.0x4 20.0x4'));
      // Mapped onto the ONE seeded Squat (case-insensitive), not duplicated.
      expect(
        (await db.select(db.exercises).get()).where(
          (e) => e.name.toLowerCase() == 'squat',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'unknown type becomes one custom exercise, reused across entries',
    () async {
      await importer(
        _v1([
          {'type': 'Zercher squat', 'weight': '1', 'reps': '1', 'sets': '1'},
          {'type': 'zercher SQUAT', 'weight': '2', 'reps': '1', 'sets': '1'},
        ]),
      ).run();
      final custom = (await db.select(db.exercises).get()).where(
        (e) => e.isCustom,
      );
      expect(custom.single.name, 'Zercher squat');
      expect(custom.single.muscleGroup, 'Other');
    },
  );

  test('second launch does not import twice', () async {
    final raw = _v1([
      {'type': 'Squat', 'weight': '1', 'reps': '1', 'sets': '1'},
    ]);
    await importer(raw).run();
    final second = await importer(raw).run();
    expect(second.outcome, LegacyImportOutcome.alreadyImported);
    expect(await db.select(db.workoutSessions).get(), hasLength(1));
  });

  test('no legacy key, or an empty list: nothing imported, flag set', () async {
    expect(
      (await importer(null).run()).outcome,
      LegacyImportOutcome.nothingToImport,
    );
    expect((await db.settingsDao.getSettings()).legacyImportedAt, now);

    await db.close();
    db = testDatabase();
    expect(
      (await importer('[]').run()).outcome,
      LegacyImportOutcome.nothingToImport,
    );
    expect(await db.select(db.workoutSessions).get(), isEmpty);
    expect((await db.settingsDao.getSettings()).legacyImportedAt, now);
  });

  for (final (label, raw) in [
    ('not JSON', '{not json'),
    ('not a list', '{"type":"Squat"}'),
    ('element not an object', '[1]'),
    ('element without type', '[{"weight":"1"}]'),
  ]) {
    test(
      'corrupt data ($label): throws, writes nothing, flag stays unset',
      () async {
        await expectLater(
          importer(raw).run(),
          throwsA(isA<LegacyImportException>()),
        );
        expect(await db.select(db.workoutSessions).get(), isEmpty);
        expect((await db.settingsDao.getSettings()).legacyImportedAt, isNull);
      },
    );
  }

  test('a failure mid-import rolls everything back', () async {
    await db.customStatement('DROP TABLE set_entries');
    await expectLater(
      importer(
        _v1([
          {'type': 'Brand new', 'weight': '1', 'reps': '1', 'sets': '1'},
        ]),
      ).run(),
      throwsA(anything),
    );
    expect(await db.select(db.workoutSessions).get(), isEmpty);
    expect(
      (await db.select(db.exercises).get()).map((e) => e.name),
      isNot(contains('Brand new')),
    );
    expect((await db.settingsDao.getSettings()).legacyImportedAt, isNull);
  });

  group('with real GetStorage', () {
    late Directory tmp;
    setUpAll(() async {
      tmp = await Directory.systemTemp.createTemp('wt_legacy_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tmp.path,
          );
      await GetStorage('GetStorage', tmp.path).initStorage;
    });
    // The OS temp dir is not deleted here: GetStorage flushes asynchronously after
    // erase(), and deleting the folder under a pending flush made this test flaky.
    setUp(() => GetStorage().erase());

    LegacyImporter real() =>
        LegacyImporter(db, readLegacy: readLegacyWorkoutJson, now: () => now);

    test(
      'the legacy key is left untouched after a successful import',
      () async {
        final raw = _v1([
          {'type': 'Squat', 'weight': '1', 'reps': '1', 'sets': '1'},
        ]);
        await GetStorage().write(legacyWorkoutListKey, raw);
        await real().run();
        expect(GetStorage().read<String>(legacyWorkoutListKey), raw);
        expect(await db.select(db.workoutSessions).get(), hasLength(1));
      },
    );

    test('the legacy key is left untouched after a failed import', () async {
      await GetStorage().write(legacyWorkoutListKey, '{not json');
      await expectLater(real().run(), throwsA(isA<LegacyImportException>()));
      expect(GetStorage().read<String>(legacyWorkoutListKey), '{not json');
    });
  });
}
