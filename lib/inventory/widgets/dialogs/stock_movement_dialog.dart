// lib/inventory/widgets/dialogs/stock_movement_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_item.dart';
import '../../models/inventory_enums.dart';
import '../../services/inventory_movement_service.dart';

class StockMovementDialog extends StatefulWidget {
  final InventoryItem item;
  final VoidCallback? onSuccess;

  const StockMovementDialog({super.key, required this.item, this.onSuccess});

  static Future<void> show(
    BuildContext context, {
    required InventoryItem item,
    VoidCallback? onSuccess,
  }) {
    return showDialog(
      context: context,
      builder: (_) => StockMovementDialog(item: item, onSuccess: onSuccess),
    );
  }

  @override
  State<StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<StockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  MovementType _selectedType = MovementType.purchase;
  bool _isLoading = false;

  final _movementService = InventoryMovementService.instance;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final quantity = int.parse(_quantityController.text);
      final reason = _reasonController.text.trim();
      final notes = _notesController.text.trim();

      if (_selectedType.isIncoming) {
        await _movementService.registerStockIn(
          itemId: widget.item.id,
          quantity: quantity,
          reason: reason,
          type: _selectedType,
          notes: notes.isNotEmpty ? notes : null,
        );
      } else {
        await _movementService.registerStockOut(
          itemId: widget.item.id,
          quantity: quantity,
          reason: reason,
          type: _selectedType,
          notes: notes.isNotEmpty ? notes : null,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Movimiento registrado: ${_selectedType.label}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Movimiento de Stock', style: AppTextStyles.h3),
                          Text(
                            widget.item.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),

                // Current stock info
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoColumn(
                        label: 'Stock Actual',
                        value: widget.item.stock.toString(),
                        color: widget.item.isStockLow
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      _InfoColumn(
                        label: 'Mínimo',
                        value: widget.item.minStock.toString(),
                      ),
                      if (widget.item.maxStock != null) ...[
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.divider,
                        ),
                        _InfoColumn(
                          label: 'Máximo',
                          value: widget.item.maxStock.toString(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),

                // Movement type
                Text('Tipo de movimiento', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppDimensions.sm),
                Wrap(
                  spacing: AppDimensions.sm,
                  runSpacing: AppDimensions.sm,
                  children: MovementType.values
                      .where((t) => t != MovementType.transfer)
                      .map(
                        (type) => _TypeChip(
                          type: type,
                          isSelected: _selectedType == type,
                          onSelected: () =>
                              setState(() => _selectedType = type),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppDimensions.lg),

                // Quantity
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    prefixIcon: Icon(
                      _selectedType.isIncoming
                          ? Icons.add_rounded
                          : Icons.remove_rounded,
                      color: _selectedType.color,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa la cantidad';
                    }
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return 'La cantidad debe ser mayor a 0';
                    }
                    if (!_selectedType.isIncoming && qty > widget.item.stock) {
                      return 'No hay suficiente stock (disponible: ${widget.item.stock})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.md),

                // Reason
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Razón',
                    hintText: 'Ej: Compra a proveedor, Venta, Ajuste...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la razón del movimiento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.md),

                // Notes (optional)
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Información adicional...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppDimensions.xl),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _selectedType.isIncoming
                                  ? Icons.add_rounded
                                  : Icons.remove_rounded,
                            ),
                      label: Text(
                        _isLoading
                            ? 'Procesando...'
                            : _selectedType.isIncoming
                            ? 'Registrar Entrada'
                            : 'Registrar Salida',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoColumn({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
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

class _TypeChip extends StatelessWidget {
  final MovementType type;
  final bool isSelected;
  final VoidCallback onSelected;

  const _TypeChip({
    required this.type,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      avatar: Icon(
        type.icon,
        size: 18,
        color: isSelected ? Colors.white : type.color,
      ),
      label: Text(type.label),
      selectedColor: type.color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
