import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/database_provider.dart';
import '../../../data/legacy/legacy_importer.dart';
import '../../../data/legacy/legacy_store.dart';
import '../../../utils/clock.dart';

part 'app_startup_provider.g.dart';

/// Opens the database (creating + seeding it on first launch) and runs the one-shot v1
/// import. The app routes in only once this completes.
@Riverpod(keepAlive: true)
class AppStartup extends _$AppStartup {
  @override
  Future<LegacyImportResult> build() async {
    final db = ref.watch(appDatabaseProvider);
    await db.settingsDao.getSettings();
    return LegacyImporter(
      db,
      readLegacy: ref.watch(legacyReaderProvider),
      now: ref.watch(clockProvider),
    ).run();
  }

  void retry() => ref.invalidateSelf();
}
