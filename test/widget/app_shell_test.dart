import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  const tabs = ['Workout', 'History', 'Exercises', 'Progress', 'Settings'];

  for (final mode in ['light', 'dark']) {
    testAppWidgets(
      'startup routes into the shell with 5 labelled tabs ($mode)',
      (app) async {
        final tester = app.tester;
        await dbCall(tester, () => app.db.settingsDao.setThemeMode(mode));

        final nav = find.byType(NavigationBar);
        expect(nav, findsOneWidget);
        for (final t in tabs) {
          expect(
            find.descendant(of: nav, matching: find.text(t)),
            findsOneWidget,
            reason: t,
          );
        }
        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(
          materialApp.themeMode,
          mode == 'dark' ? ThemeMode.dark : ThemeMode.light,
        );
        expect(
          Theme.of(tester.element(nav)).brightness,
          mode == 'dark' ? Brightness.dark : Brightness.light,
        );

        // Every tab can be opened.
        for (final t in tabs.reversed) {
          await tester.tap(find.descendant(of: nav, matching: find.text(t)));
          await settle(tester);
          expect(find.widgetWithText(AppBar, t), findsOneWidget, reason: t);
        }
      },
    );
  }

  testAppWidgets(
    'corrupt v1 data: error with retry, continue still enters the app',
    (app) async {
      final tester = app.tester;
      expect(find.text('Could not import your saved workouts'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      final s = await dbCall(tester, app.db.settingsDao.getSettings);
      expect(s.legacyImportedAt, isNull);

      await tester.tap(find.text('Continue without importing'));
      await settle(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
    },
    legacyJson: '{not json',
  );

  testAppWidgets(
    'valid v1 data is imported on first launch',
    (app) async {
      expect(find.byType(NavigationBar), findsOneWidget);
      final sets = await dbCall(
        app.tester,
        () => app.db.select(app.db.setEntries).get(),
      );
      expect(sets, hasLength(2));
    },
    legacyJson:
        '[{"type":"Squat","weight":"100","reps":"5","sets":"2","icon":"","description":""}]',
  );
}
