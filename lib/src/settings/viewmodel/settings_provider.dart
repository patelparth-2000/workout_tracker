import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/app_database.dart';
import '../../../data/database_provider.dart';
import '../../../utils/units.dart';

part 'settings_provider.g.dart';

/// Live settings row.
@Riverpod(keepAlive: true)
Stream<AppSettingsData> currentSettings(Ref ref) =>
    ref.watch(appDatabaseProvider).settingsDao.watchSettings();

/// The display unit. kg until settings have loaded.
@riverpod
WeightUnit weightUnit(Ref ref) => WeightUnit.fromName(
  ref.watch(currentSettingsProvider.select((s) => s.value?.unit)),
);

/// Default rest in seconds (90 until settings have loaded).
@riverpod
int defaultRestSeconds(Ref ref) => ref.watch(
  currentSettingsProvider.select((s) => s.value?.defaultRestSeconds ?? 90),
);

ThemeMode themeModeFrom(String value) => switch (value) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

/// Settings writes. keepAlive: a command controller is only ever `ref.read`, never
/// watched, so an auto-dispose one is disposed before its method runs.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  void build() {}

  Future<void> setUnit(WeightUnit unit) =>
      ref.read(appDatabaseProvider).settingsDao.setUnit(unit.name);

  Future<void> setDefaultRest(int seconds) =>
      ref.read(appDatabaseProvider).settingsDao.setDefaultRestSeconds(seconds);

  Future<void> setThemeMode(String mode) =>
      ref.read(appDatabaseProvider).settingsDao.setThemeMode(mode);
}

/// Rest choices offered in settings (seconds).
const restChoices = [30, 45, 60, 75, 90, 120, 150, 180, 240, 300];
