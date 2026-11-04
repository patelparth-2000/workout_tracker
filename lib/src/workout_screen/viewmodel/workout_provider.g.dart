// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// This provider manages the state of the workout screen, including text editing controllers for weight, reps, and sets.

@ProviderFor(WorkoutProvider)
final workoutProviderProvider = WorkoutProviderProvider._();

/// This provider manages the state of the workout screen, including text editing controllers for weight, reps, and sets.
final class WorkoutProviderProvider
    extends $NotifierProvider<WorkoutProvider, int?> {
  /// This provider manages the state of the workout screen, including text editing controllers for weight, reps, and sets.
  WorkoutProviderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutProviderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutProviderHash();

  @$internal
  @override
  WorkoutProvider create() => WorkoutProvider();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$workoutProviderHash() => r'b929d5ef08fc6c91bfc6ff80a950a3848ea7777b';

/// This provider manages the state of the workout screen, including text editing controllers for weight, reps, and sets.

abstract class _$WorkoutProvider extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
