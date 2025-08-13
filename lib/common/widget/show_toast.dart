import 'package:flutter/material.dart';
import 'package:workout_tracker/utils/color_constant.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showToast({
  required String message,
  Duration snackBarDisplayDuration = const Duration(milliseconds: 4000),
}) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      duration: snackBarDisplayDuration,
      backgroundColor: BackgroundColor.black,
      content: Text(
        message,
      ),
    ),
    snackBarAnimationStyle: AnimationStyle(
      duration: const Duration(seconds: 1),
      reverseDuration: const Duration(seconds: 1),
    ),
  );
}
