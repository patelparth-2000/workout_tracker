import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../utils/clock.dart';

part 'rest_timer_provider.g.dart';

/// Rest timer state: an END TIMESTAMP, not a countdown. Remaining time is always derived
/// from the clock, so a backgrounded or throttled app cannot drift (ARCHITECTURE §8).
class RestTimerState {
  const RestTimerState({this.endsAt, this.total = Duration.zero});

  const RestTimerState.idle() : endsAt = null, total = Duration.zero;

  final DateTime? endsAt;

  /// Length of the current rest, for the progress bar. Grows when time is added.
  final Duration total;

  bool isRunningAt(DateTime now) => endsAt != null && endsAt!.isAfter(now);

  Duration remainingAt(DateTime now) {
    if (endsAt == null) return Duration.zero;
    final r = endsAt!.difference(now);
    return r.isNegative ? Duration.zero : r;
  }

  /// 0 (just started) .. 1 (done).
  double progressAt(DateTime now) {
    if (endsAt == null || total <= Duration.zero) return 1;
    final p = 1 - remainingAt(now).inMilliseconds / total.inMilliseconds;
    return p.clamp(0, 1).toDouble();
  }
}

/// Step used by the -15 s / +15 s buttons.
const restAdjustStep = Duration(seconds: 15);

@Riverpod(keepAlive: true)
class RestTimer extends _$RestTimer {
  @override
  RestTimerState build() => const RestTimerState.idle();

  DateTime _now() => ref.read(clockProvider)();

  void start(Duration duration) {
    if (duration <= Duration.zero) {
      state = const RestTimerState.idle();
      return;
    }
    state = RestTimerState(endsAt: _now().add(duration), total: duration);
  }

  /// Adds (or with a negative delta removes) time. Going to zero or below stops it.
  void adjust(Duration delta) {
    final endsAt = state.endsAt;
    final now = _now();
    if (endsAt == null || !endsAt.isAfter(now)) return;
    final next = endsAt.add(delta);
    if (!next.isAfter(now)) {
      state = const RestTimerState.idle();
      return;
    }
    final remaining = next.difference(now);
    state = RestTimerState(
      endsAt: next,
      total: remaining > state.total ? remaining : state.total,
    );
  }

  void skip() => state = const RestTimerState.idle();
}
