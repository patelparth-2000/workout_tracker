import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widget/async_value_view.dart';
import '../../../common/widget/empty_state.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_spacing.dart';
import '../../settings/viewmodel/settings_provider.dart';
import '../viewmodel/history_providers.dart';
import 'widget/session_summary_tile.dart';

/// History tab: finished workouts, newest first, loaded a page at a time.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(historyFeedProvider);
    final unit = ref.watch(weightUnitProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: AsyncValueView<HistoryState>(
        value: feed,
        onRetry: () => ref.invalidate(historyFeedProvider),
        loadingLabel: 'Loading history',
        isEmpty: (s) => s.items.isEmpty,
        empty: EmptyState(
          icon: Icons.history,
          title: 'No workouts yet',
          message: 'Finished workouts appear here.',
          action: FilledButton(
            onPressed: () => context.goNamed(RouteNames.workout),
            child: const Text('Start a workout'),
          ),
        ),
        data: (s) => NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 600) {
              ref.read(historyFeedProvider.notifier).loadMore();
            }
            return false;
          },
          child: ListView.builder(
            itemCount: s.items.length + 1,
            itemBuilder: (context, i) {
              if (i < s.items.length) {
                final item = s.items[i];
                return SessionSummaryTile(
                  summary: item,
                  unit: unit,
                  onTap: () => context.pushNamed(
                    RouteNames.sessionDetail,
                    pathParameters: {'sessionId': '${item.session.id}'},
                  ),
                );
              }
              return _Footer(state: s);
            },
          ),
        ),
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loadingMore) {
      return const Padding(
        padding: AppInsets.screen,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreError != null) {
      return Padding(
        padding: AppInsets.screen,
        child: Column(
          children: [
            Text('Could not load more: ${state.loadMoreError}'),
            TextButton(
              onPressed: () =>
                  ref.read(historyFeedProvider.notifier).loadMore(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.hasMore) {
      return Padding(
        padding: AppInsets.screen,
        child: Center(
          child: OutlinedButton(
            onPressed: () => ref.read(historyFeedProvider.notifier).loadMore(),
            child: const Text('Load more'),
          ),
        ),
      );
    }
    return const SizedBox(height: AppSpacing.xl);
  }
}
