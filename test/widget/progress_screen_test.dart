import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/app_database.dart';
import 'package:workout_tracker/src/progress/view/widget/progress_chart.dart';

import '../helpers/pump_app.dart';
import '../helpers/test_database.dart';

Future<void> _history(AppDatabase db) async {
  final now = DateTime.now();
  await logFinishedSession(
    db,
    exercise: 'Squat',
    at: now.subtract(const Duration(days: 20)),
    sets: [(100, 5)],
  );
  await logFinishedSession(
    db,
    exercise: 'Squat',
    at: now.subtract(const Duration(days: 10)),
    sets: [(110, 5), (60, 10)],
  );
}

void main() {
  testAppWidgets('progress is empty before any completed workout', (app) async {
    await openTab(app.tester, 'Progress');
    expect(find.text('No progress yet'), findsOneWidget);
  });

  testAppWidgets(
    'loaded: records, chart with a text summary, unit switch, metric toggle',
    (app) async {
      final tester = app.tester;
      await openTab(tester, 'Progress');
      expect(find.text('Squat (2)'), findsOneWidget);
      expect(find.text('110 kg'), findsWidgets); // best weight
      expect(find.text('128.3 kg'), findsWidgets); // e1RM 110 x 5
      expect(find.text('1,150 kg'), findsWidgets); // best session volume
      expect(find.byType(ProgressChart), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Estimated 1-rep max chart, 2 workouts'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Volume'));
      await settle(tester);
      expect(
        find.bySemanticsLabel(RegExp(r'^Session volume chart')),
        findsOneWidget,
      );

      await dbCall(tester, () => app.db.settingsDao.setUnit('lb'));
      expect(find.text('242.5 lb'), findsWidgets); // 110 kg
      expect(find.text('110 kg'), findsNothing);
    },
    setup: _history,
  );

  testAppWidgets('a record set shows a PR badge in history', (app) async {
    final tester = app.tester;
    await openTab(tester, 'History');
    await tester.tap(find.text('W').first); // newest: the 110 kg session
    await settle(tester);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    expect(find.text(' PR'), findsOneWidget);
  }, setup: _history);

  testAppWidgets(
    'completing a set that beats your best shows the PR badge live',
    (app) async {
      final tester = app.tester;
      await tester.tap(find.text('Start empty workout'));
      await settle(tester);
      await tester.tap(find.text('Add exercise'));
      await settle(tester);
      await tester.tap(find.text('Squat'));
      await settle(tester);
      // Prefilled from last time (110 x 5) — a tie, so no badge.
      await tester.tap(find.byTooltip('Mark set 1 done'));
      await settle(tester);
      expect(find.byTooltip('Personal record'), findsNothing);
      await tester.tap(find.byTooltip('Mark set 1 not done'));
      await settle(tester);
      await tester.enterText(find.widgetWithText(TextField, 'kg').first, '115');
      await settle(tester);
      await tester.tap(find.byTooltip('Mark set 1 done'));
      await settle(tester);
      expect(find.byTooltip('Personal record'), findsOneWidget);
    },
    setup: _history,
  );

  testAppWidgets('the chart plots in the display unit', (app) async {
    final tester = app.tester;
    await dbCall(tester, () => app.db.settingsDao.setUnit('lb'));
    await openTab(tester, 'Progress');
    // Best e1RM 128.33 kg = 282.9 lb.
    expect(find.bySemanticsLabel(RegExp(r'highest 282\.9 lb')), findsOneWidget);
  }, setup: _history);
}
