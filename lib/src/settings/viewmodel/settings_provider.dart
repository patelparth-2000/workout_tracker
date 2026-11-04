import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/app_database.dart';
import '../../../data/database_provider.dart';

part 'settings_provider.g.dart';

/// Live settings row.
@Riverpod(keepAlive: true)
Stream<AppSettingsData> currentSettings(Ref ref) =>
    ref.watch(appDatabaseProvider).settingsDao.watchSettings();

ThemeMode themeModeFrom(String value) => switch (value) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};
