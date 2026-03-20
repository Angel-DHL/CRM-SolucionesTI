// lib/inventory/widgets/cards/category_card.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_category.dart';

class CategoryCard extends StatelessWidget {
  final InventoryCategory category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showItemCount;
  final bool isSelected;
  final bool compact;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.showItemCount = true,
    this.isSelected = false,
    this.compact = false,
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
          color: isSelected ? category.color.color : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: category.color.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(
                  category.icon.icon,
                  color: category.color.color,
                  size: 28,
                ),
              ),
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
                            category.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!category.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textHint.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Inactiva',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (category.description != null &&
                        category.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppDimensions.sm),
                    Row(
                      children: [
                        if (showItemCount) ...[
                          _InfoChip(
                            icon: Icons.inventory_2_rounded,
                            label: '${category.itemCount} items',
                          ),
                          const SizedBox(width: AppDimensions.sm),
                        ],
                        if (category.hasChildren)
                          _InfoChip(
                            icon: Icons.folder_rounded,
                            label:
                                '${category.childCategoryCount} subcategorías',
                          ),
                        if (category.parentId != null)
                          _InfoChip(
                            icon: Icons.subdirectory_arrow_right_rounded,
                            label: 'Nivel ${category.level}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (showActions)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textHint,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
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
                    if (onDelete != null) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        enabled:
                            category.itemCount == 0 && !category.hasChildren,
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_rounded,
                            color:
                                category.itemCount == 0 && !category.hasChildren
                                ? AppColors.error
                                : AppColors.textHint,
                          ),
                          title: Text(
                            'Eliminar',
                            style: TextStyle(
                              color:
                                  category.itemCount == 0 &&
                                      !category.hasChildren
                                  ? AppColors.error
                                  : AppColors.textHint,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
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
          color: isSelected ? category.color.color : AppColors.border,
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.color.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  category.icon.icon,
                  color: category.color.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showItemCount)
                      Text(
                        '${category.itemCount} items',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: category.color.color,
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

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
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar categorías en árbol
class CategoryTreeTile extends StatelessWidget {
  final InventoryCategory category;
  final List<InventoryCategory> children;
  final VoidCallback? onTap;
  final bool expanded;
  final VoidCallback? onExpandToggle;
  final bool isSelected;

  const CategoryTreeTile({
    super.key,
    required this.category,
    this.children = const [],
    this.onTap,
    this.expanded = false,
    this.onExpandToggle,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppDimensions.md + (category.level * 24.0),
              right: AppDimensions.md,
              top: AppDimensions.sm,
              bottom: AppDimensions.sm,
            ),
            child: Row(
              children: [
                if (children.isNotEmpty)
                  GestureDetector(
                    onTap: onExpandToggle,
                    child: Icon(
                      expanded
                          ? Icons.expand_more_rounded
                          : Icons.chevron_right_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: AppDimensions.xs),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: category.color.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    category.icon.icon,
                    color: category.color.color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    category.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${category.itemCount}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: AppDimensions.sm),
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (expanded && children.isNotEmpty)
          ...children.map(
            (child) => CategoryTreeTile(
              category: child,
              onTap: () {}, // Pass appropriate callback
            ),
          ),
      ],
    );
  }
}
