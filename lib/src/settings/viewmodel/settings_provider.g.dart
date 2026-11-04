// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live settings row.

@ProviderFor(currentSettings)
final currentSettingsProvider = CurrentSettingsProvider._();

/// Live settings row.

final class CurrentSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppSettingsData>,
          AppSettingsData,
          Stream<AppSettingsData>
        >
    with $FutureModifier<AppSettingsData>, $StreamProvider<AppSettingsData> {
  /// Live settings row.
  CurrentSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSettingsHash();

  @$internal
  @override
  $StreamProviderElement<AppSettingsData> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppSettingsData> create(Ref ref) {
    return currentSettings(ref);
  }
}

String _$currentSettingsHash() => r'0c00160f72678b541d84a81f92b1493db47ded33';

/// The display unit. kg until settings have loaded.

@ProviderFor(weightUnit)
final weightUnitProvider = WeightUnitProvider._();

/// The display unit. kg until settings have loaded.

final class WeightUnitProvider
    extends $FunctionalProvider<WeightUnit, WeightUnit, WeightUnit>
    with $Provider<WeightUnit> {
  /// The display unit. kg until settings have loaded.
  WeightUnitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weightUnitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weightUnitHash();

  @$internal
  @override
  $ProviderElement<WeightUnit> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WeightUnit create(Ref ref) {
    return weightUnit(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeightUnit value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeightUnit>(value),
    );
  }
}

String _$weightUnitHash() => r'b510d068e8e1be92f5e30905df041c97e4781c67';

/// Default rest in seconds (90 until settings have loaded).

@ProviderFor(defaultRestSeconds)
final defaultRestSecondsProvider = DefaultRestSecondsProvider._();

/// Default rest in seconds (90 until settings have loaded).

final class DefaultRestSecondsProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Default rest in seconds (90 until settings have loaded).
  DefaultRestSecondsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultRestSecondsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultRestSecondsHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return defaultRestSeconds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$defaultRestSecondsHash() =>
    r'c221d618f28952a63c5c5fdefaced4f284d3ead5';

/// Settings writes. keepAlive: a command controller is only ever `ref.read`, never
/// watched, so an auto-dispose one is disposed before its method runs.

@ProviderFor(SettingsController)
final settingsControllerProvider = SettingsControllerProvider._();

/// Settings writes. keepAlive: a command controller is only ever `ref.read`, never
/// watched, so an auto-dispose one is disposed before its method runs.
final class SettingsControllerProvider
    extends $NotifierProvider<SettingsController, void> {
  /// Settings writes. keepAlive: a command controller is only ever `ref.read`, never
  /// watched, so an auto-dispose one is disposed before its method runs.
  SettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsControllerHash();

  @$internal
  @override
  SettingsController create() => SettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$settingsControllerHash() =>
    r'1ea821ebde13651d8f3aedc1a40d5f967645415d';

/// Settings writes. keepAlive: a command controller is only ever `ref.read`, never
/// watched, so an auto-dispose one is disposed before its method runs.

abstract class _$SettingsController extends $Notifier<void> {
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
