// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProgressSelectionNotifier)
final progressSelectionProvider = ProgressSelectionNotifierProvider._();

final class ProgressSelectionNotifierProvider
    extends $NotifierProvider<ProgressSelectionNotifier, ProgressSelection> {
  ProgressSelectionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressSelectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressSelectionNotifierHash();

  @$internal
  @override
  ProgressSelectionNotifier create() => ProgressSelectionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressSelection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressSelection>(value),
    );
  }
}

String _$progressSelectionNotifierHash() =>
    r'3010377b919977c41cdfd6a2a4682e2630e8e91d';

abstract class _$ProgressSelectionNotifier
    extends $Notifier<ProgressSelection> {
  ProgressSelection build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProgressSelection, ProgressSelection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProgressSelection, ProgressSelection>,
              ProgressSelection,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(trainedExercises)
final trainedExercisesProvider = TrainedExercisesProvider._();

final class TrainedExercisesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ExerciseWithHistory>>,
          List<ExerciseWithHistory>,
          Stream<List<ExerciseWithHistory>>
        >
    with
        $FutureModifier<List<ExerciseWithHistory>>,
        $StreamProvider<List<ExerciseWithHistory>> {
  TrainedExercisesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trainedExercisesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trainedExercisesHash();

  @$internal
  @override
  $StreamProviderElement<List<ExerciseWithHistory>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ExerciseWithHistory>> create(Ref ref) {
    return trainedExercises(ref);
  }
}

String _$trainedExercisesHash() => r'74f9bc6a217b4ce95cd544d9035696f998125ea6';

@ProviderFor(exerciseBests)
final exerciseBestsProvider = ExerciseBestsFamily._();

final class ExerciseBestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExerciseBests>,
          ExerciseBests,
          Stream<ExerciseBests>
        >
    with $FutureModifier<ExerciseBests>, $StreamProvider<ExerciseBests> {
  ExerciseBestsProvider._({
    required ExerciseBestsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'exerciseBestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseBestsHash();

  @override
  String toString() {
    return r'exerciseBestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ExerciseBests> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ExerciseBests> create(Ref ref) {
    final argument = this.argument as int;
    return exerciseBests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseBestsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseBestsHash() => r'e557c049b0bf319b672a33874140d75cc70d7175';

final class ExerciseBestsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ExerciseBests>, int> {
  ExerciseBestsFamily._()
    : super(
        retry: null,
        name: r'exerciseBestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExerciseBestsProvider call(int exerciseId) =>
      ExerciseBestsProvider._(argument: exerciseId, from: this);

  @override
  String toString() => r'exerciseBestsProvider';
}

@ProviderFor(progressSeries)
final progressSeriesProvider = ProgressSeriesFamily._();

final class ProgressSeriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProgressPoint>>,
          List<ProgressPoint>,
          Stream<List<ProgressPoint>>
        >
    with
        $FutureModifier<List<ProgressPoint>>,
        $StreamProvider<List<ProgressPoint>> {
  ProgressSeriesProvider._({
    required ProgressSeriesFamily super.from,
    required (int, ProgressRange) super.argument,
  }) : super(
         retry: null,
         name: r'progressSeriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progressSeriesHash();

  @override
  String toString() {
    return r'progressSeriesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<ProgressPoint>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ProgressPoint>> create(Ref ref) {
    final argument = this.argument as (int, ProgressRange);
    return progressSeries(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressSeriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progressSeriesHash() => r'f337f862dd468bc4b05977baf17a2a081d1464cb';

final class ProgressSeriesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<ProgressPoint>>,
          (int, ProgressRange)
        > {
  ProgressSeriesFamily._()
    : super(
        retry: null,
        name: r'progressSeriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProgressSeriesProvider call(int exerciseId, ProgressRange range) =>
      ProgressSeriesProvider._(argument: (exerciseId, range), from: this);

  @override
  String toString() => r'progressSeriesProvider';
}

/// Set ids that are personal records within a session (live or finished).

@ProviderFor(recordSetIds)
final recordSetIdsProvider = RecordSetIdsFamily._();

/// Set ids that are personal records within a session (live or finished).

final class RecordSetIdsProvider
    extends
        $FunctionalProvider<AsyncValue<Set<int>>, Set<int>, Stream<Set<int>>>
    with $FutureModifier<Set<int>>, $StreamProvider<Set<int>> {
  /// Set ids that are personal records within a session (live or finished).
  RecordSetIdsProvider._({
    required RecordSetIdsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'recordSetIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$recordSetIdsHash();

  @override
  String toString() {
    return r'recordSetIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Set<int>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Set<int>> create(Ref ref) {
    final argument = this.argument as int;
    return recordSetIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecordSetIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recordSetIdsHash() => r'f2f216e6db83cc4765c6d1ecf9d12626ee32cccc';

/// Set ids that are personal records within a session (live or finished).

final class RecordSetIdsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Set<int>>, int> {
  RecordSetIdsFamily._()
    : super(
        retry: null,
        name: r'recordSetIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Set ids that are personal records within a session (live or finished).

  RecordSetIdsProvider call(int sessionId) =>
      RecordSetIdsProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'recordSetIdsProvider';
}
