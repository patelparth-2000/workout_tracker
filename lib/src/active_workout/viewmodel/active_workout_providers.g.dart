// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_workout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The in-progress session, or null.

@ProviderFor(activeSession)
final activeSessionProvider = ActiveSessionProvider._();

/// The in-progress session, or null.

final class ActiveSessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<WorkoutSession?>,
          WorkoutSession?,
          Stream<WorkoutSession?>
        >
    with $FutureModifier<WorkoutSession?>, $StreamProvider<WorkoutSession?> {
  /// The in-progress session, or null.
  ActiveSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSessionHash();

  @$internal
  @override
  $StreamProviderElement<WorkoutSession?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<WorkoutSession?> create(Ref ref) {
    return activeSession(ref);
  }
}

String _$activeSessionHash() => r'1a74984a90ba7edacb53eaf84ecd8a82efc0281b';

/// A session with its exercises and sets (active or finished).

@ProviderFor(sessionDetail)
final sessionDetailProvider = SessionDetailFamily._();

/// A session with its exercises and sets (active or finished).

final class SessionDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionDetail?>,
          SessionDetail?,
          Stream<SessionDetail?>
        >
    with $FutureModifier<SessionDetail?>, $StreamProvider<SessionDetail?> {
  /// A session with its exercises and sets (active or finished).
  SessionDetailProvider._({
    required SessionDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sessionDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionDetailHash();

  @override
  String toString() {
    return r'sessionDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SessionDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SessionDetail?> create(Ref ref) {
    final argument = this.argument as int;
    return sessionDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionDetailHash() => r'5f43beadf3ffff1a595804c26a450a146b642fc3';

/// A session with its exercises and sets (active or finished).

final class SessionDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SessionDetail?>, int> {
  SessionDetailFamily._()
    : super(
        retry: null,
        name: r'sessionDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A session with its exercises and sets (active or finished).

  SessionDetailProvider call(int sessionId) =>
      SessionDetailProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionDetailProvider';
}

/// exerciseId -> the sets logged the previous time that exercise was done.

@ProviderFor(previousSets)
final previousSetsProvider = PreviousSetsFamily._();

/// exerciseId -> the sets logged the previous time that exercise was done.

final class PreviousSetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, List<SetEntry>>>,
          Map<int, List<SetEntry>>,
          Stream<Map<int, List<SetEntry>>>
        >
    with
        $FutureModifier<Map<int, List<SetEntry>>>,
        $StreamProvider<Map<int, List<SetEntry>>> {
  /// exerciseId -> the sets logged the previous time that exercise was done.
  PreviousSetsProvider._({
    required PreviousSetsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'previousSetsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$previousSetsHash();

  @override
  String toString() {
    return r'previousSetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<int, List<SetEntry>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<int, List<SetEntry>>> create(Ref ref) {
    final argument = this.argument as int;
    return previousSets(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PreviousSetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$previousSetsHash() => r'53c8517733f85b045afb2f85afea9e58c0804282';

/// exerciseId -> the sets logged the previous time that exercise was done.

final class PreviousSetsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<int, List<SetEntry>>>, int> {
  PreviousSetsFamily._()
    : super(
        retry: null,
        name: r'previousSetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// exerciseId -> the sets logged the previous time that exercise was done.

  PreviousSetsProvider call(int sessionId) =>
      PreviousSetsProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'previousSetsProvider';
}

/// Commands for starting and running a workout (keepAlive: only ever `ref.read`).

@ProviderFor(ActiveWorkoutController)
final activeWorkoutControllerProvider = ActiveWorkoutControllerProvider._();

/// Commands for starting and running a workout (keepAlive: only ever `ref.read`).
final class ActiveWorkoutControllerProvider
    extends $NotifierProvider<ActiveWorkoutController, void> {
  /// Commands for starting and running a workout (keepAlive: only ever `ref.read`).
  ActiveWorkoutControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeWorkoutControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeWorkoutControllerHash();

  @$internal
  @override
  ActiveWorkoutController create() => ActiveWorkoutController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$activeWorkoutControllerHash() =>
    r'2ef3eade735f352099ed79545a8b547e9acf6b1f';

/// Commands for starting and running a workout (keepAlive: only ever `ref.read`).

abstract class _$ActiveWorkoutController extends $Notifier<void> {
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
