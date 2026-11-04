import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widget/async_value_view.dart';
import '../../../common/widget/confirm_dialog.dart';
import '../../../common/widget/empty_state.dart';
import '../../../common/widget/error_state.dart';
import '../../../common/widget/loading_state.dart';
import '../../../common/widget/show_toast.dart';
import '../../../data/app_database.dart';
import '../../../data/models.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_spacing.dart';
import '../../progress/viewmodel/progress_providers.dart';
import '../../settings/viewmodel/settings_provider.dart';
import '../viewmodel/active_workout_providers.dart';
import 'widget/elapsed_text.dart';
import 'widget/rest_timer_bar.dart';
import 'widget/session_exercise_card.dart';

/// The live workout. Everything is written to the database as it happens, so the
/// workout survives the app being killed.
class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeSessionProvider);
    return switch (active) {
      AsyncData(:final value) when value != null => _ActiveSession(
        session: value,
      ),
      AsyncData() => Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: EmptyState(
          icon: Icons.fitness_center,
          title: 'No workout in progress',
          action: FilledButton(
            onPressed: () => context.goNamed(RouteNames.workout),
            child: const Text('Back to Workout'),
          ),
        ),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(activeSessionProvider),
        ),
      ),
      _ => const Scaffold(body: LoadingState()),
    };
  }
}

class _ActiveSession extends ConsumerWidget {
  const _ActiveSession({required this.session});

  final WorkoutSession session;

  ActiveWorkoutController _c(WidgetRef ref) =>
      ref.read(activeWorkoutControllerProvider.notifier);

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      showToast(message: 'Could not save: $e');
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: session.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename workout'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await _guard(() => _c(ref).rename(session.id, name));
    }
  }

  Future<void> _finish(
    BuildContext context,
    WidgetRef ref,
    SessionDetail? d,
  ) async {
    final completed =
        d?.exercises.fold<int>(
          0,
          (n, e) => n + e.sets.where((s) => s.completedAt != null).length,
        ) ??
        0;
    if (completed == 0) {
      final ok = await showConfirmDialog(
        context,
        title: 'Finish without completed sets?',
        message:
            'No set is ticked as done. Only completed sets count toward '
            'volume and records.',
        confirmLabel: 'Finish',
      );
      if (!ok) return;
    }
    await _guard(() => _c(ref).finish(session.id));
    showToast(message: 'Workout saved');
    if (context.mounted) context.goNamed(RouteNames.history);
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Discard workout?',
      message: 'Everything logged in this workout will be deleted.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!ok) return;
    await _guard(() => _c(ref).discard(session.id));
    showToast(message: 'Workout discarded');
    if (context.mounted) context.goNamed(RouteNames.workout);
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final id = await context.pushNamed<int>(RouteNames.exercisePicker);
    if (id != null) await _guard(() => _c(ref).addExercise(session.id, id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(sessionDetailProvider(session.id));
    final previous =
        ref.watch(previousSetsProvider(session.id)).value ?? const {};
    final unit = ref.watch(weightUnitProvider);
    final records =
        ref.watch(recordSetIdsProvider(session.id)).value ?? const {};
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.name, overflow: TextOverflow.ellipsis),
            ElapsedText(
              since: session.startedAt,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Rename workout',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _rename(context, ref),
          ),
          FilledButton(
            onPressed: () => _finish(context, ref, detail.value),
            child: const Text('Finish'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      bottomNavigationBar: const RestTimerBar(),
      body: AsyncValueView<SessionDetail?>(
        value: detail,
        onRetry: () => ref.invalidate(sessionDetailProvider(session.id)),
        data: (d) {
          final exercises = d?.exercises ?? const <SessionExerciseDetail>[];
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
            children: [
              if (exercises.isEmpty)
                const Padding(
                  padding: AppInsets.screen,
                  child: Text('Add your first exercise to start logging sets.'),
                ),
              for (final (i, e) in exercises.indexed)
                SessionExerciseCard(
                  key: ValueKey(e.entry.id),
                  detail: e,
                  unit: unit,
                  previous: previous[e.exercise.id] ?? const [],
                  recordSetIds: records,
                  isFirst: i == 0,
                  isLast: i == exercises.length - 1,
                  onSetChanged: (set, kg, reps) =>
                      _guard(() => _c(ref).updateSet(set.id, kg, reps)),
                  onToggleComplete: (set) => _guard(
                    () => _c(
                      ref,
                    ).toggleComplete(set, restSeconds: e.entry.restSeconds),
                  ),
                  onDeleteSet: (set) => _guard(() => _c(ref).removeSet(set.id)),
                  onAddSet: () => _guard(() => _c(ref).addSet(e.entry.id)),
                  onMoveUp: () =>
                      _guard(() => _c(ref).moveExercise(session.id, i, i - 1)),
                  onMoveDown: () =>
                      _guard(() => _c(ref).moveExercise(session.id, i, i + 1)),
                  onRemove: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Remove ${e.exercise.name}?',
                      message: 'Its sets in this workout will be deleted.',
                      confirmLabel: 'Remove',
                      destructive: true,
                    );
                    if (ok) {
                      await _guard(() => _c(ref).removeExercise(e.entry.id));
                    }
                  },
                ),
              Padding(
                padding: AppInsets.screen,
                child: FilledButton.tonalIcon(
                  onPressed: () => _addExercise(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add exercise'),
                ),
              ),
              Padding(
                padding: AppInsets.screenH,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => _discard(context, ref),
                  child: const Text('Discard workout'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
