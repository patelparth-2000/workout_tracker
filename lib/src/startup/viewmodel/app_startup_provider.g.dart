// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_startup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opens the database (creating + seeding it on first launch) and runs the one-shot v1
/// import. The app routes in only once this completes.

@ProviderFor(AppStartup)
final appStartupProvider = AppStartupProvider._();

/// Opens the database (creating + seeding it on first launch) and runs the one-shot v1
/// import. The app routes in only once this completes.
final class AppStartupProvider
    extends $AsyncNotifierProvider<AppStartup, LegacyImportResult> {
  /// Opens the database (creating + seeding it on first launch) and runs the one-shot v1
  /// import. The app routes in only once this completes.
  AppStartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStartupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStartupHash();

  @$internal
  @override
  AppStartup create() => AppStartup();
}

String _$appStartupHash() => r'f3f0c426094d09858b60507e7bd5f5d4ced49a1f';

/// Opens the database (creating + seeding it on first launch) and runs the one-shot v1
/// import. The app routes in only once this completes.

abstract class _$AppStartup extends $AsyncNotifier<LegacyImportResult> {
  FutureOr<LegacyImportResult> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<LegacyImportResult>, LegacyImportResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LegacyImportResult>, LegacyImportResult>,
              AsyncValue<LegacyImportResult>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
