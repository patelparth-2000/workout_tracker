import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/src/active_workout/viewmodel/rest_timer_provider.dart';
import 'package:workout_tracker/utils/clock.dart';

void main() {
  late DateTime now;
  late ProviderContainer c;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    c = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
  });
  tearDown(() => c.dispose());

  RestTimer timer() => c.read(restTimerProvider.notifier);
  RestTimerState state() => c.read(restTimerProvider);

  test('starts idle', () {
    expect(state().isRunningAt(now), isFalse);
    expect(state().remainingAt(now), Duration.zero);
  });

  test('start sets an end timestamp; remaining follows the clock', () {
    timer().start(const Duration(seconds: 90));
    expect(state().endsAt, now.add(const Duration(seconds: 90)));
    now = now.add(const Duration(seconds: 30));
    expect(state().remainingAt(now), const Duration(seconds: 60));
    expect(state().progressAt(now), closeTo(1 / 3, 1e-9));
  });

  test('a long background gap is accounted for (no drift)', () {
    timer().start(const Duration(seconds: 120));
    now = now.add(const Duration(seconds: 119, milliseconds: 500));
    expect(state().remainingAt(now), const Duration(milliseconds: 500));
    now = now.add(const Duration(minutes: 10));
    expect(state().isRunningAt(now), isFalse);
    expect(state().remainingAt(now), Duration.zero);
    expect(state().progressAt(now), 1);
  });

  test('+15 / -15 adjust; going below zero stops; adding grows total', () {
    timer().start(const Duration(seconds: 20));
    timer().adjust(restAdjustStep);
    expect(state().remainingAt(now), const Duration(seconds: 35));
    expect(state().total, const Duration(seconds: 35));
    timer().adjust(-restAdjustStep);
    expect(state().remainingAt(now), const Duration(seconds: 20));
    expect(state().total, const Duration(seconds: 35));
    timer().adjust(-restAdjustStep);
    timer().adjust(-restAdjustStep);
    expect(state().isRunningAt(now), isFalse);
  });

  test(
    'adjusting an expired timer does nothing; skip and zero start go idle',
    () {
      timer().start(const Duration(seconds: 10));
      now = now.add(const Duration(seconds: 11));
      timer().adjust(restAdjustStep);
      expect(state().isRunningAt(now), isFalse);

      timer().start(const Duration(seconds: 10));
      timer().skip();
      expect(state().endsAt, isNull);

      timer().start(Duration.zero);
      expect(state().endsAt, isNull);
    },
  );

  test(
    'removing more time than is left resets to idle (no stale end time)',
    () {
      timer().start(const Duration(seconds: 10));
      timer().adjust(-restAdjustStep);
      expect(state().endsAt, isNull);
      expect(state().total, Duration.zero);
    },
  );
}
