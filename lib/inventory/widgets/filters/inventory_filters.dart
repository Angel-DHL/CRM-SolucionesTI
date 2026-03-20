// lib/inventory/widgets/filters/inventory_filters.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_enums.dart';
import '../../services/inventory_service.dart';

class InventoryFiltersSheet extends StatefulWidget {
  final InventoryFilters currentFilters;
  final Function(InventoryFilters) onApply;

  const InventoryFiltersSheet({
    super.key,
    required this.currentFilters,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required InventoryFilters currentFilters,
    required Function(InventoryFilters) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (_) => InventoryFiltersSheet(
        currentFilters: currentFilters,
        onApply: onApply,
      ),
    );
  }

  @override
  State<InventoryFiltersSheet> createState() => _InventoryFiltersSheetState();
}

class _InventoryFiltersSheetState extends State<InventoryFiltersSheet> {
  late InventoryFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  void _updateFilters(InventoryFilters Function(InventoryFilters) update) {
    setState(() => _filters = update(_filters));
  }

  void _clearAll() {
    setState(() => _filters = InventoryFilters.none);
  }

  void _apply() {
    widget.onApply(_filters);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: AppDimensions.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded),
                  const SizedBox(width: AppDimensions.sm),
                  Text('Filtros', style: AppTextStyles.h3),
                  const Spacer(),
                  if (_filters.hasFilters)
                    TextButton(
                      onPressed: _clearAll,
                      child: const Text('Limpiar'),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Filters content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppDimensions.lg),
                children: [
                  // Type filter
                  _FilterSection(
                    title: 'Tipo',
                    child: Wrap(
                      spacing: AppDimensions.sm,
                      children: InventoryItemType.values.map((type) {
                        final isSelected = _filters.type == type;
                        return FilterChip(
                          selected: isSelected,
                          onSelected: (_) {
                            _updateFilters(
                              (f) => f.copyWith(type: isSelected ? null : type),
                            );
                          },
                          avatar: Icon(type.icon, size: 18),
                          label: Text(type.label),
                          selectedColor: type.color.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                  ),

                  // Status filter
                  _FilterSection(
                    title: 'Estado',
                    child: Wrap(
                      spacing: AppDimensions.sm,
                      children: InventoryItemStatus.values.map((status) {
                        final isSelected = _filters.status == status;
                        return FilterChip(
                          selected: isSelected,
                          onSelected: (_) {
                            _updateFilters(
                              (f) => f.copyWith(
                                status: isSelected ? null : status,
                              ),
                            );
                          },
                          label: Text(status.label),
                          selectedColor: status.color.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                  ),

                  // Stock filter
                  _FilterSection(
                    title: 'Stock',
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('Solo stock bajo'),
                          subtitle: const Text('Items por debajo del mínimo'),
                          value: _filters.isStockLow ?? false,
                          onChanged: (value) {
                            _updateFilters(
                              (f) => f.copyWith(isStockLow: value),
                            );
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  // Special filters
                  _FilterSection(
                    title: 'Especiales',
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('Solo activos'),
                          value: _filters.isActive ?? false,
                          onChanged: (value) {
                            _updateFilters((f) => f.copyWith(isActive: value));
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Solo destacados'),
                          value: _filters.isFeatured ?? false,
                          onChanged: (value) {
                            _updateFilters(
                              (f) => f.copyWith(isFeatured: value),
                            );
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  // Price range
                  _FilterSection(
                    title: 'Rango de precio',
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Mínimo',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.md,
                                vertical: AppDimensions.sm,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final price = double.tryParse(value);
                              _updateFilters(
                                (f) => f.copyWith(minPrice: price),
                              );
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.sm,
                          ),
                          child: Text('-'),
                        ),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Máximo',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.md,
                                vertical: AppDimensions.sm,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final price = double.tryParse(value);
                              _updateFilters(
                                (f) => f.copyWith(maxPrice: price),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.xl),
                ],
              ),
            ),

            // Apply button
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  if (_filters.hasFilters)
                    Expanded(
                      child: Text(
                        '${_countActiveFilters()} filtros activos',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: _apply,
                    child: const Text('Aplicar filtros'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  int _countActiveFilters() {
    int count = 0;
    if (_filters.type != null) count++;
    if (_filters.status != null) count++;
    if (_filters.categoryId != null) count++;
    if (_filters.isStockLow == true) count++;
    if (_filters.isActive == true) count++;
    if (_filters.isFeatured == true) count++;
    if (_filters.minPrice != null) count++;
    if (_filters.maxPrice != null) count++;
    return count;
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          child,
        ],
      ),
    );
  }
}
