// lib/inventory/widgets/common/stock_indicator.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

enum StockLevel { outOfStock, critical, low, normal, high }

class StockIndicator extends StatelessWidget {
  final int currentStock;
  final int minStock;
  final int? maxStock;
  final bool showLabel;
  final bool showProgress;
  final bool compact;

  const StockIndicator({
    super.key,
    required this.currentStock,
    required this.minStock,
    this.maxStock,
    this.showLabel = true,
    this.showProgress = true,
    this.compact = false,
  });

  StockLevel get level {
    if (currentStock <= 0) return StockLevel.outOfStock;
    if (currentStock <= minStock * 0.5) return StockLevel.critical;
    if (currentStock <= minStock) return StockLevel.low;
    if (maxStock != null && currentStock >= maxStock!) return StockLevel.high;
    return StockLevel.normal;
  }

  Color get color {
    return switch (level) {
      StockLevel.outOfStock => AppColors.error,
      StockLevel.critical => AppColors.error,
      StockLevel.low => AppColors.warning,
      StockLevel.normal => AppColors.success,
      StockLevel.high => AppColors.info,
    };
  }

  String get labelText {
    return switch (level) {
      StockLevel.outOfStock => 'Sin Stock',
      StockLevel.critical => 'Crítico',
      StockLevel.low => 'Bajo',
      StockLevel.normal => 'Normal',
      StockLevel.high => 'Alto',
    };
  }

  IconData get icon {
    return switch (level) {
      StockLevel.outOfStock => Icons.remove_circle_rounded,
      StockLevel.critical => Icons.error_rounded,
      StockLevel.low => Icons.warning_rounded,
      StockLevel.normal => Icons.check_circle_rounded,
      StockLevel.high => Icons.arrow_circle_up_rounded,
    };
  }

  double get progressValue {
    if (maxStock == null || maxStock == 0) return 0.5;
    return (currentStock / maxStock!).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  Widget _buildCompact() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          currentStock.toString(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFull() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$currentStock unidades',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (showLabel)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            labelText,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (showProgress) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (minStock > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Mínimo: $minStock${maxStock != null ? ' | Máximo: $maxStock' : ''}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ],
    );
  }
}
