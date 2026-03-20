// lib/inventory/widgets/charts/stock_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class StockBarChart extends StatelessWidget {
  final List<StockBarData> data;
  final double height;
  final String? title;
  final bool showValues;

  const StockBarChart({
    super.key,
    required this.data,
    this.height = 200,
    this.title,
    this.showValues = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Sin datos',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
        ),
      );
    }

    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!, style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.md),
        ],
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surface,
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${data[groupIndex].label}\n${rod.toY.toInt()}',
                      AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= data.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          data[value.toInt()].shortLabel ??
                              data[value.toInt()].label.substring(0, 3),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
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
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: AppColors.divider, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: entry.value.color ?? AppColors.primary,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                  showingTooltipIndicators: showValues ? [0] : [],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class StockBarData {
  final String label;
  final String? shortLabel;
  final int value;
  final Color? color;

  const StockBarData({
    required this.label,
    this.shortLabel,
    required this.value,
    this.color,
  });
}
