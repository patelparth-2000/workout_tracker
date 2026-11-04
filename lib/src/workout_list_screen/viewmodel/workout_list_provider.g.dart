// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// This provider manages the list of workouts, allowing for adding, updating, deleting, and clearing workouts.

@ProviderFor(WorkoutList)
final workoutListProvider = WorkoutListProvider._();

/// This provider manages the list of workouts, allowing for adding, updating, deleting, and clearing workouts.
final class WorkoutListProvider
    extends $NotifierProvider<WorkoutList, List<WorkoutModel>> {
  /// This provider manages the list of workouts, allowing for adding, updating, deleting, and clearing workouts.
  WorkoutListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutListHash();

  @$internal
  @override
  WorkoutList create() => WorkoutList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<WorkoutModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<WorkoutModel>>(value),
    );
  }
}

String _$workoutListHash() => r'5d6e5278a567258af87c58aad081ed06208ea9ae';

/// This provider manages the list of workouts, allowing for adding, updating, deleting, and clearing workouts.

abstract class _$WorkoutList extends $Notifier<List<WorkoutModel>> {
  List<WorkoutModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<WorkoutModel>, List<WorkoutModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<WorkoutModel>, List<WorkoutModel>>,
              List<WorkoutModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
