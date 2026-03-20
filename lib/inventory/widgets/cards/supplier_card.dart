// lib/inventory/widgets/cards/supplier_card.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_supplier.dart';

class SupplierCard extends StatelessWidget {
  final InventorySupplier supplier;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;
  final bool showActions;
  final bool compact;
  final bool isSelected;

  const SupplierCard({
    super.key,
    required this.supplier,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onCall,
    this.onEmail,
    this.showActions = true,
    this.compact = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactCard();
    }
    return _buildFullCard();
  }

  Widget _buildFullCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo/Avatar
                  _buildAvatar(),
                  const SizedBox(width: AppDimensions.md),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                supplier.name,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (supplier.isPreferred)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 12,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Preferido',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          supplier.code,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  if (showActions) _buildPopupMenu(),
                ],
              ),
              const SizedBox(height: AppDimensions.md),

              // Status and type badges
              Row(
                children: [
                  _StatusBadge(status: supplier.status),
                  const SizedBox(width: AppDimensions.sm),
                  _TypeBadge(type: supplier.type),
                ],
              ),
              const SizedBox(height: AppDimensions.md),

              // Contact info
              if (supplier.email.isNotEmpty || supplier.phone != null)
                Wrap(
                  spacing: AppDimensions.md,
                  runSpacing: AppDimensions.sm,
                  children: [
                    if (supplier.email.isNotEmpty)
                      _ContactChip(
                        icon: Icons.email_rounded,
                        value: supplier.email,
                        onTap: onEmail,
                      ),
                    if (supplier.phone != null)
                      _ContactChip(
                        icon: Icons.phone_rounded,
                        value: supplier.phone!,
                        onTap: onCall,
                      ),
                  ],
                ),

              // Rating and stats
              if (supplier.rating != null || supplier.totalOrders != null) ...[
                const SizedBox(height: AppDimensions.md),
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.md),
                Row(
                  children: [
                    if (supplier.rating != null) ...[
                      _RatingDisplay(rating: supplier.rating!),
                      const SizedBox(width: AppDimensions.lg),
                    ],
                    if (supplier.totalOrders != null)
                      _StatItem(
                        label: 'Órdenes',
                        value: supplier.totalOrders.toString(),
                      ),
                    if (supplier.onTimeDeliveryRate != null) ...[
                      const SizedBox(width: AppDimensions.lg),
                      _StatItem(
                        label: 'A tiempo',
                        value:
                            '${supplier.onTimeDeliveryRate!.toStringAsFixed(0)}%',
                        valueColor: supplier.onTimeDeliveryRate! >= 90
                            ? AppColors.success
                            : supplier.onTimeDeliveryRate! >= 70
                            ? AppColors.warning
                            : AppColors.error,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.sm),
          child: Row(
            children: [
              _buildAvatar(size: 40),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      supplier.type.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (supplier.isPreferred)
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 20,
                )
              else
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

  Widget _buildAvatar({double size = 56}) {
    if (supplier.logoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Image.network(
          supplier.logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultAvatar(size),
        ),
      );
    }
    return _buildDefaultAvatar(size);
  }

  Widget _buildDefaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Icon(
        supplier.type.icon,
        color: AppColors.primary,
        size: size * 0.5,
      ),
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
          case 'call':
            onCall?.call();
            break;
          case 'email':
            onEmail?.call();
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
        if (onCall != null && supplier.phone != null)
          const PopupMenuItem(
            value: 'call',
            child: ListTile(
              leading: Icon(Icons.phone_rounded),
              title: Text('Llamar'),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        if (onEmail != null)
          const PopupMenuItem(
            value: 'email',
            child: ListTile(
              leading: Icon(Icons.email_rounded),
              title: Text('Enviar email'),
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

class _StatusBadge extends StatelessWidget {
  final SupplierStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: status.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final SupplierType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  const _ContactChip({required this.icon, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingDisplay extends StatelessWidget {
  final double rating;

  const _RatingDisplay({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final filled = index < rating.floor();
          final half = index == rating.floor() && rating % 1 >= 0.5;
          return Icon(
            half ? Icons.star_half_rounded : Icons.star_rounded,
            size: 16,
            color: filled || half ? AppColors.warning : AppColors.divider,
          );
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }
}
