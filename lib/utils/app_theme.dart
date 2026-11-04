import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'color_constant.dart';

/// Semantic colours Material's ColorScheme has no slot for.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.record,
    required this.onRecord,
    required this.chartPrimary,
    required this.chartSecondary,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color record;
  final Color onRecord;
  final Color chartPrimary;
  final Color chartSecondary;

  static const light = AppColors(
    success: AppPalette.successLight,
    onSuccess: AppPalette.onSuccessLight,
    successContainer: AppPalette.successContainerLight,
    record: AppPalette.recordLight,
    onRecord: AppPalette.onRecordLight,
    chartPrimary: AppPalette.chartPrimaryLight,
    chartSecondary: AppPalette.chartSecondaryLight,
  );

  static const dark = AppColors(
    success: AppPalette.successDark,
    onSuccess: AppPalette.onSuccessDark,
    successContainer: AppPalette.successContainerDark,
    record: AppPalette.recordDark,
    onRecord: AppPalette.onRecordDark,
    chartPrimary: AppPalette.chartPrimaryDark,
    chartSecondary: AppPalette.chartSecondaryDark,
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? record,
    Color? onRecord,
    Color? chartPrimary,
    Color? chartSecondary,
  }) => AppColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    record: record ?? this.record,
    onRecord: onRecord ?? this.onRecord,
    chartPrimary: chartPrimary ?? this.chartPrimary,
    chartSecondary: chartSecondary ?? this.chartSecondary,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      record: Color.lerp(record, other.record, t)!,
      onRecord: Color.lerp(onRecord, other.onRecord, t)!,
      chartPrimary: Color.lerp(chartPrimary, other.chartPrimary, t)!,
      chartSecondary: Color.lerp(chartSecondary, other.chartSecondary, t)!,
    );
  }
}

/// ThemeData built only from tokens.
class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColors.light);
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.seed,
      brightness: brightness,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: [colors],
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        scrolledUnderElevation: 2,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        shape: shape,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
