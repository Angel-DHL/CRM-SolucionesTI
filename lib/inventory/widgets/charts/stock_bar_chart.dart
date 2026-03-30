// lib/inventory/widgets/charts/stock_bar_chart.dart

import 'package:flutter/material.dart';
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
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(title!, style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.md),
        ],
        ...data.map((item) {
          final percentage = (item.value / maxValue);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${item.value}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 8,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      item.color ?? AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
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
