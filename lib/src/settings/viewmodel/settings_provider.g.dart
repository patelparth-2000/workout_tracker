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
