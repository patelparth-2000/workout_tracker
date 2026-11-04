import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/widget/error_state.dart';
import '../../../../common/widget/loading_state.dart';
import '../../../../data/app_database.dart';
import 'exercise_filter_bar.dart';
import 'exercise_tile.dart';

/// Filter bar + exercise list in ONE scroll view, so at large text sizes the filters
/// scroll away instead of leaving no room for results. Shows all four states.
class ExerciseSliverList extends StatelessWidget {
  const ExerciseSliverList({
    super.key,
    required this.scope,
    required this.exercises,
    required this.onTap,
    required this.empty,
    required this.onRetry,
    this.showArchivedToggle = true,
    this.bottomPadding = 0,
  });

  final String scope;
  final AsyncValue<List<Exercise>> exercises;
  final ValueChanged<Exercise> onTap;
  final Widget empty;
  final VoidCallback onRetry;
  final bool showArchivedToggle;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ExerciseFilterBar(
            scope: scope,
            showArchivedToggle: showArchivedToggle,
          ),
        ),
        switch (exercises) {
          AsyncData(:final value) when value.isEmpty => SliverFillRemaining(
            hasScrollBody: false,
            child: empty,
          ),
          AsyncData(:final value) => SliverPadding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            sliver: SliverList.builder(
              itemCount: value.length,
              itemBuilder: (context, i) => ExerciseTile(
                exercise: value[i],
                onTap: () => onTap(value[i]),
              ),
            ),
          ),
          AsyncError(:final error) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(message: '$error', onRetry: onRetry),
          ),
          _ => const SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingState(label: 'Loading exercises'),
          ),
        },
      ],
    );
  }
}
