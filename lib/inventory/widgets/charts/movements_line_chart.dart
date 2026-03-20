// lib/inventory/widgets/charts/movements_line_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class MovementsLineChart extends StatelessWidget {
  final List<MovementPoint> inData;
  final List<MovementPoint> outData;
  final double height;
  final String? title;

  const MovementsLineChart({
    super.key,
    required this.inData,
    required this.outData,
    this.height = 250,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (inData.isEmpty && outData.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Sin datos de movimientos',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
        ),
      );
    }

    final allValues = [
      ...inData.map((d) => d.value),
      ...outData.map((d) => d.value),
    ];
    final maxY = allValues.isEmpty
        ? 10.0
        : allValues.reduce((a, b) => a > b ? a : b) * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Text(title!, style: AppTextStyles.h4),
              const Spacer(),
              _LegendChip(color: AppColors.success, label: 'Entradas'),
              const SizedBox(width: AppDimensions.md),
              _LegendChip(color: AppColors.error, label: 'Salidas'),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
        ],
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: AppColors.divider, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= inData.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('dd/MM').format(inData[index].date),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                    interval: (inData.length / 6).ceilToDouble(),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      );
                    },
                    reservedSize: 40,
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
              maxX: (inData.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                // Entradas
                LineChartBarData(
                  spots: inData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
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
                // Salidas
                LineChartBarData(
                  spots: outData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.value);
                  }).toList(),
                  isCurved: true,
                  color: AppColors.error,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.error,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.error.withOpacity(0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surface,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIn = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${isIn ? "Entrada" : "Salida"}: ${spot.y.toInt()}',
                        AppTextStyles.bodySmall.copyWith(
                          color: isIn ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class MovementPoint {
  final DateTime date;
  final double value;

  const MovementPoint({required this.date, required this.value});
}
