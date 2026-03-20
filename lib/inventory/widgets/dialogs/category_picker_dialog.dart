// lib/inventory/widgets/dialogs/category_picker_dialog.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_category.dart';
import '../../services/inventory_category_service.dart';
import '../cards/category_card.dart';
import '../common/inventory_loading.dart';
import '../common/inventory_empty_state.dart';

class CategoryPickerDialog extends StatefulWidget {
  final String? selectedCategoryId;
  final bool allowRoot;
  final String? excludeCategoryId;

  const CategoryPickerDialog({
    super.key,
    this.selectedCategoryId,
    this.allowRoot = true,
    this.excludeCategoryId,
  });

  static Future<InventoryCategory?> show(
    BuildContext context, {
    String? selectedCategoryId,
    bool allowRoot = true,
    String? excludeCategoryId,
  }) async {
    return showDialog<InventoryCategory>(
      context: context,
      builder: (_) => CategoryPickerDialog(
        selectedCategoryId: selectedCategoryId,
        allowRoot: allowRoot,
        excludeCategoryId: excludeCategoryId,
      ),
    );
  }

  @override
  State<CategoryPickerDialog> createState() => _CategoryPickerDialogState();
}

class _CategoryPickerDialogState extends State<CategoryPickerDialog> {
  final _searchController = TextEditingController();
  final _categoryService = InventoryCategoryService.instance;

  String? _selectedId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedCategoryId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Row(
                children: [
                  const Icon(Icons.category_rounded, color: AppColors.primary),
                  const SizedBox(width: AppDimensions.sm),
                  Text('Seleccionar Categoría', style: AppTextStyles.h3),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar categoría...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Categories list
            Expanded(
              child: StreamBuilder<List<InventoryCategory>>(
                stream: _categoryService.streamCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const InventoryLoading(
                      message: 'Cargando categorías...',
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  var categories = snapshot.data ?? [];

                  // Exclude specific category
                  if (widget.excludeCategoryId != null) {
                    categories = categories
                        .where((c) => c.id != widget.excludeCategoryId)
                        .toList();
                  }

                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    categories = categories.where((c) {
                      return c.name.toLowerCase().contains(query) ||
                          c.path.toLowerCase().contains(query);
                    }).toList();
                  }

                  if (categories.isEmpty) {
                    return InventoryEmptyState.categories();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return CategoryCard(
                        category: category,
                        compact: true,
                        isSelected: _selectedId == category.id,
                        showActions: false,
                        showItemCount: true,
                        onTap: () {
                          setState(() => _selectedId = category.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  FilledButton(
                    onPressed: _selectedId != null
                        ? () async {
                            final category = await _categoryService
                                .getCategoryById(_selectedId!);
                            if (!mounted) return;
                            Navigator.of(context).pop(category);
                          }
                        : null,
                    child: const Text('Seleccionar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
