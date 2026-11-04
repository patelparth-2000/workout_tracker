import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/widget/confirm_dialog.dart';
import '../../../common/widget/error_state.dart';
import '../../../common/widget/loading_state.dart';
import '../../../common/widget/section_header.dart';
import '../../../common/widget/show_toast.dart';
import '../../../data/app_database.dart';
import '../../../data/models.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_spacing.dart';
import '../../active_workout/viewmodel/active_workout_providers.dart';
import '../viewmodel/routine_providers.dart';
import 'widget/routine_card.dart';

/// Workout tab: resume / start empty / start from a routine; manage routines.
class WorkoutHomeScreen extends ConsumerWidget {
  const WorkoutHomeScreen({super.key});

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    Future<int> Function() start,
  ) async {
    try {
      await start();
      if (context.mounted) context.pushNamed(RouteNames.activeWorkout);
    } catch (e) {
      showToast(message: 'Could not start the workout: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeSessionProvider);
    final routines = ref.watch(routinesProvider);
    final controller = ref.read(activeWorkoutControllerProvider.notifier);
    final hasActive = active.value != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: AppInsets.screen,
            child: switch (active) {
              AsyncData(:final value) when value != null => _ResumeCard(
                session: value,
              ),
              AsyncError(:final error) => Text(
                'Could not check for a workout in progress: $error',
              ),
              _ => FilledButton.icon(
                onPressed: active.isLoading
                    ? null
                    : () => _start(context, ref, controller.startEmpty),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start empty workout'),
              ),
            },
          ),
          SectionHeader(
            title: 'Routines',
            trailing: TextButton.icon(
              onPressed: () => context.pushNamed(RouteNames.routineNew),
              icon: const Icon(Icons.add),
              label: const Text('New routine'),
            ),
          ),
          switch (routines) {
            AsyncData(:final value) when value.isEmpty => const Padding(
              padding: AppInsets.screen,
              child: Text(
                'No routines yet. Save the exercises you repeat as a routine '
                'to start workouts with one tap.',
              ),
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final r in value)
                  RoutineCard(
                    summary: r,
                    startEnabled: !hasActive,
                    onStart: () => _start(
                      context,
                      ref,
                      () => controller.startFromRoutine(r.routine),
                    ),
                    onEdit: () => context.pushNamed(
                      RouteNames.routineEdit,
                      pathParameters: {'routineId': '${r.routine.id}'},
                    ),
                    onDelete: () => _delete(context, ref, r),
                  ),
                if (hasActive)
                  const Padding(
                    padding: AppInsets.screen,
                    child: Text(
                      'Finish or discard the workout in progress to start another.',
                    ),
                  ),
              ],
            ),
            AsyncError(:final error) => ErrorState(
              message: '$error',
              onRetry: () => ref.invalidate(routinesProvider),
            ),
            _ => const Padding(
              padding: AppInsets.screen,
              child: LoadingState(label: 'Loading routines'),
            ),
          },
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RoutineSummary r,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete routine?',
      message:
          '"${r.routine.name}" will be deleted. Workouts already logged from it are kept.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(routineControllerProvider.notifier).delete(r.routine.id);
    showToast(message: 'Routine deleted');
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Workout in progress',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${session.name} · started ${DateFormat.jm().format(session.startedAt)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.pushNamed(RouteNames.activeWorkout),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume workout'),
            ),
          ],
        ),
      ),
    );
  }
}
