import 'dart:async';
import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_provider.dart';
import '../../../data/models.dart';

part 'history_providers.g.dart';

class HistoryState {
  const HistoryState({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<SessionSummary> items;
  final bool hasMore;
  final bool loadingMore;
  final Object? loadMoreError;

  HistoryState copyWith({
    List<SessionSummary>? items,
    bool? hasMore,
    bool? loadingMore,
    Object? Function()? loadMoreError,
  }) => HistoryState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: loadMoreError != null ? loadMoreError() : this.loadMoreError,
  );
}

/// Finished workouts, newest first, keyset-paged (ARCHITECTURE §10). Reloads the
/// already-loaded range whenever sessions or sets change (debounced: typing in a live
/// workout must not re-run the history query per keystroke).
@riverpod
class HistoryFeed extends _$HistoryFeed {
  static const pageSize = 30;
  static const _debounce = Duration(milliseconds: 300);

  Timer? _refreshTimer;

  @override
  Future<HistoryState> build() async {
    final dao = ref.watch(appDatabaseProvider).workoutDao;
    final sub = dao.watchHistoryChanges().listen((_) {
      _refreshTimer?.cancel();
      _refreshTimer = Timer(_debounce, _refresh);
    });
    ref.onDispose(() {
      sub.cancel();
      _refreshTimer?.cancel();
    });
    final page = await dao.historyPage(limit: pageSize);
    return HistoryState(items: page, hasMore: page.length == pageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreError: () => null),
    );
    try {
      final last = current.items.last.session;
      final page = await ref
          .read(appDatabaseProvider)
          .workoutDao
          .historyPage(
            before: HistoryCursor(startedAt: last.startedAt, id: last.id),
            limit: pageSize,
          );
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page],
          hasMore: page.length == pageSize,
          loadingMore: false,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreError: () => e),
      );
    }
  }

  Future<void> _refresh() async {
    if (!ref.mounted) return;
    final loaded = state.value?.items.length ?? 0;
    final count = math.max(pageSize, loaded);
    try {
      final items = await ref
          .read(appDatabaseProvider)
          .workoutDao
          .historyPage(limit: count);
      if (!ref.mounted) return;
      state = AsyncData(
        HistoryState(items: items, hasMore: items.length == count),
      );
    } catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
  }
}

/// History edits (keepAlive: only ever `ref.read`).
@Riverpod(keepAlive: true)
class HistoryController extends _$HistoryController {
  @override
  void build() {}

  Future<void> updateSet(
    int setId, {
    required double weightKg,
    required int reps,
    required bool done,
    required DateTime completedAtIfDone,
  }) async {
    final dao = ref.read(appDatabaseProvider).workoutDao;
    await dao.updateSet(setId, weightKg: weightKg, reps: reps);
    await dao.setCompleted(setId, completed: done, now: completedAtIfDone);
  }

  Future<void> deleteSet(int setId) =>
      ref.read(appDatabaseProvider).workoutDao.removeSet(setId);

  Future<void> deleteSession(int id) =>
      ref.read(appDatabaseProvider).workoutDao.deleteSession(id);

  Future<void> rename(int id, String name) =>
      ref.read(appDatabaseProvider).workoutDao.renameSession(id, name);
}
