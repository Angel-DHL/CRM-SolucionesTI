// lib/inventory/widgets/common/status_badge.dart

import 'package:crm_solucionesti/inventory/models/inventory_movement.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_enums.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool outlined;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.outlined = false,
    this.fontSize,
  });

  /// Badge para tipo de item
  factory StatusBadge.itemType(InventoryItemType type) {
    return StatusBadge(label: type.label, color: type.color, icon: type.icon);
  }

  /// Badge para estado de item
  factory StatusBadge.itemStatus(InventoryItemStatus status) {
    return StatusBadge(label: status.label, color: status.color);
  }

  /// Badge para tipo de movimiento
  factory StatusBadge.movementType(MovementType type) {
    return StatusBadge(label: type.label, color: type.color, icon: type.icon);
  }

  /// Badge para estado de movimiento
  factory StatusBadge.movementStatus(MovementStatus status) {
    return StatusBadge(label: status.label, color: status.color);
  }

  /// Badge para condición de activo
  factory StatusBadge.assetCondition(AssetCondition condition) {
    return StatusBadge(label: condition.label, color: condition.color);
  }

  /// Badge de stock bajo
  factory StatusBadge.lowStock() {
    return const StatusBadge(
      label: 'Stock Bajo',
      color: AppColors.error,
      icon: Icons.warning_rounded,
    );
  }

  /// Badge de sin stock
  factory StatusBadge.outOfStock() {
    return const StatusBadge(
      label: 'Sin Stock',
      color: AppColors.error,
      icon: Icons.inventory_rounded,
    );
  }

  /// Badge de vencido
  factory StatusBadge.expired() {
    return const StatusBadge(
      label: 'Vencido',
      color: AppColors.error,
      icon: Icons.event_busy_rounded,
    );
  }

  /// Badge de próximo a vencer
  factory StatusBadge.expiringSoon() {
    return const StatusBadge(
      label: 'Por Vencer',
      color: AppColors.warning,
      icon: Icons.schedule_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.1),
        border: outlined ? Border.all(color: color, width: 1) : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
