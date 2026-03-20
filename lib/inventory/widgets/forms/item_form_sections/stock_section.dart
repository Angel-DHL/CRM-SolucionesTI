// lib/inventory/widgets/forms/item_form_sections/stock_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../models/inventory_location.dart';
import '../../dialogs/location_picker_dialog.dart';

class StockSection extends StatelessWidget {
  final TextEditingController stockController;
  final TextEditingController minStockController;
  final TextEditingController maxStockController;
  final TextEditingController reorderPointController;
  final InventoryLocation? selectedLocation;
  final ValueChanged<InventoryLocation?> onLocationChanged;
  final bool trackInventory;
  final ValueChanged<bool> onTrackInventoryChanged;
  final bool allowBackorder;
  final ValueChanged<bool> onAllowBackorderChanged;
  final bool isEditing;

  const StockSection({
    super.key,
    required this.stockController,
    required this.minStockController,
    required this.maxStockController,
    required this.reorderPointController,
    required this.selectedLocation,
    required this.onLocationChanged,
    required this.trackInventory,
    required this.onTrackInventoryChanged,
    required this.allowBackorder,
    required this.onAllowBackorderChanged,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _SectionHeader(
          icon: Icons.inventory_rounded,
          title: 'Stock e Inventario',
        ),
        const SizedBox(height: AppDimensions.lg),

        // Track inventory switch
        SwitchListTile(
          title: const Text('Rastrear inventario'),
          subtitle: const Text('Controlar entradas y salidas de stock'),
          value: trackInventory,
          onChanged: onTrackInventoryChanged,
          contentPadding: EdgeInsets.zero,
        ),

        if (trackInventory) ...[
          const Divider(height: AppDimensions.lg),

          // Stock initial (only for new items)
          if (!isEditing) ...[
            TextFormField(
              controller: stockController,
              decoration: InputDecoration(
                labelText: 'Stock inicial',
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                prefixIcon: const Icon(Icons.inventory_2_rounded),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AppDimensions.md),
          ],

          // Min and max stock
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: minStockController,
                  decoration: InputDecoration(
                    labelText: 'Stock mínimo *',
                    hintText: '5',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    helperText: 'Alerta de stock bajo',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: TextFormField(
                  controller: maxStockController,
                  decoration: InputDecoration(
                    labelText: 'Stock máximo',
                    hintText: 'Sin límite',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    helperText: 'Opcional',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Reorder point
          TextFormField(
            controller: reorderPointController,
            decoration: InputDecoration(
              labelText: 'Punto de reorden',
              hintText: 'Igual al stock mínimo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              prefixIcon: const Icon(Icons.notification_important_rounded),
              helperText: 'Notificar cuando alcance este nivel',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppDimensions.md),

          // Default location
          _LocationSelector(
            selectedLocation: selectedLocation,
            onChanged: onLocationChanged,
          ),
          const SizedBox(height: AppDimensions.md),

          // Allow backorder
          SwitchListTile(
            title: const Text('Permitir pedidos sin stock'),
            subtitle: const Text('Aceptar órdenes aunque no haya existencias'),
            value: allowBackorder,
            onChanged: onAllowBackorderChanged,
            contentPadding: EdgeInsets.zero,
          ),
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

class _LocationSelector extends StatelessWidget {
  final InventoryLocation? selectedLocation;
  final ValueChanged<InventoryLocation?> onChanged;

  const _LocationSelector({
    required this.selectedLocation,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final location = await LocationPickerDialog.show(
          context,
          selectedLocationId: selectedLocation?.id,
        );
        if (location != null) {
          onChanged(location);
        }
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ubicación predeterminada',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          prefixIcon: Icon(
            selectedLocation?.type.icon ?? Icons.location_on_rounded,
            color: selectedLocation != null ? AppColors.primary : null,
          ),
          suffixIcon: const Icon(Icons.chevron_right_rounded),
        ),
        child: Text(
          selectedLocation?.name ?? 'Seleccionar ubicación',
          style: TextStyle(
            color: selectedLocation != null
                ? AppColors.textPrimary
                : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
