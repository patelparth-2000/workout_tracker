import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testAppWidgets('settings change unit, rest and theme and persist them', (
    app,
  ) async {
    final tester = app.tester;
    await openTab(tester, 'Settings');
    expect(find.text('Kilograms (kg)'), findsOneWidget);
    expect(find.text('1:30'), findsOneWidget); // default 90 s

    await tester.tap(find.text('Pounds (lb)'));
    await settle(tester);
    await tester.tap(find.text('1:30'));
    await settle(tester);
    await tester.tap(find.text('2:00').last);
    await settle(tester);
    await tester.tap(find.text('Dark'));
    await settle(tester);

    final s = await dbCall(tester, app.db.settingsDao.getSettings);
    expect((s.unit, s.defaultRestSeconds, s.themeMode), ('lb', 120, 'dark'));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testAppWidgets('plate calculator loads each side in the display unit', (
    app,
  ) async {
    final tester = app.tester;
    await openTab(tester, 'Settings');
    await scrollAndTap(tester, find.text('Plate calculator'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Target weight (kg)'),
      '100',
    );
    await settle(tester);
    expect(find.text('25 + 15'), findsOneWidget);
    expect(find.text('Total 100 kg'), findsOneWidget);

    await tester.tap(find.text('15 kg'));
    await settle(tester);
    expect(find.text('25 + 10 + 5'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Target weight (kg)'),
      '101',
    );
    await settle(tester);
    expect(find.text('Closest: 100 kg (1 kg short)'), findsOneWidget);
  });

  testAppWidgets('plate calculator uses lb plates when the unit is lb', (
    app,
  ) async {
    final tester = app.tester;
    await dbCall(tester, () => app.db.settingsDao.setUnit('lb'));
    await openTab(tester, 'Settings');
    await scrollAndTap(tester, find.text('Plate calculator'));
    expect(find.widgetWithText(TextField, '45'), findsOneWidget); // bar
    await tester.enterText(
      find.widgetWithText(TextField, 'Target weight (lb)'),
      '225',
    );
    await settle(tester);
    expect(find.text('45 + 45'), findsOneWidget);
  });
}
