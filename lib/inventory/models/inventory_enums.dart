// lib/inventory/models/inventory_enums.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Tipo de ítem en el inventario
enum InventoryItemType {
  product('Producto', Icons.inventory_2_rounded, AppColors.primary),
  service('Servicio', Icons.construction_rounded, AppColors.warning),
  asset('Activo', Icons.account_balance_rounded, AppColors.success);

  final String label;
  final IconData icon;
  final Color color;
  const InventoryItemType(this.label, this.icon, this.color);

  static InventoryItemType fromString(String? value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => InventoryItemType.product,
    );
  }
}

/// Estado del ítem
enum InventoryItemStatus {
  active('Activo', AppColors.success),
  inactive('Inactivo', AppColors.textHint),
  discontinued('Descontinuado', AppColors.error),
  maintenance('En Mantenimiento', AppColors.warning);

  final String label;
  final Color color;
  const InventoryItemStatus(this.label, this.color);

  static InventoryItemStatus fromString(String? value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => InventoryItemStatus.active,
    );
  }
}

/// Unidad de medida
enum UnitOfMeasure {
  unit('Unidad', 'ud'),
  kg('Kilogramo', 'kg'),
  liter('Litro', 'L'),
  meter('Metro', 'm'),
  box('Caja', 'cj'),
  pack('Paquete', 'pq'),
  hour('Hora', 'hr'),
  day('Día', 'día'),
  month('Mes', 'mes');

  final String label;
  final String abbreviation;
  const UnitOfMeasure(this.label, this.abbreviation);

  static UnitOfMeasure fromString(String? value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => UnitOfMeasure.unit,
    );
  }
}

/// Tipo de movimiento de stock
enum MovementType {
  purchase('Compra', Icons.shopping_cart_rounded, AppColors.success),
  sale('Venta', Icons.point_of_sale_rounded, AppColors.primary),
  adjustment('Ajuste', Icons.tune_rounded, AppColors.warning),
  return_in(
    'Devolución Entrada',
    Icons.keyboard_return_rounded,
    AppColors.info,
  ),
  return_out('Devolución Salida', Icons.undo_rounded, AppColors.error),
  transfer('Transferencia', Icons.swap_horiz_rounded, AppColors.primaryLight),
  damaged('Dañado', Icons.broken_image_rounded, AppColors.error),
  lost('Pérdida', Icons.report_problem_rounded, AppColors.error);

  final String label;
  final IconData icon;
  final Color color;
  const MovementType(this.label, this.icon, this.color);

  bool get isIncoming => [purchase, return_in, adjustment].contains(this);
  bool get isOutgoing =>
      [sale, return_out, transfer, damaged, lost].contains(this);

  static MovementType fromString(String? value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => MovementType.adjustment,
    );
  }
}

/// Condición de un activo
enum AssetCondition {
  new_('Nuevo', AppColors.success),
  excellent('Excelente', AppColors.success),
  good('Bueno', AppColors.primary),
  fair('Regular', AppColors.warning),
  poor('Malo', AppColors.error),
  defective('Defectuoso', AppColors.error);

  final String label;
  final Color color;
  const AssetCondition(this.label, this.color);

  static AssetCondition fromString(String? value) {
    // Handle 'new' keyword by using 'new_'
    if (value == 'new') return AssetCondition.new_;
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => AssetCondition.good,
    );
  }
}
