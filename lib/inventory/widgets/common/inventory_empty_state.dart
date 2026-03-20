// lib/inventory/widgets/common/inventory_empty_state.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class InventoryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool hasFilters;
  final VoidCallback? onClearFilters;

  const InventoryEmptyState({
    super.key,
    this.icon = Icons.inventory_2_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.hasFilters = false,
    this.onClearFilters,
  });

  /// Estado vacío para items
  factory InventoryEmptyState.items({
    bool hasFilters = false,
    VoidCallback? onClearFilters,
    VoidCallback? onAddItem,
  }) {
    return InventoryEmptyState(
      icon: Icons.inventory_2_outlined,
      title: hasFilters
          ? 'No hay items que coincidan'
          : 'No hay items en el inventario',
      subtitle: hasFilters
          ? 'Intenta con otros filtros de búsqueda'
          : 'Comienza agregando tu primer producto, servicio o activo',
      actionLabel: hasFilters ? null : 'Agregar Item',
      onAction: onAddItem,
      hasFilters: hasFilters,
      onClearFilters: onClearFilters,
    );
  }

  /// Estado vacío para categorías
  factory InventoryEmptyState.categories({VoidCallback? onAddCategory}) {
    return InventoryEmptyState(
      icon: Icons.category_outlined,
      title: 'No hay categorías',
      subtitle: 'Crea categorías para organizar tu inventario',
      actionLabel: 'Crear Categoría',
      onAction: onAddCategory,
    );
  }

  /// Estado vacío para proveedores
  factory InventoryEmptyState.suppliers({VoidCallback? onAddSupplier}) {
    return InventoryEmptyState(
      icon: Icons.local_shipping_outlined,
      title: 'No hay proveedores',
      subtitle: 'Agrega proveedores para gestionar tus compras',
      actionLabel: 'Agregar Proveedor',
      onAction: onAddSupplier,
    );
  }

  /// Estado vacío para ubicaciones
  factory InventoryEmptyState.locations({VoidCallback? onAddLocation}) {
    return InventoryEmptyState(
      icon: Icons.location_on_outlined,
      title: 'No hay ubicaciones',
      subtitle: 'Define ubicaciones para organizar tu inventario físico',
      actionLabel: 'Agregar Ubicación',
      onAction: onAddLocation,
    );
  }

  /// Estado vacío para movimientos
  factory InventoryEmptyState.movements() {
    return const InventoryEmptyState(
      icon: Icons.swap_horiz_rounded,
      title: 'No hay movimientos',
      subtitle: 'Los movimientos de inventario aparecerán aquí',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.xl),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              title,
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppDimensions.xl),
            if (hasFilters && onClearFilters != null)
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Limpiar filtros'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            if (actionLabel != null && onAction != null)
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
