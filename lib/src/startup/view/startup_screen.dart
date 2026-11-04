import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/widget/error_state.dart';
import '../../../common/widget/show_toast.dart';
import '../../../data/legacy/legacy_importer.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/images.dart';
import '../viewmodel/app_startup_provider.dart';

/// Shown until the database is ready. Replaces the fixed 3-second v1 splash.
class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appStartupProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        if (value.outcome == LegacyImportOutcome.imported) {
          showToast(
            message:
                'Imported ${value.entryCount} saved workouts from the previous version',
          );
        }
        context.goNamed(RouteNames.workout);
      }
    });
    final startup = ref.watch(appStartupProvider);
    return Scaffold(
      body: SafeArea(
        child: switch (startup) {
          AsyncError(:final error) => ErrorState(
            title: error is LegacyImportException
                ? 'Could not import your saved workouts'
                : 'Could not open your data',
            message: error is LegacyImportException
                ? '$error. Nothing was changed or deleted. You can retry, or continue '
                      'and the import will be tried again next time the app starts.'
                : '$error',
            onRetry: () => ref.read(appStartupProvider.notifier).retry(),
            secondaryAction: error is LegacyImportException
                ? TextButton(
                    onPressed: () => context.goNamed(RouteNames.workout),
                    child: const Text('Continue without importing'),
                  )
                : null,
          ),
          _ => const _Loading(),
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Workout Tracker is loading',
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.asset(
                  Images.splashLogo,
                  width: AppSizes.logo,
                  height: AppSizes.logo,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const ExcludeSemantics(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
