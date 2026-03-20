// lib/inventory/widgets/cards/inventory_item_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_item.dart';
import '../../models/inventory_enums.dart';
import '../common/status_badge.dart';
import '../common/stock_indicator.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStockMovement;
  final bool showActions;
  final bool compact;

  const InventoryItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onStockMovement,
    this.showActions = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildFullCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              _buildImage(),
              const SizedBox(width: AppDimensions.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.sku,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showActions) _buildPopupMenu(),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.sm),

                    // Badges
                    Wrap(
                      spacing: AppDimensions.xs,
                      runSpacing: AppDimensions.xs,
                      children: [
                        StatusBadge.itemType(item.type),
                        StatusBadge.itemStatus(item.status),
                        if (item.isStockLow) StatusBadge.lowStock(),
                        if (item.isExpired) StatusBadge.expired(),
                        if (item.isFeatured)
                          const StatusBadge(
                            label: 'Destacado',
                            color: AppColors.warning,
                            icon: Icons.star_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // Description
                    if (item.description.isNotEmpty) ...[
                      Text(
                        item.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.sm),
                    ],

                    // Footer
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Precio',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                              Text(
                                currencyFormat.format(item.sellingPrice),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stock (solo para productos y activos)
                        if (item.type != InventoryItemType.service)
                          Expanded(
                            child: StockIndicator(
                              currentStock: item.stock,
                              minStock: item.minStock,
                              maxStock: item.maxStock,
                              compact: true,
                            ),
                          ),

                        // Quick action
                        if (item.type != InventoryItemType.service &&
                            onStockMovement != null)
                          IconButton(
                            onPressed: onStockMovement,
                            icon: const Icon(Icons.swap_horiz_rounded),
                            tooltip: 'Movimiento de stock',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primarySurface,
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.sm),
          child: Row(
            children: [
              // Mini image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  color: AppColors.surface,
                  image: item.primaryImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(item.primaryImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.primaryImageUrl == null
                    ? Icon(item.type.icon, color: item.type.color, size: 24)
                    : null,
              ),
              const SizedBox(width: AppDimensions.sm),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.sku,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),

              // Stock
              if (item.type != InventoryItemType.service)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.isStockLow
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.stock}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: item.isStockLow
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(width: AppDimensions.sm),

              // Price
              Text(
                currencyFormat.format(item.sellingPrice),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: AppDimensions.xs),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        color: AppColors.surface,
        image: item.primaryImageUrl != null
            ? DecorationImage(
                image: NetworkImage(item.primaryImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: item.primaryImageUrl == null
          ? Center(
              child: Icon(
                item.type.icon,
                color: item.type.color.withOpacity(0.5),
                size: 40,
              ),
            )
          : null,
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textHint),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'stock':
            onStockMovement?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit_rounded),
              title: Text('Editar'),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        if (onStockMovement != null && item.type != InventoryItemType.service)
          const PopupMenuItem(
            value: 'stock',
            child: ListTile(
              leading: Icon(Icons.swap_horiz_rounded),
              title: Text('Movimiento'),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        if (onDelete != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_rounded, color: AppColors.error),
              title: Text('Eliminar', style: TextStyle(color: AppColors.error)),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ],
    );
  }
}
