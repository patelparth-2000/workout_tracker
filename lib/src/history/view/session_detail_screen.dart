import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/widget/async_value_view.dart';
import '../../../common/widget/confirm_dialog.dart';
import '../../../common/widget/empty_state.dart';
import '../../../common/widget/show_toast.dart';
import '../../../data/app_database.dart';
import '../../../data/models.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/clock.dart';
import '../../../utils/units.dart';
import '../../../utils/workout_math.dart';
import '../../active_workout/viewmodel/active_workout_providers.dart';
import '../../progress/viewmodel/progress_providers.dart';
import '../../settings/viewmodel/settings_provider.dart';
import '../viewmodel/history_providers.dart';
import 'widget/edit_set_dialog.dart';

/// One logged workout: summary, every exercise and set; edit sets; delete.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete workout?',
      message: 'This workout and all its sets will be permanently deleted.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(historyControllerProvider.notifier).deleteSession(sessionId);
    showToast(message: 'Workout deleted');
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(sessionDetailProvider(sessionId));
    final unit = ref.watch(weightUnitProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.session.name ?? 'Workout'),
        actions: [
          if (detail.value != null)
            IconButton(
              tooltip: 'Delete workout',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref),
            ),
        ],
      ),
      body: AsyncValueView<SessionDetail?>(
        value: detail,
        onRetry: () => ref.invalidate(sessionDetailProvider(sessionId)),
        isEmpty: (d) => d == null,
        empty: const EmptyState(
          icon: Icons.help_outline,
          title: 'Workout not found',
          message: 'It may have been deleted.',
        ),
        data: (d) => _DetailBody(detail: d!, unit: unit),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail, required this.unit});

  final SessionDetail detail;
  final WeightUnit unit;

  Future<void> _editSet(
    BuildContext context,
    WidgetRef ref,
    SetEntry set,
    int number,
  ) async {
    final result = await showEditSetDialog(
      context,
      set: set,
      number: number,
      unit: unit,
    );
    if (result == null) return;
    final c = ref.read(historyControllerProvider.notifier);
    try {
      if (identical(result, deleteSetResult)) {
        await c.deleteSet(set.id);
        showToast(message: 'Set deleted');
        return;
      }
      await c.updateSet(
        set.id,
        weightKg: result.weightKg,
        reps: result.reps,
        done: result.done,
        completedAtIfDone:
            set.completedAt ??
            detail.session.endedAt ??
            ref.read(clockProvider)(),
      );
    } catch (e) {
      showToast(message: 'Could not save: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final s = detail.session;
    final records =
        ref.watch(recordSetIdsProvider(s.id)).value ?? const <int>{};
    final duration = s.endedAt?.difference(s.startedAt);
    final completed = detail.exercises.fold<int>(
      0,
      (n, e) => n + e.sets.where((x) => x.completedAt != null).length,
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Padding(
          padding: AppInsets.screen,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Chip(
                avatar: const Icon(Icons.event, size: AppSizes.iconSm),
                label: Text(DateFormat.yMMMEd().add_jm().format(s.startedAt)),
              ),
              if (duration != null)
                Chip(
                  avatar: const Icon(
                    Icons.timer_outlined,
                    size: AppSizes.iconSm,
                  ),
                  label: Text(formatDuration(duration)),
                ),
              Chip(
                avatar: const Icon(Icons.check, size: AppSizes.iconSm),
                label: Text('$completed sets done'),
              ),
              Chip(
                avatar: const Icon(Icons.fitness_center, size: AppSizes.iconSm),
                label: Text(formatVolume(detail.volumeKg, unit)),
              ),
            ],
          ),
        ),
        if (s.notes != null)
          Padding(padding: AppInsets.screenH, child: Text(s.notes!)),
        if (detail.exercises.isEmpty)
          const Padding(
            padding: AppInsets.screen,
            child: Text('No exercises were logged in this workout.'),
          ),
        for (final e in detail.exercises)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: AppInsets.screenH,
                    child: Semantics(
                      header: true,
                      child: Text(
                        e.exercise.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  if (e.entry.notes != null)
                    Padding(
                      padding: AppInsets.screenH,
                      child: Text(
                        e.entry.notes!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  for (final (i, set) in e.sets.indexed)
                    ListTile(
                      dense: true,
                      onTap: () => _editSet(context, ref, set, i + 1),
                      leading: Text(
                        '${i + 1}',
                        style: theme.textTheme.titleSmall,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${formatWeight(set.weightKg, unit)} × ${set.reps}',
                            ),
                          ),
                          if (records.contains(set.id)) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.emoji_events,
                              size: AppSizes.iconSm,
                              color: colors.record,
                              semanticLabel: 'Personal record',
                            ),
                            Text(
                              ' PR',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.record,
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: set.completedAt == null
                          ? const Text('Not done (not counted)')
                          : null,
                      trailing: set.completedAt == null
                          ? const Icon(
                              Icons.radio_button_unchecked,
                              semanticLabel: 'Not done',
                            )
                          : Icon(
                              Icons.check_circle,
                              color: colors.success,
                              semanticLabel: 'Done',
                            ),
                    ),
                ],
              ),
            ),
          ),
        const Padding(
          padding: AppInsets.screen,
          child: Text('Tap a set to edit or delete it.'),
        ),
      ],
    );
  }
}
