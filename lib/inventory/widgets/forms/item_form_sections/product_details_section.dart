// lib/inventory/widgets/forms/item_form_sections/product_details_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProductDetailsSection extends StatelessWidget {
  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController manufacturerController;
  final TextEditingController serialNumberController;
  final TextEditingController barcodeController;
  final TextEditingController weightController;
  final TextEditingController lengthController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final TextEditingController batchNumberController;
  final DateTime? expirationDate;
  final ValueChanged<DateTime?> onExpirationDateChanged;

  const ProductDetailsSection({
    super.key,
    required this.brandController,
    required this.modelController,
    required this.manufacturerController,
    required this.serialNumberController,
    required this.barcodeController,
    required this.weightController,
    required this.lengthController,
    required this.widthController,
    required this.heightController,
    required this.batchNumberController,
    required this.expirationDate,
    required this.onExpirationDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(
          icon: Icons.inventory_2_rounded,
          title: 'Detalles del Producto',
        ),
        const SizedBox(height: AppDimensions.lg),

        // Brand and Model
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: brandController,
                decoration: InputDecoration(
                  labelText: 'Marca',
                  hintText: 'Ej: Samsung, Apple...',
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
                  hintText: 'Ej: Galaxy S24, iPhone 15...',
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

        // Manufacturer
        TextFormField(
          controller: manufacturerController,
          decoration: InputDecoration(
            labelText: 'Fabricante',
            hintText: 'Nombre del fabricante',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.factory_rounded),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppDimensions.md),

        // Serial Number and Barcode
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: serialNumberController,
                decoration: InputDecoration(
                  labelText: 'Número de serie',
                  hintText: 'S/N único del producto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.tag_rounded),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: TextFormField(
                controller: barcodeController,
                decoration: InputDecoration(
                  labelText: 'Código de barras',
                  hintText: 'EAN, UPC, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    onPressed: () {
                      // TODO: Implementar escaneo de código
                    },
                    tooltip: 'Escanear código',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.lg),

        // Dimensions subsection
        Text(
          'Dimensiones y peso',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        // Weight
        TextFormField(
          controller: weightController,
          decoration: InputDecoration(
            labelText: 'Peso',
            hintText: '0.00',
            suffixText: 'kg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            prefixIcon: const Icon(Icons.scale_rounded),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
          ],
        ),
        const SizedBox(height: AppDimensions.md),

        // Dimensions (L x W x H)
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: lengthController,
                decoration: InputDecoration(
                  labelText: 'Largo',
                  hintText: '0',
                  suffixText: 'cm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.xs),
              child: Text('×'),
            ),
            Expanded(
              child: TextFormField(
                controller: widthController,
                decoration: InputDecoration(
                  labelText: 'Ancho',
                  hintText: '0',
                  suffixText: 'cm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.xs),
              child: Text('×'),
            ),
            Expanded(
              child: TextFormField(
                controller: heightController,
                decoration: InputDecoration(
                  labelText: 'Alto',
                  hintText: '0',
                  suffixText: 'cm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.lg),

        // Batch and expiration subsection
        Text(
          'Lote y vencimiento',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: batchNumberController,
                decoration: InputDecoration(
                  labelText: 'Número de lote',
                  hintText: 'Identificador del lote',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  prefixIcon: const Icon(Icons.inventory_rounded),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _DatePickerField(
                label: 'Fecha de vencimiento',
                value: expirationDate,
                onChanged: onExpirationDateChanged,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                icon: Icons.event_busy_rounded,
              ),
            ),
          ],
        ),

        // Warning if expiration is set
        if (expirationDate != null) ...[
          const SizedBox(height: AppDimensions.sm),
          _ExpirationWarning(expirationDate: expirationDate!),
        ],
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

class _ExpirationWarning extends StatelessWidget {
  final DateTime expirationDate;

  const _ExpirationWarning({required this.expirationDate});

  @override
  Widget build(BuildContext context) {
    final daysUntilExpiry = expirationDate.difference(DateTime.now()).inDays;
    final isExpired = daysUntilExpiry < 0;
    final isExpiringSoon = daysUntilExpiry >= 0 && daysUntilExpiry <= 30;

    if (!isExpired && !isExpiringSoon) return const SizedBox.shrink();

    final color = isExpired ? AppColors.error : AppColors.warning;
    final message = isExpired
        ? 'Este producto ya está vencido'
        : 'Este producto vence en $daysUntilExpiry días';

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
            isExpired ? Icons.error_rounded : Icons.warning_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: AppDimensions.sm),
          Text(message, style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
