import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testAppWidgets('library lists, searches, filters and shows the empty state', (
    app,
  ) async {
    final tester = app.tester;
    await openTab(tester, 'Exercises');
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search exercises'),
      'BENCH',
    );
    await settle(tester);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Squat'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search exercises'),
      'zzz',
    );
    await settle(tester);
    expect(find.text('No exercises match'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await settle(tester);
    expect(find.text('Squat'), findsOneWidget);

    await tester.tap(find.text('Equipment: Any'));
    await settle(tester);
    await tester.tap(find.text('Dumbbell').last);
    await settle(tester);
    expect(find.text('Bicep curl'), findsOneWidget);
    expect(find.text('Squat'), findsNothing);
  });

  testAppWidgets('create a custom exercise; duplicates are rejected inline', (
    app,
  ) async {
    final tester = app.tester;
    await openTab(tester, 'Exercises');
    await tester.tap(find.text('New exercise'));
    await settle(tester);

    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Enter a name'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'squat');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(
      find.text('An exercise named "squat" already exists'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Sissy squat',
    );
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Sissy squat'), findsOneWidget);
    expect(find.textContaining('Custom'), findsOneWidget);
  });

  testAppWidgets('detail shows info; archive hides it from the library', (
    app,
  ) async {
    final tester = app.tester;
    await openTab(tester, 'Exercises');
    await tester.tap(find.text('Bench press'));
    await settle(tester);
    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('No description yet.'), findsOneWidget);
    // Built-ins cannot be edited, only archived.
    expect(find.byTooltip('Edit exercise'), findsNothing);

    await tester.tap(find.byTooltip('Archive exercise'));
    await settle(tester);
    expect(find.byTooltip('Restore exercise'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    expect(find.text('Bench press'), findsNothing);
    await tester.tap(find.text('Show archived'));
    await settle(tester);
    expect(find.text('Bench press'), findsOneWidget);
  });

  testAppWidgets('custom exercise can be edited', (app) async {
    final tester = app.tester;
    await dbCall(
      tester,
      () => app.db.exerciseDao.createCustom(
        name: 'Zercher',
        muscleGroup: 'Quads',
        equipment: 'Barbell',
      ),
    );
    await openTab(tester, 'Exercises');
    await tester.tap(find.text('Zercher'));
    await settle(tester);
    await tester.tap(find.byTooltip('Edit exercise'));
    await settle(tester);
    expect(find.widgetWithText(TextFormField, 'Zercher'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Zercher squat',
    );
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Zercher squat'), findsWidgets);
  });
}
