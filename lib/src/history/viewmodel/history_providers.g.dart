// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Finished workouts, newest first, keyset-paged (ARCHITECTURE §10). Reloads the
/// already-loaded range whenever sessions or sets change (debounced: typing in a live
/// workout must not re-run the history query per keystroke).

@ProviderFor(HistoryFeed)
final historyFeedProvider = HistoryFeedProvider._();

/// Finished workouts, newest first, keyset-paged (ARCHITECTURE §10). Reloads the
/// already-loaded range whenever sessions or sets change (debounced: typing in a live
/// workout must not re-run the history query per keystroke).
final class HistoryFeedProvider
    extends $AsyncNotifierProvider<HistoryFeed, HistoryState> {
  /// Finished workouts, newest first, keyset-paged (ARCHITECTURE §10). Reloads the
  /// already-loaded range whenever sessions or sets change (debounced: typing in a live
  /// workout must not re-run the history query per keystroke).
  HistoryFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyFeedHash();

  @$internal
  @override
  HistoryFeed create() => HistoryFeed();
}

String _$historyFeedHash() => r'0b091a6e43c4b9be862061cdc9afccec0c66b06c';

/// Finished workouts, newest first, keyset-paged (ARCHITECTURE §10). Reloads the
/// already-loaded range whenever sessions or sets change (debounced: typing in a live
/// workout must not re-run the history query per keystroke).

abstract class _$HistoryFeed extends $AsyncNotifier<HistoryState> {
  FutureOr<HistoryState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HistoryState>, HistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HistoryState>, HistoryState>,
              AsyncValue<HistoryState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// History edits (keepAlive: only ever `ref.read`).

@ProviderFor(HistoryController)
final historyControllerProvider = HistoryControllerProvider._();

/// History edits (keepAlive: only ever `ref.read`).
final class HistoryControllerProvider
    extends $NotifierProvider<HistoryController, void> {
  /// History edits (keepAlive: only ever `ref.read`).
  HistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyControllerHash();

  @$internal
  @override
  HistoryController create() => HistoryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$historyControllerHash() => r'b89909792904af37df5accf44698bd3aec94ec0f';

/// History edits (keepAlive: only ever `ref.read`).

abstract class _$HistoryController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
