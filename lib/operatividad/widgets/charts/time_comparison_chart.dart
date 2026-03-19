// lib/operatividad/widgets/charts/time_comparison_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/oper_activity.dart';

class TimeComparisonChart extends StatelessWidget {
  final List<OperActivity> activities;

  const TimeComparisonChart({super.key, required this.activities});

  List<OperActivity> get _completedWithTime {
    return activities
        .where((a) {
          return (a.status == OperStatus.done ||
                  a.status == OperStatus.verified) &&
              a.estimatedHours > 0 &&
              a.workStartAt != null;
        })
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = _completedWithTime;

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
                  Icons.compare_arrows_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'Tiempo estimado vs real',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniLegend(color: AppColors.info, label: 'Estimado'),
                    const SizedBox(width: AppDimensions.md),
                    _MiniLegend(color: AppColors.primary, label: 'Real'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),

            if (data.isEmpty)
              SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 48,
                        color: AppColors.textHint.withOpacity(0.3),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        'Sin datos de tiempo aún',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                      Text(
                        'Completa actividades con horas estimadas',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primaryDark,
                        tooltipRoundedRadius: AppDimensions.radiusMd,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final activity = data[group.x.toInt()];
                          final label = rodIndex == 0 ? 'Estimado' : 'Real';
                          return BarTooltipItem(
                            '${activity.title}\n$label: ${rod.toY.toStringAsFixed(1)}h',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}h',
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
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[index].title.length > 8
                                    ? '${data[index].title.substring(0, 8)}...'
                                    : data[index].title,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textHint,
                                  fontSize: 9,
                                ),
                                textAlign: TextAlign.center,
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
                      final a = entry.value;
                      final realHours = a.workDurationHours ?? 0;

                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: a.estimatedHours,
                            color: AppColors.info,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: realHours,
                            color: realHours > a.estimatedHours
                                ? AppColors.error
                                : AppColors.primary,
                            width: 12,
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
          ],
        ),
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
