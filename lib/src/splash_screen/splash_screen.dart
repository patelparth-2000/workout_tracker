import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_tracker/routes/app_routes.dart';

import '../../utils/images.dart';

/// SplashScreen widget that displays a logo and navigates to the main screen after a delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      context.goNamed(RouteNames.workoutListScreen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              Images.splashLogo,
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 20),
            Text(
              'Workout Tracker',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
