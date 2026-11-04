// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backupPlatform)
final backupPlatformProvider = BackupPlatformProvider._();

final class BackupPlatformProvider
    extends $FunctionalProvider<BackupPlatform, BackupPlatform, BackupPlatform>
    with $Provider<BackupPlatform> {
  BackupPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupPlatformHash();

  @$internal
  @override
  $ProviderElement<BackupPlatform> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupPlatform create(Ref ref) {
    return backupPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupPlatform value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupPlatform>(value),
    );
  }
}

String _$backupPlatformHash() => r'bcc994c4ce644bcf6a8ee43bdf295432c4ab2efb';

/// Export / restore (keepAlive: only ever `ref.read`).

@ProviderFor(BackupController)
final backupControllerProvider = BackupControllerProvider._();

/// Export / restore (keepAlive: only ever `ref.read`).
final class BackupControllerProvider
    extends $NotifierProvider<BackupController, void> {
  /// Export / restore (keepAlive: only ever `ref.read`).
  BackupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupControllerHash();

  @$internal
  @override
  BackupController create() => BackupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$backupControllerHash() => r'e3ac2ce39d2a30a81c55c37ca9ed26e4a4cd45c2';

/// Export / restore (keepAlive: only ever `ref.read`).

abstract class _$BackupController extends $Notifier<void> {
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
