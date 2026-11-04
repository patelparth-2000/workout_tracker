import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widget/async_value_view.dart';
import '../../../common/widget/empty_state.dart';
import '../../../common/widget/section_header.dart';
import '../../../common/widget/show_toast.dart';
import '../../../data/app_database.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_spacing.dart';
import '../../progress/view/widget/exercise_bests_grid.dart';
import '../../progress/viewmodel/progress_providers.dart';
import '../../settings/viewmodel/settings_provider.dart';
import '../viewmodel/exercise_providers.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final int exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.watch(exerciseByIdProvider(exerciseId));
    final e = exercise.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(e?.name ?? 'Exercise'),
        actions: [
          if (e != null && e.isCustom)
            IconButton(
              tooltip: 'Edit exercise',
              icon: const Icon(Icons.edit),
              onPressed: () => context.pushNamed(
                RouteNames.exerciseEdit,
                pathParameters: {'exerciseId': '$exerciseId'},
              ),
            ),
          if (e != null)
            IconButton(
              tooltip: e.archived ? 'Restore exercise' : 'Archive exercise',
              icon: Icon(e.archived ? Icons.unarchive : Icons.archive_outlined),
              onPressed: () async {
                await ref
                    .read(exerciseControllerProvider.notifier)
                    .setArchived(e.id, !e.archived);
                showToast(
                  message: e.archived
                      ? '${e.name} restored'
                      : '${e.name} archived. Its history is kept.',
                );
              },
            ),
        ],
      ),
      body: AsyncValueView<Exercise?>(
        value: exercise,
        onRetry: () => ref.invalidate(exerciseByIdProvider(exerciseId)),
        isEmpty: (e) => e == null,
        empty: const EmptyState(
          icon: Icons.help_outline,
          title: 'Exercise not found',
        ),
        data: (e) => _Details(exercise: e!),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bests = ref.watch(exerciseBestsProvider(exercise.id)).value;
    final unit = ref.watch(weightUnitProvider);
    final gif = exercise.gifAsset;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (gif != null)
          Padding(
            padding: AppInsets.screen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset(
                gif,
                height: AppSizes.gifHeight,
                fit: BoxFit.contain,
                semanticLabel: 'Animated demonstration of ${exercise.name}',
                errorBuilder: (context, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        Padding(
          padding: AppInsets.screenH,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Chip(label: Text(exercise.muscleGroup)),
              Chip(label: Text(exercise.equipment)),
              if (exercise.isCustom) const Chip(label: Text('Custom')),
              if (exercise.archived) const Chip(label: Text('Archived')),
            ],
          ),
        ),
        const SectionHeader(title: 'How to'),
        Padding(
          padding: AppInsets.screenH,
          child: Text(
            exercise.description.isEmpty
                ? 'No description yet.'
                : exercise.description,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        if (bests != null && bests.sessionCount > 0) ...[
          const SectionHeader(title: 'Your records'),
          Padding(
            padding: AppInsets.screenH,
            child: ExerciseBestsGrid(bests: bests, unit: unit),
          ),
        ],
      ],
    );
  }
}
