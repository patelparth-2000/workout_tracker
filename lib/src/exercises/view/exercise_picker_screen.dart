import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widget/async_value_view.dart';
import '../../../common/widget/empty_state.dart';
import '../../../data/app_database.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/exercise_providers.dart';
import 'widget/exercise_filter_bar.dart';
import 'widget/exercise_tile.dart';

const _scope = 'picker';

/// Pick one exercise. Pops with its id (or null when cancelled).
class ExercisePickerScreen extends ConsumerWidget {
  const ExercisePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(exerciseListProvider(_scope));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose exercise'),
        actions: [
          IconButton(
            tooltip: 'Create a new exercise',
            icon: const Icon(Icons.add),
            onPressed: () => context.pushNamed(RouteNames.exerciseNew),
          ),
        ],
      ),
      body: Column(
        children: [
          const ExerciseFilterBar(scope: _scope, showArchivedToggle: false),
          Expanded(
            child: AsyncValueView<List<Exercise>>(
              value: list,
              onRetry: () => ref.invalidate(exerciseListProvider(_scope)),
              isEmpty: (l) => l.isEmpty,
              empty: const EmptyState(
                icon: Icons.search_off,
                title: 'No exercises match',
                message: 'Change the search, or create a new exercise with +.',
              ),
              data: (exercises) => ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, i) => ExerciseTile(
                  exercise: exercises[i],
                  onTap: () => context.pop(exercises[i].id),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
