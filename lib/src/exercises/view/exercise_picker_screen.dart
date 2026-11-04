import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widget/empty_state.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/exercise_providers.dart';
import 'widget/exercise_sliver_list.dart';

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
      body: ExerciseSliverList(
        scope: _scope,
        exercises: list,
        showArchivedToggle: false,
        onRetry: () => ref.invalidate(exerciseListProvider(_scope)),
        onTap: (e) => context.pop(e.id),
        empty: const EmptyState(
          icon: Icons.search_off,
          title: 'No exercises match',
          message: 'Change the search, or create a new exercise with +.',
        ),
      ),
    );
  }
}
