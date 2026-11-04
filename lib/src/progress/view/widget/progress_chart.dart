import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../utils/app_spacing.dart';
import '../../../../utils/app_theme.dart';
import '../../../../utils/units.dart';

/// Line chart of values over time. Custom-painted, so it carries a text summary for
/// screen readers; the table under it on the Progress screen holds the exact values.
class ProgressChart extends StatelessWidget {
  const ProgressChart({
    super.key,
    required this.points,
    required this.unit,
    required this.metricLabel,
  });

  /// (date, value in kg)
  final List<(DateTime, double)> points;
  final WeightUnit unit;
  final String metricLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    if (points.isEmpty) return const SizedBox.shrink();
    final first = points.first.$1;
    double x(DateTime d) => d.difference(first).inHours / 24;
    final spots = [
      for (final p in points) FlSpot(x(p.$1), kgToUnit(p.$2, unit)),
    ];
    final values = spots.map((s) => s.y);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() < 1 ? 5.0 : (maxY - minY) * 0.15;
    final dateFmt = DateFormat.MMMd();
    final summary =
        '$metricLabel chart, ${points.length} workouts from '
        '${dateFmt.format(points.first.$1)} to ${dateFmt.format(points.last.$1)}. '
        'First ${formatWeight(points.first.$2, unit)}, latest '
        '${formatWeight(points.last.$2, unit)}, highest '
        '${formatNumber(maxY)} ${unit.symbol}.';

    return Semantics(
      label: summary,
      excludeSemantics: true,
      child: SizedBox(
        height: AppSizes.chartHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.sm,
          ),
          child: LineChart(
            LineChartData(
              minY: (minY - pad).clamp(0, double.infinity),
              maxY: maxY + pad,
              minX: 0,
              maxX: spots.last.x <= 0 ? 1 : spots.last.x,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        formatNumber(v),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: spots.last.x <= 0
                        ? 1
                        : (spots.last.x / 3).ceilToDouble(),
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        dateFmt.format(
                          first.add(Duration(hours: (v * 24).round())),
                        ),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) => [
                    for (final t in touched)
                      LineTooltipItem(
                        '${formatNumber(t.y)} ${unit.symbol}',
                        theme.textTheme.labelMedium!.copyWith(
                          color: theme.colorScheme.onInverseSurface,
                        ),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: colors.chartPrimary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
