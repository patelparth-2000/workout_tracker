import 'package:flutter/widgets.dart';

/// Spacing scale. Screens use these, never magic numbers.
class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 999;
}

class AppSizes {
  /// Minimum interactive size (Material / WCAG target size).
  static const double minTapTarget = 48;
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 48;
  static const double iconXl = 72;
  static const double gifHeight = 220;
  static const double chartHeight = 220;
  static const double logo = 160;
  static const double timerRing = 44;
  static const double maxContentWidth = 720;
  static const double inlineProgress = 24;
  static const double compactField = 120;
  static const double statTileMinWidth = 160;
  static const double chartLeftAxis = 44;
  static const double chartBottomAxis = 28;
  static const double chartLine = 3;
  static const double fabClearance = 96;
}

class AppInsets {
  static const EdgeInsets screen = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets screenH = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
  );
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets listTile = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.xs,
  );
  static const EdgeInsets section = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.xl,
    AppSpacing.lg,
    AppSpacing.sm,
  );

  /// Leaves room under the last list item for a floating action button.
  static const EdgeInsets listWithFab = EdgeInsets.only(
    bottom: AppSizes.fabClearance,
  );
}
