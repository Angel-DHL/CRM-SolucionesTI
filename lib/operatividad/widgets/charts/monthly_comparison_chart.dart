// lib/operatividad/widgets/charts/monthly_comparison_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/oper_activity.dart';
import '../../services/metrics_service.dart';

class MonthlyComparisonChart extends StatelessWidget {
  final List<OperActivity> activities;

  const MonthlyComparisonChart({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final data = MetricsService.calculateMonthlyMetrics(
      activities: activities,
      months: 6,
    );

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxActivities = data.fold<int>(
      0,
      (prev, m) => m.totalActivities > prev ? m.totalActivities : prev,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'Comparativo mensual',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniLegend(color: AppColors.primary, label: 'Totales'),
                    const SizedBox(width: AppDimensions.sm),
                    _MiniLegend(color: AppColors.success, label: 'Completadas'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),

            // Chart
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primaryDark,
                      tooltipRoundedRadius: AppDimensions.radiusMd,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month = data[group.x.toInt()];
                        final label = rodIndex == 0 ? 'Total' : 'Completadas';
                        return BarTooltipItem(
                          '${month.monthLabel}\n$label: ${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (maxActivities / 4).clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textHint,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[index].monthLabelShort,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: AppColors.divider, strokeWidth: 1),
                  ),
                  barGroups: data.asMap().entries.map((entry) {
                    final m = entry.value;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: m.totalActivities.toDouble(),
                          color: AppColors.primary.withOpacity(0.6),
                          width: 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: m.completedActivities.toDouble(),
                          color: AppColors.success,
                          width: 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                swapAnimationDuration: AppDimensions.animNormal,
              ),
            ),

            const SizedBox(height: AppDimensions.lg),

            // Monthly summary cards
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppDimensions.sm),
                itemBuilder: (context, index) {
                  final m = data[index];
                  return _MonthSummaryChip(metrics: m);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSummaryChip extends StatelessWidget {
  final MonthlyMetrics metrics;

  const _MonthSummaryChip({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final color = metrics.completionRate >= 0.8
        ? AppColors.success
        : metrics.completionRate >= 0.5
        ? AppColors.warning
        : AppColors.error;

    return Container(
      width: 100,
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            metrics.monthLabelShort,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
          ),
          Text(
            '${(metrics.completionRate * 100).toStringAsFixed(0)}%',
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${metrics.completedActivities}/${metrics.totalActivities}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textHint,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _MiniLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textHint,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
