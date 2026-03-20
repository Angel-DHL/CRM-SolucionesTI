// lib/inventory/widgets/forms/item_form_sections/asset_details_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../models/inventory_enums.dart';

class AssetDetailsSection extends StatelessWidget {
  final TextEditingController serialNumberController;
  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController depreciationRateController;
  final AssetCondition selectedCondition;
  final ValueChanged<AssetCondition> onConditionChanged;
  final DateTime? purchaseDate;
  final ValueChanged<DateTime?> onPurchaseDateChanged;
  final DateTime? warrantyExpiryDate;
  final ValueChanged<DateTime?> onWarrantyExpiryDateChanged;
  final DateTime? lastMaintenanceDate;
  final ValueChanged<DateTime?> onLastMaintenanceDateChanged;
  final DateTime? nextMaintenanceDate;
  final ValueChanged<DateTime?> onNextMaintenanceDateChanged;
  final String? assignedToUserId;
  final ValueChanged<String?> onAssignedToChanged;

  const AssetDetailsSection({
    super.key,
    required this.serialNumberController,
    required this.brandController,
    required this.modelController,
    required this.depreciationRateController,
    required this.selectedCondition,
    required this.onConditionChanged,
    required this.purchaseDate,
    required this.onPurchaseDateChanged,
    required this.warrantyExpiryDate,
    required this.onWarrantyExpiryDateChanged,
    required this.lastMaintenanceDate,
    required this.onLastMaintenanceDateChanged,
    required this.nextMaintenanceDate,
    required this.onNextMaintenanceDateChanged,
    this.assignedToUserId,
    required this.onAssignedToChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(
          icon: Icons.business_center_rounded,
          title: 'Detalles del Activo',
        ),
        const SizedBox(height: AppDimensions.lg),

        // Condition selector
        Text('Condición del activo *', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          runSpacing: AppDimensions.sm,
          children: AssetCondition.values.map((condition) {
            final isSelected = selectedCondition == condition;
            return ChoiceChip(
              label: Text(condition.label),
              selected: isSelected,
              onSelected: (_) => onConditionChanged(condition),
              selectedColor: condition.color.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? condition.color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              avatar: isSelected
                  ? Icon(Icons.check_rounded, size: 16, color: condition.color)
                  : null,
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.lg),

        // Brand, Model, Serial
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: brandController,
                decoration: InputDecoration(
                  labelText: 'Marca',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.branding_watermark_rounded),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: TextFormField(
                controller: modelController,
                decoration: InputDecoration(
                  labelText: 'Modelo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.devices_rounded),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),

        TextFormField(
          controller: serialNumberController,
          decoration: InputDecoration(
            labelText: 'Número de serie *',
            hintText: 'Identificador único del activo',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.tag_rounded),
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El número de serie es requerido para activos';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.lg),

        // Purchase and warranty dates
        Text(
          'Compra y garantía',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        Row(
          children: [
            Expanded(
              child: _DatePickerField(
                label: 'Fecha de compra',
                value: purchaseDate,
                onChanged: onPurchaseDateChanged,
                lastDate: DateTime.now(),
                icon: Icons.shopping_cart_rounded,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _DatePickerField(
                label: 'Vencimiento garantía',
                value: warrantyExpiryDate,
                onChanged: onWarrantyExpiryDateChanged,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                icon: Icons.verified_user_rounded,
              ),
            ),
          ],
        ),

        // Warranty status indicator
        if (warrantyExpiryDate != null) ...[
          const SizedBox(height: AppDimensions.sm),
          _WarrantyStatusIndicator(warrantyDate: warrantyExpiryDate!),
        ],
        const SizedBox(height: AppDimensions.lg),

        // Maintenance dates
        Text(
          'Mantenimiento',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        Row(
          children: [
            Expanded(
              child: _DatePickerField(
                label: 'Último mantenimiento',
                value: lastMaintenanceDate,
                onChanged: onLastMaintenanceDateChanged,
                lastDate: DateTime.now(),
                icon: Icons.build_rounded,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _DatePickerField(
                label: 'Próximo mantenimiento',
                value: nextMaintenanceDate,
                onChanged: onNextMaintenanceDateChanged,
                firstDate: DateTime.now(),
                icon: Icons.event_rounded,
              ),
            ),
          ],
        ),

        // Maintenance alert
        if (nextMaintenanceDate != null) ...[
          const SizedBox(height: AppDimensions.sm),
          _MaintenanceAlert(nextDate: nextMaintenanceDate!),
        ],
        const SizedBox(height: AppDimensions.lg),

        // Depreciation
        Text(
          'Depreciación',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        TextFormField(
          controller: depreciationRateController,
          decoration: InputDecoration(
            labelText: 'Tasa de depreciación anual',
            hintText: 'Ej: 10 para 10% anual',
            suffixText: '% anual',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.trending_down_rounded),
            helperText: 'Porcentaje de depreciación por año',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),

        // Depreciation preview
        if (purchaseDate != null &&
            depreciationRateController.text.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.md),
          _DepreciationPreview(
            purchaseDate: purchaseDate!,
            depreciationRate:
                double.tryParse(depreciationRateController.text) ?? 0,
          ),
        ],

        const SizedBox(height: AppDimensions.lg),

        // Assignment (simplified - in real app would use user picker)
        Text(
          'Asignación',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        TextFormField(
          initialValue: assignedToUserId,
          decoration: InputDecoration(
            labelText: 'Asignado a',
            hintText: 'ID o email del usuario responsable',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.person_rounded),
            suffixIcon: IconButton(
              icon: const Icon(Icons.person_search_rounded),
              onPressed: () {
                // TODO: Implementar selector de usuarios
              },
              tooltip: 'Buscar usuario',
            ),
          ),
          onChanged: onAssignedToChanged,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

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
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final IconData icon;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.icon = Icons.calendar_today_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2000),
          lastDate: lastDate ?? DateTime(2100),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          prefixIcon: Icon(icon),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(
          value != null
              ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color: value != null ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _WarrantyStatusIndicator extends StatelessWidget {
  final DateTime warrantyDate;

  const _WarrantyStatusIndicator({required this.warrantyDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = warrantyDate.isBefore(now);
    final daysRemaining = warrantyDate.difference(now).inDays;
    final isExpiringSoon = !isExpired && daysRemaining <= 30;

    final color = isExpired
        ? AppColors.error
        : isExpiringSoon
        ? AppColors.warning
        : AppColors.success;

    final message = isExpired
        ? 'Garantía vencida'
        : isExpiringSoon
        ? 'Garantía vence en $daysRemaining días'
        : 'Garantía vigente ($daysRemaining días restantes)';

    final icon = isExpired
        ? Icons.cancel_rounded
        : isExpiringSoon
        ? Icons.warning_rounded
        : Icons.check_circle_rounded;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppDimensions.sm),
          Text(message, style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _MaintenanceAlert extends StatelessWidget {
  final DateTime nextDate;

  const _MaintenanceAlert({required this.nextDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPastDue = nextDate.isBefore(now);
    final daysUntil = nextDate.difference(now).inDays;
    final isDueSoon = !isPastDue && daysUntil <= 7;

    if (!isPastDue && !isDueSoon) return const SizedBox.shrink();

    final color = isPastDue ? AppColors.error : AppColors.warning;
    final message = isPastDue
        ? 'Mantenimiento vencido hace ${-daysUntil} días'
        : 'Mantenimiento programado en $daysUntil días';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isPastDue ? Icons.error_rounded : Icons.schedule_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepreciationPreview extends StatelessWidget {
  final DateTime purchaseDate;
  final double depreciationRate;

  const _DepreciationPreview({
    required this.purchaseDate,
    required this.depreciationRate,
  });

  @override
  Widget build(BuildContext context) {
    final yearsOwned = DateTime.now().difference(purchaseDate).inDays / 365;
    final totalDepreciation = (depreciationRate * yearsOwned).clamp(0, 100);
    final currentValue = 100 - totalDepreciation;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valor actual estimado',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: AppDimensions.xs),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: currentValue / 100,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      currentValue > 50 ? AppColors.success : AppColors.warning,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Text(
                '${currentValue.toStringAsFixed(1)}%',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Depreciación acumulada: ${totalDepreciation.toStringAsFixed(1)}% (${yearsOwned.toStringAsFixed(1)} años)',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
