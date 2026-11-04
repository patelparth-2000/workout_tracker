// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Filter state per screen ("library" tab, "picker").

@ProviderFor(ExerciseFilter)
final exerciseFilterProvider = ExerciseFilterFamily._();

/// Filter state per screen ("library" tab, "picker").
final class ExerciseFilterProvider
    extends $NotifierProvider<ExerciseFilter, ExerciseFilterState> {
  /// Filter state per screen ("library" tab, "picker").
  ExerciseFilterProvider._({
    required ExerciseFilterFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseFilterProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseFilterHash();

  @override
  String toString() {
    return r'exerciseFilterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ExerciseFilter create() => ExerciseFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExerciseFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExerciseFilterState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseFilterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseFilterHash() => r'4f38bd27627f49744a90e201a57a193a24628aa6';

/// Filter state per screen ("library" tab, "picker").

final class ExerciseFilterFamily extends $Family
    with
        $ClassFamilyOverride<
          ExerciseFilter,
          ExerciseFilterState,
          ExerciseFilterState,
          ExerciseFilterState,
          String
        > {
  ExerciseFilterFamily._()
    : super(
        retry: null,
        name: r'exerciseFilterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Filter state per screen ("library" tab, "picker").

  ExerciseFilterProvider call(String scope) =>
      ExerciseFilterProvider._(argument: scope, from: this);

  @override
  String toString() => r'exerciseFilterProvider';
}

/// Filter state per screen ("library" tab, "picker").

abstract class _$ExerciseFilter extends $Notifier<ExerciseFilterState> {
  late final _$args = ref.$arg as String;
  String get scope => _$args;

  ExerciseFilterState build(String scope);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ExerciseFilterState, ExerciseFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExerciseFilterState, ExerciseFilterState>,
              ExerciseFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(exerciseList)
final exerciseListProvider = ExerciseListFamily._();

final class ExerciseListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          List<Exercise>,
          Stream<List<Exercise>>
        >
    with $FutureModifier<List<Exercise>>, $StreamProvider<List<Exercise>> {
  ExerciseListProvider._({
    required ExerciseListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseListHash();

  @override
  String toString() {
    return r'exerciseListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Exercise>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Exercise>> create(Ref ref) {
    final argument = this.argument as String;
    return exerciseList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseListHash() => r'b04bebd92cbc42cbac0491ff7fd28584a0e05059';

final class ExerciseListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Exercise>>, String> {
  ExerciseListFamily._()
    : super(
        retry: null,
        name: r'exerciseListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExerciseListProvider call(String scope) =>
      ExerciseListProvider._(argument: scope, from: this);

  @override
  String toString() => r'exerciseListProvider';
}

@ProviderFor(muscleGroups)
final muscleGroupsProvider = MuscleGroupsProvider._();

final class MuscleGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  MuscleGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'muscleGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$muscleGroupsHash();

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    return muscleGroups(ref);
  }
}

String _$muscleGroupsHash() => r'a2589a342f8b896853ffd298b454406b7bf239b1';

@ProviderFor(equipmentTypes)
final equipmentTypesProvider = EquipmentTypesProvider._();

final class EquipmentTypesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          Stream<List<String>>
        >
    with $FutureModifier<List<String>>, $StreamProvider<List<String>> {
  EquipmentTypesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'equipmentTypesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$equipmentTypesHash();

  @$internal
  @override
  $StreamProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<String>> create(Ref ref) {
    return equipmentTypes(ref);
  }
}

String _$equipmentTypesHash() => r'9a3b273140986e9ffce39f56e3a548ab8e33786c';

@ProviderFor(exerciseById)
final exerciseByIdProvider = ExerciseByIdFamily._();

final class ExerciseByIdProvider
    extends
        $FunctionalProvider<AsyncValue<Exercise?>, Exercise?, Stream<Exercise?>>
    with $FutureModifier<Exercise?>, $StreamProvider<Exercise?> {
  ExerciseByIdProvider._({
    required ExerciseByIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'exerciseByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseByIdHash();

  @override
  String toString() {
    return r'exerciseByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Exercise?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Exercise?> create(Ref ref) {
    final argument = this.argument as int;
    return exerciseById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseByIdHash() => r'f9d4eb7c741368b79e46151313b85ea010ad8214';

final class ExerciseByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Exercise?>, int> {
  ExerciseByIdFamily._()
    : super(
        retry: null,
        name: r'exerciseByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExerciseByIdProvider call(int id) =>
      ExerciseByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'exerciseByIdProvider';
}

/// Exercise writes (keepAlive: command controllers are only read, never watched).

@ProviderFor(ExerciseController)
final exerciseControllerProvider = ExerciseControllerProvider._();

/// Exercise writes (keepAlive: command controllers are only read, never watched).
final class ExerciseControllerProvider
    extends $NotifierProvider<ExerciseController, void> {
  /// Exercise writes (keepAlive: command controllers are only read, never watched).
  ExerciseControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseControllerHash();

  @$internal
  @override
  ExerciseController create() => ExerciseController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$exerciseControllerHash() =>
    r'1ec011146f403003ee68ce856e8aa0b0b022da52';

/// Exercise writes (keepAlive: command controllers are only read, never watched).

abstract class _$ExerciseController extends $Notifier<void> {
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
