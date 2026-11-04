import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/utils/plate_math.dart';
import 'package:workout_tracker/utils/units.dart';

void main() {
  final kg = defaultPlates[WeightUnit.kg]!;
  final lb = defaultPlates[WeightUnit.lb]!;

  test('exact kg load, heaviest plates first', () {
    final r = calculatePlates(target: 100, bar: 20, plates: kg);
    expect(r.perSide, [25, 15]);
    expect(r.achieved, 100);
    expect(r.exact, isTrue);
  });

  test('fractional plates without float drift', () {
    final r = calculatePlates(target: 102.5, bar: 20, plates: kg);
    expect(r.perSide, [25, 15, 1.25]);
    expect(r.achieved, 102.5);
  });

  test('lb: 225 is two 45s a side; 315 is three', () {
    expect(calculatePlates(target: 225, bar: 45, plates: lb).perSide, [45, 45]);
    expect(calculatePlates(target: 315, bar: 45, plates: lb).perSide, [
      45,
      45,
      45,
    ]);
  });

  test('unreachable target reports how far short', () {
    final r = calculatePlates(target: 101, bar: 20, plates: kg);
    expect(r.achieved, 100);
    expect(r.shortBy, closeTo(1, 1e-9));
    expect(r.exact, isFalse);
  });

  test('target at or below the bar, and no plates', () {
    expect(calculatePlates(target: 20, bar: 20, plates: kg).perSide, isEmpty);
    final below = calculatePlates(target: 10, bar: 20, plates: kg);
    expect(below.achieved, 20);
    expect(below.shortBy, 0);
    final none = calculatePlates(target: 60, bar: 20, plates: const []);
    expect(none.perSide, isEmpty);
    expect(none.shortBy, 40);
  });

  test('only selected plates are used; duplicates and zeros ignored', () {
    final r = calculatePlates(
      target: 60,
      bar: 20,
      plates: const [10, 10, 0, 5],
    );
    expect(r.perSide, [10, 10]);
  });
}
