import 'units.dart';

/// Default bar and plates per unit (common gym sets).
const defaultBar = {WeightUnit.kg: 20.0, WeightUnit.lb: 45.0};
const defaultPlates = {
  WeightUnit.kg: [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25],
  WeightUnit.lb: [45.0, 35.0, 25.0, 10.0, 5.0, 2.5],
};

class PlateResult {
  const PlateResult({
    required this.perSide,
    required this.achieved,
    required this.shortBy,
  });

  /// Plates for ONE side, heaviest first.
  final List<double> perSide;

  /// Total the bar actually reaches (bar + 2 x per side).
  final double achieved;

  /// target - achieved (>= 0). Non-zero when the plates cannot make the target exactly.
  final double shortBy;

  bool get exact => shortBy.abs() < 1e-9;
}

/// Greedy per-side loading with unlimited pairs of each plate. Works in hundredths to
/// avoid float drift (2.5 + 1.25 ...). Greedy is optimal for the standard plate sets
/// above; for unusual custom sets it may not find the closest load (said, not hidden).
PlateResult calculatePlates({
  required double target,
  required double bar,
  required List<double> plates,
}) {
  int c(double v) => (v * 100).round();
  final barC = c(bar);
  if (c(target) <= barC || plates.isEmpty) {
    return PlateResult(
      perSide: const [],
      achieved: bar,
      shortBy: target > bar ? target - bar : 0,
    );
  }
  var remaining = (c(target) - barC) ~/ 2; // per side, hundredths
  final sorted = [
    ...{
      for (final p in plates)
        if (p > 0) c(p),
    },
  ]..sort((a, b) => b - a);
  final out = <double>[];
  for (final p in sorted) {
    while (remaining >= p) {
      out.add(p / 100);
      remaining -= p;
    }
  }
  final achievedC = barC + 2 * out.fold<int>(0, (s, p) => s + c(p));
  return PlateResult(
    perSide: out,
    achieved: achievedC / 100,
    shortBy: (c(target) - achievedC) / 100,
  );
}
