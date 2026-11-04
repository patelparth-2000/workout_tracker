import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/utils/units.dart';
import 'package:workout_tracker/utils/workout_math.dart';

void main() {
  group('units', () {
    test('kg is the identity', () {
      expect(kgToUnit(62.5, WeightUnit.kg), 62.5);
      expect(unitToKg(62.5, WeightUnit.kg), 62.5);
    });

    test('lb conversion uses 2.2046226218', () {
      expect(kgToUnit(100, WeightUnit.lb), closeTo(220.46226218, 1e-9));
      expect(unitToKg(220.46226218, WeightUnit.lb), closeTo(100, 1e-9));
    });

    test(
      'typed lb values round-trip through kg storage to the same display',
      () {
        for (final lb in [45.0, 135.0, 225.0, 2.5, 0.0, 999.9, 1.1]) {
          final stored = unitToKg(lb, WeightUnit.lb);
          expect(
            formatWeight(stored, WeightUnit.lb, withUnit: false),
            formatNumber(lb),
          );
        }
      },
    );

    test('formatting rounds to one decimal and drops .0', () {
      expect(formatNumber(60), '60');
      expect(formatNumber(61.25), '61.3');
      expect(formatNumber(61.24), '61.2');
      expect(formatNumber(0.04), '0');
      expect(formatWeight(20, WeightUnit.lb), '44.1 lb');
      expect(formatWeight(20, WeightUnit.kg), '20 kg');
    });

    test('volume has thousands separators', () {
      expect(formatVolume(0, WeightUnit.kg), '0 kg');
      expect(formatVolume(999.6, WeightUnit.kg), '1,000 kg');
      expect(formatVolume(1234567, WeightUnit.kg), '1,234,567 kg');
      expect(formatVolume(100, WeightUnit.lb), '220 lb');
    });

    test('input parsing', () {
      expect(parseWeightInput(' 62,5 '), 62.5);
      expect(parseWeightInput('10 '), 10);
      expect(parseWeightInput(''), isNull);
      expect(parseWeightInput('abc'), isNull);
      expect(parseWeightInput('-1'), isNull);
      expect(parseWeightInput('NaN'), isNull);
      expect(parseRepsInput('8'), 8);
      expect(parseRepsInput('8.5'), isNull);
      expect(parseRepsInput('-3'), isNull);
      expect(WeightUnit.fromName('lb'), WeightUnit.lb);
      expect(WeightUnit.fromName('junk'), WeightUnit.kg);
    });
  });

  group('workout maths', () {
    test('Epley e1RM: reps 1 is the weight, reps 0 is not a lift', () {
      expect(estimatedOneRepMax(100, 1), 100);
      expect(estimatedOneRepMax(100, 0), isNull);
      expect(estimatedOneRepMax(0, 5), isNull);
      expect(estimatedOneRepMax(100, 10), closeTo(133.333, 1e-3));
      expect(estimatedOneRepMax(100, 30), 200);
    });

    test('volume and durations', () {
      expect(setVolume(60, 10), 600);
      expect(formatDuration(const Duration(minutes: 42)), '42m');
      expect(formatDuration(const Duration(hours: 1, minutes: 5)), '1h 05m');
      expect(formatClock(const Duration(seconds: 65)), '1:05');
      expect(formatClock(const Duration(hours: 1, seconds: 5)), '1:00:05');
      expect(formatClock(const Duration(seconds: -3)), '0:00');
    });
  });
}
