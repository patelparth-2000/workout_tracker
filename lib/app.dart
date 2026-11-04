import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common/widget/show_toast.dart';
import 'routes/app_routes.dart';
import 'src/settings/viewmodel/settings_provider.dart';
import 'utils/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    // Before the database is open the theme follows the system.
    final mode = ref.watch(
      currentSettingsProvider.select(
        (s) => themeModeFrom(s.value?.themeMode ?? 'system'),
      ),
    );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Workout Tracker',
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
    );
  }
}
