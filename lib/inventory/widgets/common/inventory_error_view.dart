// lib/inventory/widgets/common/inventory_error_view.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';

class InventoryErrorView extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool showDetails;

  const InventoryErrorView({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.showDetails = false,
  });

  /// Error genérico
  factory InventoryErrorView.generic({VoidCallback? onRetry}) {
    return InventoryErrorView(
      message: 'Algo salió mal',
      details: 'Ocurrió un error inesperado. Por favor intenta de nuevo.',
      onRetry: onRetry,
    );
  }

  /// Error de conexión
  factory InventoryErrorView.network({VoidCallback? onRetry}) {
    return InventoryErrorView(
      message: 'Sin conexión',
      details: 'Verifica tu conexión a internet e intenta de nuevo.',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Error de permisos
  factory InventoryErrorView.permission({VoidCallback? onRetry}) {
    return InventoryErrorView(
      message: 'Sin permisos',
      details: 'No tienes permisos para realizar esta acción.',
      icon: Icons.lock_outline_rounded,
      onRetry: onRetry,
    );
  }

  /// Error de datos no encontrados
  factory InventoryErrorView.notFound({
    String? itemType,
    VoidCallback? onRetry,
  }) {
    return InventoryErrorView(
      message: '${itemType ?? "Elemento"} no encontrado',
      details: 'El elemento que buscas no existe o fue eliminado.',
      icon: Icons.search_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Error de carga
  factory InventoryErrorView.loadError({
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return InventoryErrorView(
      message: 'Error al cargar',
      details: errorMessage ?? 'No se pudieron cargar los datos.',
      icon: Icons.cloud_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Error de guardado
  factory InventoryErrorView.saveError({
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return InventoryErrorView(
      message: 'Error al guardar',
      details: errorMessage ?? 'No se pudieron guardar los cambios.',
      icon: Icons.save_outlined,
      onRetry: onRetry,
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
            // Icon
            Container(
              padding: const EdgeInsets.all(AppDimensions.xl),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.error),
            ),
            const SizedBox(height: AppDimensions.lg),

            // Message
            Text(
              message,
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),

            // Details
            if (details != null) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(
                details!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: AppDimensions.xl),

            // Retry button
            if (onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget compacto para mostrar errores inline
class InventoryErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const InventoryErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Reintentar'),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.error,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
