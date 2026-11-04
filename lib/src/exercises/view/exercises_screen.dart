import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widget/async_value_view.dart';
import '../../../common/widget/empty_state.dart';
import '../../../data/app_database.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_spacing.dart';
import '../viewmodel/exercise_providers.dart';
import 'widget/exercise_filter_bar.dart';
import 'widget/exercise_tile.dart';

const _scope = 'library';

/// Exercises tab: searchable, filterable library.
class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(exerciseListProvider(_scope));
    final filtered = ref.watch(
      exerciseFilterProvider(_scope).select((f) => f.isFiltered),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.exerciseNew),
        icon: const Icon(Icons.add),
        label: const Text('New exercise'),
      ),
      body: Column(
        children: [
          const ExerciseFilterBar(scope: _scope),
          Expanded(
            child: AsyncValueView<List<Exercise>>(
              value: list,
              onRetry: () => ref.invalidate(exerciseListProvider(_scope)),
              isEmpty: (l) => l.isEmpty,
              empty: EmptyState(
                icon: Icons.search_off,
                title: filtered ? 'No exercises match' : 'No exercises yet',
                message: filtered
                    ? 'Try a different search or clear the filters.'
                    : 'Create your first exercise.',
                action: filtered
                    ? OutlinedButton(
                        onPressed: () => ref
                            .read(exerciseFilterProvider(_scope).notifier)
                            .clear(),
                        child: const Text('Clear filters'),
                      )
                    : null,
              ),
              data: (exercises) => ListView.builder(
                padding: AppInsets.listWithFab,
                itemCount: exercises.length,
                itemBuilder: (context, i) => ExerciseTile(
                  exercise: exercises[i],
                  onTap: () => context.pushNamed(
                    RouteNames.exerciseDetail,
                    pathParameters: {'exerciseId': '${exercises[i].id}'},
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
