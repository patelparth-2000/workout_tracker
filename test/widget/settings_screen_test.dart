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
}
