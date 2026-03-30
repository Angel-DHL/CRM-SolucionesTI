// lib/inventory/widgets/forms/item_form_sections/basic_info_section.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../models/inventory_enums.dart';
import '../../../models/inventory_category.dart';
import '../../dialogs/category_picker_dialog.dart';

class BasicInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController skuController;
  final TextEditingController descriptionController;
  final InventoryItemType selectedType;
  final ValueChanged<InventoryItemType> onTypeChanged;
  final InventoryCategory? selectedCategory;
  final ValueChanged<InventoryCategory?> onCategoryChanged;
  final UnitOfMeasure selectedUnit;
  final ValueChanged<UnitOfMeasure> onUnitChanged;
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final bool isEditing;

  const BasicInfoSection({
    super.key,
    required this.nameController,
    required this.skuController,
    required this.descriptionController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.tags,
    required this.onTagsChanged,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(icon: Icons.info_rounded, title: 'Información Básica'),
        const SizedBox(height: AppDimensions.lg),

        // Item type selector
        Text('Tipo de item', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),
        Row(
          children: InventoryItemType.values.map((type) {
            final isSelected = selectedType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != InventoryItemType.values.last
                      ? AppDimensions.sm
                      : 0,
                ),
                child: _TypeCard(
                  type: type,
                  isSelected: isSelected,
                  onTap: () => onTypeChanged(type),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.lg),

        // Name field
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Nombre *',
            hintText: 'Nombre del ${selectedType.label.toLowerCase()}',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.inventory_2_rounded),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es requerido';
            }
            if (value.length > 200) {
              return 'El nombre no puede exceder 200 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.md),

        // SKU field
        TextFormField(
          controller: skuController,
          decoration: InputDecoration(
            labelText: 'SKU',
            hintText: isEditing ? 'No editable' : 'Automático si se deja vacío',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.qr_code_rounded),
          ),
          enabled: !isEditing,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: AppDimensions.md),

        // Category selector
        _CategorySelector(
          selectedCategory: selectedCategory,
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: AppDimensions.md),

        // Unit of measure
        DropdownButtonFormField<UnitOfMeasure>(
          value: selectedUnit,
          decoration: InputDecoration(
            labelText: 'Unidad de medida *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.straighten_rounded),
          ),
          items: UnitOfMeasure.values.map((unit) {
            return DropdownMenuItem(
              value: unit,
              child: Text('${unit.label} (${unit.abbreviation})'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onUnitChanged(value);
          },
        ),
        const SizedBox(height: AppDimensions.md),

        // Description
        TextFormField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: 'Descripción *',
            hintText: 'Describe el ${selectedType.label.toLowerCase()}...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La descripción es requerida';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.md),

        // Tags
        _TagsInput(tags: tags, onChanged: onTagsChanged),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppDimensions.sm),
        Text(
          title,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final InventoryItemType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? type.color.withOpacity(0.1) : AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isSelected ? type.color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type.icon,
                color: isSelected ? type.color : AppColors.textHint,
                size: 28,
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                type.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? type.color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final InventoryCategory? selectedCategory;
  final ValueChanged<InventoryCategory?> onChanged;

  const _CategorySelector({
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final category = await CategoryPickerDialog.show(
          context,
          selectedCategoryId: selectedCategory?.id,
        );
        if (category != null) {
          onChanged(category);
        }
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Categoría *',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          prefixIcon: selectedCategory != null
              ? Icon(
                  selectedCategory!.icon.icon,
                  color: selectedCategory!.color.color,
                )
              : const Icon(Icons.category_rounded),
          suffixIcon: const Icon(Icons.chevron_right_rounded),
        ),
        child: Text(
          selectedCategory?.name ?? 'Seleccionar categoría',
          style: TextStyle(
            color: selectedCategory != null
                ? AppColors.textPrimary
                : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _TagsInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  const _TagsInput({required this.tags, required this.onChanged});

  @override
  State<_TagsInput> createState() => _TagsInputState();
}

class _TagsInputState extends State<_TagsInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isNotEmpty && !widget.tags.contains(trimmed)) {
      widget.onChanged([...widget.tags, trimmed]);
    }
    _controller.clear();
  }

  void _removeTag(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Etiquetas', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),
        Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppDimensions.xs,
                runSpacing: AppDimensions.xs,
                children: [
                  ...widget.tags.map(
                    (tag) => Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              if (widget.tags.isNotEmpty)
                const SizedBox(height: AppDimensions.sm),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: 'Agregar etiqueta...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: AppDimensions.xs,
                  ),
                ),
                onSubmitted: _addTag,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'Presiona Enter para agregar etiquetas',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }
}
