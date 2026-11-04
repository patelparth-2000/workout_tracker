import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/app.dart';
import 'package:workout_tracker/data/app_database.dart';
import 'package:workout_tracker/data/database_provider.dart';
import 'package:workout_tracker/data/legacy/legacy_store.dart';
import 'package:workout_tracker/utils/clock.dart';

import 'test_database.dart';

/// Handle to the app under test.
class AppHarness {
  AppHarness(this.tester, this.db);
  final WidgetTester tester;
  final AppDatabase db;
}

/// testWidgets that pumps the whole app on an in-memory database and tears it down
/// INSIDE the test body (flutter_test checks for pending timers before tearDowns run).
void testAppWidgets(
  String description,
  Future<void> Function(AppHarness app) body, {
  String? legacyJson,
  DateTime Function()? clock,
  List<ExercisesCompanion>? seed,
  Size? surfaceSize,
  double textScale = 1,
  Future<void> Function(AppDatabase db)? setup,
  List<Override> overrides = const [],
}) {
  testWidgets(description, (tester) async {
    if (surfaceSize != null) {
      await tester.binding.setSurfaceSize(surfaceSize);
    }
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = testDatabase(seed: seed);
    if (setup != null) await tester.runAsync(() => setup(db));
    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          legacyReaderProvider.overrideWithValue(() async => legacyJson),
          if (clock != null) clockProvider.overrideWithValue(clock),
          ...overrides,
        ],
        child: const App(),
      ),
    );
    await settle(tester);
    try {
      await body(AppHarness(tester, db));
    } finally {
      // Unmount so drift streams are cancelled, let their (fake) timers fire, then close
      // the database on real time (its close waits on a real timer).
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
      if (surfaceSize != null) await tester.binding.setSurfaceSize(null);
    }
  });
}

/// pumpAndSettle that also lets real async database work run between frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pumpAndSettle();
  }
  // Let short debounce timers (e.g. the history refresh) fire, then settle again.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 5)),
  );
  await tester.pumpAndSettle();
}

/// Runs ONE database call on real time, then settles the UI.
///
/// Multi-step work here can deadlock: the UI's drift stream queries run in the fake-async
/// zone and hold the database lock until that zone is pumped. Seed multi-step data with
/// `testAppWidgets(setup: ...)`, which runs before the UI subscribes.
Future<T> dbCall<T>(WidgetTester tester, Future<T> Function() call) async {
  final result = await tester.runAsync(call);
  await settle(tester);
  return result as T;
}

/// Opens a bottom-navigation tab by its label.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await settle(tester);
}

/// Scrolls the main vertical scroll view until [finder] is visible, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  final page = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  if (finder.evaluate().isEmpty || !tester.any(finder.hitTestable())) {
    await tester.scrollUntilVisible(finder, 150, scrollable: page.first);
    await settle(tester);
  }
  await tester.tap(finder);
  await settle(tester);
}
