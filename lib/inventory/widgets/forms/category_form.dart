// lib/inventory/widgets/forms/category_form.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_category.dart';
import '../../services/inventory_category_service.dart';
import '../dialogs/category_picker_dialog.dart';

class CategoryForm extends StatefulWidget {
  final InventoryCategory? category;
  final String? parentCategoryId;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const CategoryForm({
    super.key,
    this.category,
    this.parentCategoryId,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _categoryService = InventoryCategoryService.instance;

  CategoryIcon _selectedIcon = CategoryIcon.category;
  CategoryColor _selectedColor = CategoryColor.blue;
  InventoryCategory? _parentCategory;
  bool _isActive = true;
  bool _allowProducts = true;
  bool _allowServices = true;
  bool _allowAssets = true;

  bool _isLoading = false;
  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
      _isActive = widget.category!.isActive;
      _allowProducts = widget.category!.allowProducts;
      _allowServices = widget.category!.allowServices;
      _allowAssets = widget.category!.allowAssets;
      _loadParentCategory(widget.category!.parentId);
    } else if (widget.parentCategoryId != null) {
      _loadParentCategory(widget.parentCategoryId);
    }
  }

  Future<void> _loadParentCategory(String? parentId) async {
    if (parentId == null) return;
    final parent = await _categoryService.getCategoryById(parentId);
    if (mounted) {
      setState(() => _parentCategory = parent);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final slug = InventoryCategory.generateSlug(_nameController.text);

      if (_isEditing) {
        final updated = widget.category!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          parentId: _parentCategory?.id,
          isActive: _isActive,
          allowProducts: _allowProducts,
          allowServices: _allowServices,
          allowAssets: _allowAssets,
          updatedAt: now,
        );

        await _categoryService.updateCategory(updated);
      } else {
        final newCategory = InventoryCategory(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          slug: slug,
          icon: _selectedIcon,
          color: _selectedColor,
          parentId: _parentCategory?.id,
          level: _parentCategory != null ? _parentCategory!.level + 1 : 0,
          path: slug,
          ancestorIds: const [],
          isActive: _isActive,
          allowProducts: _allowProducts,
          allowServices: _allowServices,
          allowAssets: _allowAssets,
          createdAt: now,
          updatedAt: now,
          createdBy: '',
        );

        await _categoryService.createCategory(newCategory);
      }

      if (!mounted) return;
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: _selectedColor.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(
                    _selectedIcon.icon,
                    color: _selectedColor.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Editar Categoría' : 'Nueva Categoría',
                        style: AppTextStyles.h3,
                      ),
                      if (_parentCategory != null)
                        Text(
                          'Subcategoría de: ${_parentCategory!.name}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Nombre de la categoría',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                prefixIcon: const Icon(Icons.label_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.md),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: 'Descripción de la categoría',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppDimensions.lg),

            // Parent category
            Text('Categoría padre', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppDimensions.sm),
            _ParentCategorySelector(
              selectedCategory: _parentCategory,
              excludeCategoryId: widget.category?.id,
              onChanged: (category) {
                setState(() => _parentCategory = category);
              },
            ),
            const SizedBox(height: AppDimensions.lg),

            // Icon selector
            Text('Ícono', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppDimensions.sm),
            _IconSelector(
              selectedIcon: _selectedIcon,
              onChanged: (icon) => setState(() => _selectedIcon = icon),
            ),
            const SizedBox(height: AppDimensions.lg),

            // Color selector
            Text('Color', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppDimensions.sm),
            _ColorSelector(
              selectedColor: _selectedColor,
              onChanged: (color) => setState(() => _selectedColor = color),
            ),
            const SizedBox(height: AppDimensions.lg),

            // Item types allowed
            Text('Tipos de items permitidos', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: AppDimensions.sm,
              children: [
                FilterChip(
                  label: const Text('Productos'),
                  selected: _allowProducts,
                  onSelected: (v) => setState(() => _allowProducts = v),
                  avatar: Icon(
                    Icons.inventory_2_rounded,
                    size: 18,
                    color: _allowProducts
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
                FilterChip(
                  label: const Text('Servicios'),
                  selected: _allowServices,
                  onSelected: (v) => setState(() => _allowServices = v),
                  avatar: Icon(
                    Icons.miscellaneous_services_rounded,
                    size: 18,
                    color: _allowServices
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
                FilterChip(
                  label: const Text('Activos'),
                  selected: _allowAssets,
                  onSelected: (v) => setState(() => _allowAssets = v),
                  avatar: Icon(
                    Icons.business_center_rounded,
                    size: 18,
                    color: _allowAssets
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Active switch
            SwitchListTile(
              title: const Text('Categoría activa'),
              subtitle: const Text(
                'Las categorías inactivas no aparecen en los selectores',
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppDimensions.xl),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : widget.onCancel,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppDimensions.md),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isLoading
                        ? 'Guardando...'
                        : _isEditing
                        ? 'Actualizar'
                        : 'Crear',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentCategorySelector extends StatelessWidget {
  final InventoryCategory? selectedCategory;
  final String? excludeCategoryId;
  final ValueChanged<InventoryCategory?> onChanged;

  const _ParentCategorySelector({
    this.selectedCategory,
    this.excludeCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final category = await CategoryPickerDialog.show(
          context,
          selectedCategoryId: selectedCategory?.id,
          excludeCategoryId: excludeCategoryId,
        );
        onChanged(category);
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            if (selectedCategory != null) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: selectedCategory!.color.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  selectedCategory!.icon.icon,
                  color: selectedCategory!.color.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Text(
                  selectedCategory!.name,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              IconButton(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ] else ...[
              const Icon(Icons.folder_open_rounded, color: AppColors.textHint),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Text(
                  'Sin categoría padre (categoría raíz)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconSelector extends StatelessWidget {
  final CategoryIcon selectedIcon;
  final ValueChanged<CategoryIcon> onChanged;

  const _IconSelector({required this.selectedIcon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: CategoryIcon.values.map((icon) {
        final isSelected = selectedIcon == icon;
        return InkWell(
          onTap: () => onChanged(icon),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon.icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  final CategoryColor selectedColor;
  final ValueChanged<CategoryColor> onChanged;

  const _ColorSelector({required this.selectedColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: CategoryColor.values.map((color) {
        final isSelected = selectedColor == color;
        return InkWell(
          onTap: () => onChanged(color),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                width: 3,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
