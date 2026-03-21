// lib/inventory/widgets/cards/inventory_stat_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class InventoryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final String? subtitle;
  final String? trend;
  final bool? trendIsPositive;
  final VoidCallback? onTap;
  final bool isLoading;

  const InventoryStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.backgroundColor,
    this.subtitle,
    this.trend,
    this.trendIsPositive,
    this.onTap,
    this.isLoading = false,
  });

  /// Card de total de items
  factory InventoryStatCard.totalItems(int count) {
    return InventoryStatCard(
      title: 'Total de Items',
      value: NumberFormat('#,##0').format(count),
      icon: Icons.inventory_2_rounded,
      color: AppColors.primary,
      subtitle: 'En inventario',
    );
  }

  /// Card de productos
  factory InventoryStatCard.products(int count) {
    return InventoryStatCard(
      title: 'Productos',
      value: NumberFormat('#,##0').format(count),
      icon: Icons.inventory_rounded,
      color: AppColors.info,
    );
  }

  /// Card de servicios
  factory InventoryStatCard.services(int count) {
    return InventoryStatCard(
      title: 'Servicios',
      value: NumberFormat('#,##0').format(count),
      icon: Icons.miscellaneous_services_rounded,
      color: AppColors.warning,
    );
  }

  /// Card de activos
  factory InventoryStatCard.assets(int count) {
    return InventoryStatCard(
      title: 'Activos',
      value: NumberFormat('#,##0').format(count),
      icon: Icons.business_center_rounded,
      color: AppColors.success,
    );
  }

  /// Card de stock bajo
  factory InventoryStatCard.lowStock(int count) {
    return InventoryStatCard(
      title: 'Stock Bajo',
      value: NumberFormat('#,##0').format(count),
      icon: Icons.warning_rounded,
      color: AppColors.error,
      subtitle: count > 0 ? 'Requieren atención' : 'Todo bien',
    );
  }

  /// Card de valor total
  factory InventoryStatCard.totalValue(double value) {
    final format = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return InventoryStatCard(
      title: 'Valor Total',
      value: format.format(value),
      icon: Icons.attach_money_rounded,
      color: AppColors.success,
      subtitle: 'Inventario',
    );
  }

  /// Card de items sin stock
  factory InventoryStatCard.outOfStock(int count) {
    return InventoryStatCard(
      title: 'Sin Stock',
      value: NumberFormat('#,##0').format(count),
      icon: Icons.inventory_rounded,
      color: AppColors.error,
    );
  }

  /// Card personalizado con tendencia
  factory InventoryStatCard.withTrend({
    required String title,
    required String value,
    required IconData icon,
    Color color = AppColors.primary,
    String? trend,
    bool? trendIsPositive,
  }) {
    return InventoryStatCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      trend: trend,
      trendIsPositive: trendIsPositive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            gradient: backgroundColor != null
                ? LinearGradient(
                    colors: [
                      backgroundColor!.withOpacity(0.05),
                      backgroundColor!.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row con ícono
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.md),

              // Value
              if (isLoading)
                const SizedBox(
                  height: 32,
                  width: 100,
                  child: LinearProgressIndicator(),
                )
              else
                Text(
                  value,
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              // Subtitle or trend
              if (subtitle != null || trend != null) ...[
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (trend != null) _buildTrend(),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrend() {
    if (trend == null) return const SizedBox.shrink();

    final isPositive = trendIsPositive ?? true;
    final trendColor = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 14,
            color: trendColor,
          ),
          const SizedBox(width: 2),
          Text(
            trend!,
            style: AppTextStyles.labelSmall.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Versión compacta de stat card (para usar en listas)
class CompactStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const CompactStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
