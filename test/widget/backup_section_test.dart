import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/app_database.dart';
import 'package:workout_tracker/data/backup/backup_codec.dart';
import 'package:workout_tracker/src/settings/viewmodel/backup_controller.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

class FakeBackupPlatform extends BackupPlatform {
  FakeBackupPlatform({this.toPick});
  final shared = <(String, String)>[];
  String? toPick;

  @override
  Future<void> shareText(
    String fileName,
    String contents,
    String mimeType,
  ) async => shared.add((fileName, contents));

  @override
  Future<String?> pickBackupText() async => toPick;
}

Future<void> _openBackup(WidgetTester tester, String tile) async {
  await openTab(tester, 'Settings');
  await tester.scrollUntilVisible(
    find.text(tile),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.text(tile));
  await settle(tester);
}

Future<String> _backupOf(Future<void> Function(AppDatabase) seed) async {
  final db = testDatabase();
  await seed(db);
  final json = encodeBackup(
    await readBackupData(db),
    exportedAt: DateTime.utc(2026),
  );
  await db.close();
  return json;
}

void main() {
  final fake = FakeBackupPlatform();

  testAppWidgets(
    'export backup shares a versioned JSON file',
    (app) async {
      await _openBackup(app.tester, 'Export backup');
      expect(
        fake.shared.last.$1,
        matches(RegExp(r'^workout_tracker_backup_\d{8}-\d{4}\.json$')),
      );
      expect(
        fake.shared.last.$2,
        contains('"format": "workout_tracker_backup"'),
      );
    },
    surfaceSize: const Size(800, 1800),
    overrides: [backupPlatformProvider.overrideWithValue(fake)],
  );

  testAppWidgets(
    'export CSV shares the sets',
    (app) async {
      await _openBackup(app.tester, 'Export sets as CSV');
      expect(fake.shared.last.$1, endsWith('.csv'));
      expect(fake.shared.last.$2, contains('Squat,1,100.0,5'));
    },
    setup: (db) => logFinishedSession(
      db,
      exercise: 'Squat',
      at: DateTime(2026),
      sets: [(100, 5)],
    ),
    surfaceSize: const Size(800, 1800),
    overrides: [backupPlatformProvider.overrideWithValue(fake)],
  );

  final restoreFake = FakeBackupPlatform();
  testAppWidgets(
    'restore asks for confirmation, then replaces all data',
    (app) async {
      final tester = app.tester;
      restoreFake.toPick = await tester.runAsync(
        () => _backupOf(
          (db) => logFinishedSession(
            db,
            exercise: 'Bench press',
            at: DateTime(2026),
            sets: [(80, 8)],
          ),
        ),
      );
      await _openBackup(tester, 'Restore from backup');
      expect(find.text('Replace all data?'), findsOneWidget);
      expect(find.textContaining('This backup has 1 workout,'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
      await settle(tester);
      expect(find.text('Backup restored'), findsOneWidget);
      final sessions = await dbCall(
        tester,
        () => app.db.select(app.db.workoutSessions).get(),
      );
      expect(sessions, hasLength(1));
    },
    setup: (db) async {
      await logFinishedSession(
        db,
        exercise: 'Squat',
        at: DateTime(2025),
        sets: [(1, 1)],
      );
      await logFinishedSession(
        db,
        exercise: 'Squat',
        at: DateTime(2025, 2),
        sets: [(1, 1)],
      );
    },
    surfaceSize: const Size(800, 1800),
    overrides: [backupPlatformProvider.overrideWithValue(restoreFake)],
  );

  final badFake = FakeBackupPlatform(toPick: '{"format":"nope"}');
  testAppWidgets(
    'an invalid file is rejected with a message and nothing changes',
    (app) async {
      final tester = app.tester;
      await _openBackup(tester, 'Restore from backup');
      expect(find.text('Replace all data?'), findsNothing);
      expect(
        find.textContaining(
          'Not restored: This is not a Workout Tracker backup',
        ),
        findsOneWidget,
      );
      final sessions = await dbCall(
        tester,
        () => app.db.select(app.db.workoutSessions).get(),
      );
      expect(sessions, hasLength(1));
    },
    setup: (db) => logFinishedSession(
      db,
      exercise: 'Squat',
      at: DateTime(2025),
      sets: [(1, 1)],
    ),
    surfaceSize: const Size(800, 1800),
    overrides: [backupPlatformProvider.overrideWithValue(badFake)],
  );

  final cancelFake = FakeBackupPlatform();
  testAppWidgets(
    'cancelling the confirmation keeps the current data',
    (app) async {
      final tester = app.tester;
      cancelFake.toPick = await tester.runAsync(() => _backupOf((_) async {}));
      await _openBackup(tester, 'Restore from backup');
      expect(find.text('Replace all data?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      final sessions = await dbCall(
        tester,
        () => app.db.select(app.db.workoutSessions).get(),
      );
      expect(sessions, hasLength(1));
      expect(find.text('Backup restored'), findsNothing);
    },
    setup: (db) => logFinishedSession(
      db,
      exercise: 'Squat',
      at: DateTime(2025),
      sets: [(1, 1)],
    ),
    surfaceSize: const Size(800, 1800),
    overrides: [backupPlatformProvider.overrideWithValue(cancelFake)],
  );
}
