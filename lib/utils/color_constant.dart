import 'package:flutter/material.dart';

/// Colour tokens. The ONLY file that holds raw colour values. Screens read colours from
/// `Theme.of(context).colorScheme` or the `AppColors` theme extension, never from here.

/// Brand + semantic palette for light and dark themes.
class AppPalette {
  static const Color seed = Color(0xff1565C0);

  // Success (completed sets)
  static const Color successLight = Color(0xff2E7D32);
  static const Color onSuccessLight = Color(0xffFFFFFF);
  static const Color successContainerLight = Color(0xffC8E6C9);
  static const Color successDark = Color(0xff81C784);
  static const Color onSuccessDark = Color(0xff0B3D10);
  static const Color successContainerDark = Color(0xff1E4620);

  // Personal records
  static const Color recordLight = Color(0xffB26A00);
  static const Color onRecordLight = Color(0xffFFFFFF);
  static const Color recordDark = Color(0xffFFCA28);
  static const Color onRecordDark = Color(0xff3E2A00);

  // Chart series
  static const Color chartPrimaryLight = Color(0xff1565C0);
  static const Color chartSecondaryLight = Color(0xff00897B);
  static const Color chartPrimaryDark = Color(0xff90CAF9);
  static const Color chartSecondaryDark = Color(0xff80CBC4);
}

// v1 colours, used only by the v1 screens. Removed together with those screens.
class TextColor {
  static const Color white = Color(0xffFFFFFF);
  static const Color black = Color(0xff000000);
}

class IconColor {
  static const Color black = Color(0xff000000);
  static const Color blue = Colors.blue;
  static const Color white = Color(0xffFFFFFF);
  static const Color red = Color(0xffFF0000);
  static const Color green = Colors.green;
}

class ButtonColor {
  static const Color blue = Colors.blue;
  static const Color white = Color(0xffFFFFFF);
}

class BorderColor {
  static const Color grey = Color(0xffCCCCCC);
  static const Color black = Color(0xff000000);
}

class BackgroundColor {
  static const Color white = Color(0xffFFFFFF);
  static const Color black = Color(0xff000000);
  static const Color blue = Colors.blue;
}

class DividerColor {
  static const Color black = Color(0xff000000);
}
