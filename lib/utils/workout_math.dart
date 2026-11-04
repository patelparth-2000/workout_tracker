// Pure training maths. Inputs are kg; never units.

/// Epley estimated one-rep max: w * (1 + reps / 30). reps == 1 -> w. reps <= 0 is not a
/// lift and yields null. Must match the SQL in ProgressDao.
double? estimatedOneRepMax(double weightKg, int reps) {
  if (reps <= 0 || weightKg <= 0) return null;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}

double setVolume(double weightKg, int reps) => weightKg * reps;

/// "1h 05m", "42m", "0m".
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
}

/// "1:05" / "12:00" — used by the rest timer and elapsed time.
String formatClock(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total ~/ 60) % 60;
  final s = total % 60;
  final mm = h > 0 ? m.toString().padLeft(2, '0') : '$m';
  final head = h > 0 ? '$h:' : '';
  return '$head$mm:${s.toString().padLeft(2, '0')}';
}
