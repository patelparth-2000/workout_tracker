// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(routines)
final routinesProvider = RoutinesProvider._();

final class RoutinesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RoutineSummary>>,
          List<RoutineSummary>,
          Stream<List<RoutineSummary>>
        >
    with
        $FutureModifier<List<RoutineSummary>>,
        $StreamProvider<List<RoutineSummary>> {
  RoutinesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routinesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routinesHash();

  @$internal
  @override
  $StreamProviderElement<List<RoutineSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<RoutineSummary>> create(Ref ref) {
    return routines(ref);
  }
}

String _$routinesHash() => r'14921dc15a95f48c1b265bd36cfc967b6dd8b89b';

/// Routine writes (keepAlive: only ever `ref.read`).

@ProviderFor(RoutineController)
final routineControllerProvider = RoutineControllerProvider._();

/// Routine writes (keepAlive: only ever `ref.read`).
final class RoutineControllerProvider
    extends $NotifierProvider<RoutineController, void> {
  /// Routine writes (keepAlive: only ever `ref.read`).
  RoutineControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routineControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routineControllerHash();

  @$internal
  @override
  RoutineController create() => RoutineController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$routineControllerHash() => r'0aa3204cada3d2a339cddfeff7d0b0cba29cd6d8';

/// Routine writes (keepAlive: only ever `ref.read`).

abstract class _$RoutineController extends $Notifier<void> {
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
