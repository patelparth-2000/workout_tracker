import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// The single way to show user feedback. Colours come from the theme's SnackBarTheme.
void showToast({
  required String message,
  Duration snackBarDisplayDuration = const Duration(milliseconds: 4000),
}) {
  scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(duration: snackBarDisplayDuration, content: Text(message)),
    );
}
