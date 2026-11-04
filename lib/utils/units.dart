/// Weight units. Storage is ALWAYS kg; conversion happens only at the UI edge.
enum WeightUnit {
  kg('kg'),
  lb('lb');

  const WeightUnit(this.symbol);
  final String symbol;

  static WeightUnit fromName(String? name) => name == 'lb' ? lb : kg;
}

/// Exact definition: 1 kg = 2.2046226218 lb.
const double lbPerKg = 2.2046226218;

double kgToUnit(double kg, WeightUnit unit) =>
    unit == WeightUnit.kg ? kg : kg * lbPerKg;

double unitToKg(double value, WeightUnit unit) =>
    unit == WeightUnit.kg ? value : value / lbPerKg;

/// Rounds to one decimal and drops a trailing ".0": 60 -> "60", 61.25 -> "61.3".
String formatNumber(double value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.toStringAsFixed(0);
  return rounded.toStringAsFixed(1);
}

/// A stored kg value in the user's unit, e.g. "135 lb".
String formatWeight(double kg, WeightUnit unit, {bool withUnit = true}) {
  final text = formatNumber(kgToUnit(kg, unit));
  return withUnit ? '$text ${unit.symbol}' : text;
}

/// Large totals (volume) with thousands separators and no decimals: "12,345 kg".
String formatVolume(double kg, WeightUnit unit) {
  final v = kgToUnit(kg, unit).round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < v.length; i++) {
    if (i > 0 && (v.length - i) % 3 == 0) buf.write(',');
    buf.write(v[i]);
  }
  return '$buf ${unit.symbol}';
}

/// Parses a typed weight. Accepts "62.5", " 62,5 " (comma decimal locales). Null when not
/// a finite, non-negative number.
double? parseWeightInput(String text) {
  final v = double.tryParse(text.trim().replaceAll(',', '.'));
  if (v == null || !v.isFinite || v < 0) return null;
  return v;
}

/// Parses typed reps: a non-negative whole number.
int? parseRepsInput(String text) {
  final v = int.tryParse(text.trim());
  if (v == null || v < 0) return null;
  return v;
}
