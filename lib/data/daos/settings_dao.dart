import 'package:drift/drift.dart';

import '../app_database.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  SimpleSelectStatement<$AppSettingsTable, AppSettingsData> get _row =>
      select(appSettings)..where((s) => s.id.equals(1));

  /// The row is created in onCreate; insertOrIgnore self-heals if it is missing
  /// (e.g. after restoring a backup made by a future version without it).
  Future<AppSettingsData> getSettings() async {
    final row = await _row.getSingleOrNull();
    if (row != null) return row;
    await into(
      appSettings,
    ).insert(const AppSettingsCompanion(), mode: InsertMode.insertOrIgnore);
    return _row.getSingle();
  }

  Stream<AppSettingsData> watchSettings() => _row.watchSingleOrNull().asyncMap(
    (row) async => row ?? await getSettings(),
  );

  Future<void> _write(AppSettingsCompanion c) async {
    await getSettings();
    await (update(appSettings)..where((s) => s.id.equals(1))).write(c);
  }

  Future<void> setUnit(String unit) {
    if (unit != 'kg' && unit != 'lb') {
      throw ArgumentError.value(unit, 'unit');
    }
    return _write(AppSettingsCompanion(unit: Value(unit)));
  }

  Future<void> setDefaultRestSeconds(int seconds) {
    if (seconds < 0 || seconds > 3600) {
      throw RangeError.range(seconds, 0, 3600, 'seconds');
    }
    return _write(AppSettingsCompanion(defaultRestSeconds: Value(seconds)));
  }

  Future<void> setThemeMode(String mode) {
    if (!const {'system', 'light', 'dark'}.contains(mode)) {
      throw ArgumentError.value(mode, 'mode');
    }
    return _write(AppSettingsCompanion(themeMode: Value(mode)));
  }

  Future<void> markLegacyImported(DateTime at) =>
      _write(AppSettingsCompanion(legacyImportedAt: Value(at)));
}
