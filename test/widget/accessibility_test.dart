import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/app_database.dart';
import 'package:workout_tracker/data/models.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

Future<void> _rich(AppDatabase db) async {
  final now = DateTime.now();
  await logFinishedSession(
    db,
    exercise: 'Squat',
    at: now.subtract(const Duration(days: 9)),
    sets: [(100, 5)],
  );
  await logFinishedSession(
    db,
    exercise: 'Squat',
    at: now.subtract(const Duration(days: 2)),
    sets: [(110, 5), (60, 10)],
  );
  await db.routineDao.saveRoutine(
    name: 'Leg day with a deliberately long routine name',
    items: [RoutineExerciseDraft(exerciseId: await exerciseId(db, 'Squat'))],
    now: now,
  );
}

/// Screens to visit: (description, how to get there).
final _screens = <(String, Future<void> Function(WidgetTester))>[
  ('Workout tab', (t) async {}),
  ('History tab', (t) => openTab(t, 'History')),
  ('Exercises tab', (t) => openTab(t, 'Exercises')),
  ('Progress tab', (t) => openTab(t, 'Progress')),
  ('Settings tab', (t) => openTab(t, 'Settings')),
  (
    'Session detail',
    (t) async {
      await openTab(t, 'History');
      await scrollAndTap(t, find.text('W').first);
    },
  ),
  (
    'Exercise detail',
    (t) async {
      await openTab(t, 'Exercises');
      await scrollAndTap(t, find.text('Squat'));
    },
  ),
  (
    'Active workout',
    (t) async {
      await scrollAndTap(t, find.text('Start'));
      await scrollAndTap(t, find.byTooltip('Mark set 1 done'));
    },
  ),
  (
    'Exercise picker',
    (t) async {
      await scrollAndTap(t, find.text('New routine'));
      await scrollAndTap(t, find.text('Add exercise'));
    },
  ),
  (
    'New exercise form',
    (t) async {
      await openTab(t, 'Exercises');
      await t.tap(find.text('New exercise'));
      await settle(t);
    },
  ),
  (
    'Empty active workout',
    (t) async {
      await t.tap(find.text('Start empty workout'));
      await settle(t);
    },
  ),
  (
    'Routine editor',
    (t) async {
      await scrollAndTap(
        t,
        find.text('Leg day with a deliberately long routine name'),
      );
    },
  ),
];

void main() {
  for (final mode in ['light', 'dark']) {
    for (final (name, open) in _screens) {
      testAppWidgets(
        '$name meets tap-target, label and contrast guidelines ($mode)',
        (app) async {
          final tester = app.tester;
          final handle = tester.ensureSemantics();
          await dbCall(tester, () => app.db.settingsDao.setThemeMode(mode));
          await open(tester);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          handle.dispose();
        },
        setup: _rich,
        surfaceSize: const Size(412, 915),
      );
    }
  }

  for (final (name, open) in _screens) {
    testAppWidgets(
      '$name does not overflow at 2x text on a small phone',
      (app) async {
        await open(app.tester);
        // Any RenderFlex overflow is reported as a test failure by flutter_test.
        expect(app.tester.takeException(), isNull);
      },
      setup: _rich,
      surfaceSize: const Size(360, 740),
      textScale: 2,
    );
  }
}
