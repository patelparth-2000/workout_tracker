import 'package:flutter/material.dart';

class Images {
  // Logos
  static const String splashLogo = 'images/logos/splash_logo.jpeg';

  // gif images
  static const String barbellRow = 'images/gifs/workout_barbell_row.gif';
  static const String benchPress = 'images/gifs/workout_bench_press.gif';
  static const String deadlift = 'images/gifs/workout_deadlift.gif';
  static const String squat = 'images/gifs/workout_squat.gif';
  static const String shoulderPrees = 'images/gifs/workout_shoulder_press.gif';

  // icon
  static const IconData editIcon = Icons.edit;
  static const IconData deleteIcon = Icons.delete;
  static const IconData addIcon = Icons.add;
  static const IconData viewIcon = Icons.remove_red_eye;
}

/// Non-image bundled assets.
class DataAssets {
  static const String exerciseSeed = 'assets/data/exercises.json';
}
