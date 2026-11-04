import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../utils/app_spacing.dart';
import '../../../../utils/clock.dart';
import '../../../../utils/workout_math.dart';
import '../../viewmodel/rest_timer_provider.dart';

/// Rest countdown with -15 s / +15 s / skip. Hidden when no rest is running.
/// The 1-second ticker only repaints; time comes from the clock (no drift), and the
/// ticker is cancelled whenever no rest is running and on dispose.
class RestTimerBar extends ConsumerStatefulWidget {
  const RestTimerBar({super.key});

  @override
  ConsumerState<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends ConsumerState<RestTimerBar> {
  Timer? _ticker;

  void _sync(RestTimerState state) {
    final running = state.isRunningAt(ref.read(clockProvider)());
    if (running && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else if (!running) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _tick() {
    if (!mounted) return;
    final state = ref.read(restTimerProvider);
    if (!state.isRunningAt(ref.read(clockProvider)())) {
      HapticFeedback.mediumImpact();
      ref.read(restTimerProvider.notifier).skip();
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restTimerProvider);
    final now = ref.watch(clockProvider)();
    _sync(state);
    if (!state.isRunningAt(now)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final notifier = ref.read(restTimerProvider.notifier);
    // A countdown rounds UP: 89.4 s left reads 1:30, and 0:00 only when it is over.
    final left = state.remainingAt(now);
    final remaining = formatClock(
      Duration(seconds: (left.inMilliseconds / 1000).ceil()),
    );
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Rest timer, $remaining remaining',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rest $remaining',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      LinearProgressIndicator(value: state.progressAt(now)),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove 15 seconds',
                onPressed: () => notifier.adjust(-restAdjustStep),
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                tooltip: 'Add 15 seconds',
                onPressed: () => notifier.adjust(restAdjustStep),
                icon: const Icon(Icons.add),
              ),
              TextButton(onPressed: notifier.skip, child: const Text('Skip')),
            ],
          ),
        ),
      ),
    );
  }
}
