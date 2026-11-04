import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/models.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

Finder _field(String label) => find.widgetWithText(TextField, label);

void main() {
  testAppWidgets('empty home: no routines; start an empty workout', (
    app,
  ) async {
    final tester = app.tester;
    expect(find.textContaining('No routines yet'), findsOneWidget);
    await tester.tap(find.text('Start empty workout'));
    await settle(tester);
    expect(
      find.text('Add your first exercise to start logging sets.'),
      findsOneWidget,
    );
    expect(find.text('Finish'), findsOneWidget);
  });

  testAppWidgets(
    'log sets: add exercise, type, validate, complete, rest timer, add set',
    (app) async {
      final tester = app.tester;
      await tester.tap(find.text('Start empty workout'));
      await settle(tester);
      await tester.tap(find.text('Add exercise'));
      await settle(tester);
      await tester.tap(find.text('Squat'));
      await settle(tester);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.byTooltip('Mark set 1 done'), findsOneWidget);

      // Invalid weight blocks completion.
      await tester.enterText(_field('kg'), '1.2.3');
      await settle(tester);
      expect(find.text('Invalid'), findsOneWidget);
      await tester.tap(find.byTooltip('Mark set 1 done'));
      await settle(tester);
      var sets = await dbCall(
        tester,
        () => app.db.select(app.db.setEntries).get(),
      );
      expect(sets.single.completedAt, isNull);

      await tester.enterText(_field('kg'), '100');
      await tester.enterText(_field('Reps'), '5');
      await settle(tester);
      expect(find.text('Invalid'), findsNothing);
      await tester.tap(find.byTooltip('Mark set 1 done'));
      await settle(tester);
      sets = await dbCall(tester, () => app.db.select(app.db.setEntries).get());
      expect((sets.single.weightKg, sets.single.reps), (100.0, 5));
      expect(sets.single.completedAt, isNotNull);
      expect(find.text('Rest 1:30'), findsOneWidget);
      expect(find.byTooltip('Mark set 1 not done'), findsOneWidget);

      await tester.tap(find.byTooltip('Add 15 seconds'));
      await settle(tester);
      expect(find.text('Rest 1:45'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await settle(tester);
      expect(find.textContaining('Rest '), findsNothing);

      await tester.tap(find.text('Add set to Squat'));
      await settle(tester);
      sets = await dbCall(tester, () => app.db.select(app.db.setEntries).get());
      expect(sets, hasLength(2));
      expect((sets.last.weightKg, sets.last.reps), (100.0, 5));
    },
  );

  testAppWidgets('lb display: typed pounds are stored as kg', (app) async {
    final tester = app.tester;
    await dbCall(tester, () => app.db.settingsDao.setUnit('lb'));
    await tester.tap(find.text('Start empty workout'));
    await settle(tester);
    await tester.tap(find.text('Add exercise'));
    await settle(tester);
    await tester.tap(find.text('Squat'));
    await settle(tester);
    await tester.enterText(_field('lb'), '225');
    await settle(tester);
    final set = (await dbCall(
      tester,
      () => app.db.select(app.db.setEntries).get(),
    )).single;
    expect(set.weightKg, closeTo(102.058, 1e-3));
  });

  testAppWidgets('finish moves the workout to History; discard asks first', (
    app,
  ) async {
    final tester = app.tester;
    await tester.tap(find.text('Start empty workout'));
    await settle(tester);
    await tester.tap(find.text('Discard workout'));
    await settle(tester);
    expect(find.text('Discard workout?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('Finish'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await settle(tester);
    expect(find.text('Finish without completed sets?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Finish').last);
    await settle(tester);
    final active = await dbCall(tester, app.db.workoutDao.getActiveSession);
    expect(active, isNull);
    expect(find.widgetWithText(AppBar, 'History'), findsOneWidget);
  });

  testAppWidgets(
    'in-progress workout shows Resume and blocks starting another',
    (app) async {
      final tester = app.tester;
      await dbCall(
        tester,
        () => app.db.workoutDao.startSession(
          name: 'Legs',
          now: DateTime(2026, 1, 1, 9),
        ),
      );
      await dbCall(
        tester,
        () => app.db.routineDao.saveRoutine(
          name: 'Push',
          items: const [RoutineExerciseDraft(exerciseId: 2)],
          now: DateTime(2026),
        ),
      );
      expect(find.text('Resume workout'), findsOneWidget);
      expect(find.text('Start empty workout'), findsNothing);
      final start = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Start'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(start.onPressed, isNull);
      await tester.tap(find.text('Resume workout'));
      await settle(tester);
      expect(find.text('Legs'), findsOneWidget);
    },
  );

  testAppWidgets(
    'routines: create with the picker, start it, delete with confirm',
    (app) async {
      final tester = app.tester;
      await tester.tap(find.text('New routine'));
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(find.text('Enter a name'), findsOneWidget);

      await tester.enterText(_field('Routine name'), 'Push day');
      await tester.tap(find.text('Add exercise'));
      await settle(tester);
      await tester.tap(find.text('Bench press'));
      await settle(tester);
      expect(find.text('3 sets'), findsOneWidget);
      await tester.tap(find.byTooltip('One set more'));
      await settle(tester);
      expect(find.text('4 sets'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(find.text('Push day'), findsOneWidget);
      expect(find.text('1 exercise'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await settle(tester);
      expect(find.text('Bench press'), findsOneWidget);
      expect(find.byTooltip('Mark set 4 done'), findsOneWidget);
      // Previous values are shown and prefilled from the last time.
      expect(
        find.text('80 × 8'),
        findsOneWidget,
      ); // only set 1 existed last time
      expect(find.widgetWithText(TextField, '80'), findsNWidgets(4));
      await tester.tap(find.text('Discard workout'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
      await settle(tester);

      await tester.tap(find.byTooltip('More options for Push day'));
      await settle(tester);
      await tester.tap(find.text('Delete'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);
      expect(find.text('Push day'), findsNothing);
    },
    setup: (db) => logFinishedSession(
      db,
      exercise: 'Bench press',
      at: DateTime(2026, 1, 1),
      sets: [(80, 8)],
    ),
  );

  testAppWidgets('routine editor warns before discarding unsaved changes', (
    app,
  ) async {
    final tester = app.tester;
    await tester.tap(find.text('New routine'));
    await settle(tester);
    await tester.enterText(_field('Routine name'), 'Draft');
    await settle(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.maybePop();
    await settle(tester);
    expect(find.text('Discard changes?'), findsOneWidget);
  });
}
