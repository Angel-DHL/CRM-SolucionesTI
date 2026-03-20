// lib/inventory/widgets/dialogs/supplier_picker_dialog.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_supplier.dart';
import '../../services/inventory_supplier_service.dart';
import '../cards/supplier_card.dart';
import '../common/inventory_loading.dart';
import '../common/inventory_empty_state.dart';

class SupplierPickerDialog extends StatefulWidget {
  final String? selectedSupplierId;
  final bool showPreferredOnly;

  const SupplierPickerDialog({
    super.key,
    this.selectedSupplierId,
    this.showPreferredOnly = false,
  });

  static Future<InventorySupplier?> show(
    BuildContext context, {
    String? selectedSupplierId,
    bool showPreferredOnly = false,
  }) async {
    return showDialog<InventorySupplier>(
      context: context,
      builder: (_) => SupplierPickerDialog(
        selectedSupplierId: selectedSupplierId,
        showPreferredOnly: showPreferredOnly,
      ),
    );
  }

  @override
  State<SupplierPickerDialog> createState() => _SupplierPickerDialogState();
}

class _SupplierPickerDialogState extends State<SupplierPickerDialog> {
  final _searchController = TextEditingController();
  final _supplierService = InventorySupplierService.instance;

  String? _selectedId;
  String _searchQuery = '';
  bool _showPreferredOnly = false;
  SupplierType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedSupplierId;
    _showPreferredOnly = widget.showPreferredOnly;
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
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text('Seleccionar Proveedor', style: AppTextStyles.h3),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search and filters
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar proveedor...',
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
                  const SizedBox(height: AppDimensions.sm),

                  // Filters row
                  Row(
                    children: [
                      // Preferred filter
                      FilterChip(
                        avatar: const Icon(Icons.star_rounded, size: 16),
                        label: const Text('Preferidos'),
                        selected: _showPreferredOnly,
                        onSelected: (value) {
                          setState(() => _showPreferredOnly = value);
                        },
                      ),
                      const SizedBox(width: AppDimensions.sm),

                      // Type dropdown
                      Expanded(
                        child: DropdownButtonFormField<SupplierType?>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'Tipo',
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
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ...SupplierType.values.map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(type.icon, size: 16),
                                    const SizedBox(width: 8),
                                    Text(type.label),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedType = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Suppliers list
            Expanded(
              child: StreamBuilder<List<InventorySupplier>>(
                stream: _supplierService.streamSuppliers(
                  filters: SupplierFilters(
                    type: _selectedType,
                    isPreferred: _showPreferredOnly ? true : null,
                    status: SupplierStatus.active,
                  ),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const InventoryLoading(
                      message: 'Cargando proveedores...',
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  var suppliers = snapshot.data ?? [];

                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    suppliers = suppliers.where((s) {
                      return s.name.toLowerCase().contains(query) ||
                          s.code.toLowerCase().contains(query) ||
                          s.email.toLowerCase().contains(query) ||
                          (s.contactName?.toLowerCase().contains(query) ??
                              false);
                    }).toList();
                  }

                  if (suppliers.isEmpty) {
                    return InventoryEmptyState.suppliers();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                    ),
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = suppliers[index];
                      return SupplierCard(
                        supplier: supplier,
                        compact: true,
                        isSelected: _selectedId == supplier.id,
                        showActions: false,
                        onTap: () {
                          setState(() => _selectedId = supplier.id);
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
                            final supplier = await _supplierService
                                .getSupplierById(_selectedId!);
                            if (!mounted) return;
                            Navigator.of(context).pop(supplier);
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
