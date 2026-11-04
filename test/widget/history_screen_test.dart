import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/app_database.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

Future<void> _sessions(AppDatabase db, int n) async {
  final t0 = DateTime(2026, 1, 1, 8);
  for (var i = 0; i < n; i++) {
    final at = t0.add(Duration(days: i));
    final id = await logFinishedSession(
      db,
      exercise: 'Squat',
      at: at,
      sets: [(100, 5)],
    );
    await (db.update(db.workoutSessions)..where((s) => s.id.equals(id))).write(
      WorkoutSessionsCompanion(name: Value('Session $i')),
    );
  }
}

void main() {
  testAppWidgets('empty history explains itself', (app) async {
    await openTab(app.tester, 'History');
    expect(find.text('No workouts yet'), findsOneWidget);
    expect(find.text('Start a workout'), findsOneWidget);
  });

  testAppWidgets('finishing a workout shows it in History', (app) async {
    final tester = app.tester;
    await tester.tap(find.text('Start empty workout'));
    await settle(tester);
    await tester.tap(find.text('Add exercise'));
    await settle(tester);
    await tester.tap(find.text('Squat'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'kg'), '100');
    await tester.enterText(find.widgetWithText(TextField, 'Reps'), '5');
    await settle(tester);
    await tester.tap(find.byTooltip('Mark set 1 done'));
    await settle(tester);
    await tester.tap(find.text('Finish'));
    await settle(tester);

    expect(find.widgetWithText(AppBar, 'History'), findsOneWidget);
    expect(find.text('Workout'), findsWidgets);
    expect(find.textContaining('1 set · 500 kg'), findsOneWidget);
  });

  testAppWidgets(
    'loaded list pages past the first 30 and opens the detail',
    (app) async {
      final tester = app.tester;
      await openTab(tester, 'History');
      expect(find.text('Session 30'), findsOneWidget); // newest first
      await tester.scrollUntilVisible(
        find.text('Session 0'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await settle(tester);
      expect(find.text('Session 0'), findsOneWidget);

      await tester.tap(find.text('Session 0'));
      await settle(tester);
      expect(find.text('100 kg × 5'), findsOneWidget);
      expect(find.text('1 sets done'), findsOneWidget);
    },
    setup: (db) => _sessions(db, 31),
  );

  testAppWidgets('edit a set in history, then delete the workout', (app) async {
    final tester = app.tester;
    await openTab(tester, 'History');
    await tester.tap(find.text('Session 0'));
    await settle(tester);

    await tester.tap(find.text('100 kg × 5'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Weight (kg)'),
      'abc',
    );
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Enter a valid weight'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Weight (kg)'),
      '110',
    );
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('110 kg × 5'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete workout'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);
    expect(find.text('No workouts yet'), findsOneWidget);
  }, setup: (db) => _sessions(db, 1));
}
