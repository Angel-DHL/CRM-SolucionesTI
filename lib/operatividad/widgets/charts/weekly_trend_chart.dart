// lib/operatividad/widgets/charts/weekly_trend_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/oper_activity.dart';

class WeeklyTrendChart extends StatelessWidget {
  final List<OperActivity> activities;

  const WeeklyTrendChart({super.key, required this.activities});

  /// Calcula actividades completadas por semana (últimas 8 semanas)
  List<_WeekData> get _weeklyData {
    final now = DateTime.now();
    final weeks = <_WeekData>[];

    for (int i = 7; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final completedCount = activities.where((a) {
        if (a.status != OperStatus.done && a.status != OperStatus.verified) {
          return false;
        }
        final completedDate = a.workEndAt ?? a.actualEndAt ?? a.updatedAt;
        return completedDate.isAfter(weekStart) &&
            completedDate.isBefore(weekEnd.add(const Duration(days: 1)));
      }).length;

      final createdCount = activities.where((a) {
        return a.createdAt.isAfter(weekStart) &&
            a.createdAt.isBefore(weekEnd.add(const Duration(days: 1)));
      }).length;

      weeks.add(
        _WeekData(
          weekStart: weekStart,
          weekEnd: weekEnd,
          completedCount: completedCount,
          createdCount: createdCount,
        ),
      );
    }

    return weeks;
  }

  @override
  Widget build(BuildContext context) {
    final data = _weeklyData;
    final maxY = data.fold<int>(0, (prev, w) {
      final max = w.completedCount > w.createdCount
          ? w.completedCount
          : w.createdCount;
      return max > prev ? max : prev;
    });

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
                  Icons.show_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'Tendencia semanal',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Mini legend
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniLegend(color: AppColors.success, label: 'Completadas'),
                    const SizedBox(width: AppDimensions.md),
                    _MiniLegend(color: AppColors.info, label: 'Creadas'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),

            // Chart
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 4).clamp(1, double.infinity),
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: AppColors.divider, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (maxY / 4).clamp(1, double.infinity),
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
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final week = data[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd/MM').format(week.weekStart),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textHint,
                                fontSize: 10,
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
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: (maxY + 2).toDouble(),
                  lineBarsData: [
                    // Completadas
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          e.value.completedCount.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.success,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.success.withOpacity(0.1),
                      ),
                    ),
                    // Creadas
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          e.value.createdCount.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppColors.info,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dashArray: [8, 4],
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.info,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.info.withOpacity(0.05),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primaryDark,
                      tooltipRoundedRadius: AppDimensions.radiusMd,
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final isCompleted = spot.barIndex == 0;
                          return LineTooltipItem(
                            '${isCompleted ? "Completadas" : "Creadas"}: ${spot.y.toInt()}',
                            TextStyle(
                              color: isCompleted
                                  ? AppColors.success
                                  : AppColors.info,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                duration: AppDimensions.animNormal,
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int completedCount;
  final int createdCount;

  _WeekData({
    required this.weekStart,
    required this.weekEnd,
    required this.completedCount,
    required this.createdCount,
  });
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
          height: 3,
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
