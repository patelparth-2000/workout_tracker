// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(legacyReader)
final legacyReaderProvider = LegacyReaderProvider._();

final class LegacyReaderProvider
    extends $FunctionalProvider<LegacyReader, LegacyReader, LegacyReader>
    with $Provider<LegacyReader> {
  LegacyReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'legacyReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$legacyReaderHash();

  @$internal
  @override
  $ProviderElement<LegacyReader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LegacyReader create(Ref ref) {
    return legacyReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LegacyReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LegacyReader>(value),
    );
  }
}

String _$legacyReaderHash() => r'c9aab171c80429c90bb3461a7fe8f23951214d9b';
