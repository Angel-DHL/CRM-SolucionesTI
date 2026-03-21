// lib/inventory/pages/inventory_suppliers_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/inventory_supplier.dart';
import '../services/inventory_supplier_service.dart';
import '../widgets/cards/supplier_card.dart';
import '../widgets/forms/supplier_form.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/common/inventory_loading.dart';
import '../widgets/common/inventory_empty_state.dart';
import '../widgets/common/inventory_error_view.dart';

class InventorySuppliersPage extends StatefulWidget {
  final UserRole role;

  const InventorySuppliersPage({super.key, required this.role});

  @override
  State<InventorySuppliersPage> createState() => _InventorySuppliersPageState();
}

class _InventorySuppliersPageState extends State<InventorySuppliersPage> {
  final _supplierService = InventorySupplierService.instance;

  String _searchQuery = '';
  SupplierType? _selectedType;
  SupplierStatus _selectedStatus = SupplierStatus.active;
  bool _showPreferredOnly = false;
  String? _selectedSupplierId;

  bool get _isAdmin => widget.role == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        _buildToolbar(isMobile),
        Expanded(
          child: isMobile
              ? _buildList()
              : Row(
                  children: [
                    Expanded(flex: 3, child: _buildList()),
                    if (_selectedSupplierId != null)
                      Container(
                        width: 400,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            left: BorderSide(color: AppColors.divider),
                          ),
                        ),
                        child: _buildDetailPanel(),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TOOLBAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildToolbar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          // Fila 1: Búsqueda y botón crear
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar proveedor...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
              if (_isAdmin) ...[
                const SizedBox(width: AppDimensions.sm),
                FilledButton.icon(
                  onPressed: () => _showSupplierForm(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: isMobile
                      ? const SizedBox.shrink()
                      : const Text('Nuevo Proveedor'),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Fila 2: Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Estado
                ...SupplierStatus.values.map((status) {
                  final isSelected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppDimensions.xs),
                    child: FilterChip(
                      label: Text(status.label),
                      selected: isSelected,
                      selectedColor: status.color.withOpacity(0.2),
                      onSelected: (_) =>
                          setState(() => _selectedStatus = status),
                    ),
                  );
                }),

                const SizedBox(width: AppDimensions.sm),
                Container(width: 1, height: 24, color: AppColors.divider),
                const SizedBox(width: AppDimensions.sm),

                // Preferidos
                FilterChip(
                  avatar: const Icon(Icons.star_rounded, size: 16),
                  label: const Text('Preferidos'),
                  selected: _showPreferredOnly,
                  onSelected: (v) => setState(() => _showPreferredOnly = v),
                ),
                const SizedBox(width: AppDimensions.sm),

                // Tipo
                ...SupplierType.values.take(4).map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppDimensions.xs),
                    child: FilterChip(
                      avatar: Icon(type.icon, size: 16),
                      label: Text(type.label),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedType = isSelected ? null : type;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LISTA
  // ═══════════════════════════════════════════════════════════

  Widget _buildList() {
    return StreamBuilder<List<InventorySupplier>>(
      stream: _supplierService.streamSuppliers(
        filters: SupplierFilters(
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          status: _selectedStatus,
          type: _selectedType,
          isPreferred: _showPreferredOnly ? true : null,
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InventoryLoading(message: 'Cargando proveedores...');
        }

        if (snapshot.hasError) {
          return InventoryErrorView.loadError(
            errorMessage: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final suppliers = snapshot.data ?? [];

        if (suppliers.isEmpty) {
          return InventoryEmptyState.suppliers(
            onAddSupplier: _isAdmin ? () => _showSupplierForm(context) : null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.md),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return SupplierCard(
                supplier: supplier,
                isSelected: _selectedSupplierId == supplier.id,
                showActions: _isAdmin,
                onTap: () => setState(() => _selectedSupplierId = supplier.id),
                onEdit: _isAdmin
                    ? () => _showSupplierForm(context, supplier: supplier)
                    : null,
                onDelete: _isAdmin ? () => _confirmDelete(supplier) : null,
                onCall: supplier.phone != null
                    ? () => _launchPhone(supplier.phone!)
                    : null,
                onEmail: () => _launchEmail(supplier.email),
              );
            },
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PANEL DE DETALLE
  // ═══════════════════════════════════════════════════════════

  Widget _buildDetailPanel() {
    return StreamBuilder<InventorySupplier?>(
      stream: _supplierService.streamSupplier(_selectedSupplierId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const InventoryLoading(fullScreen: false);
        }
        final supplier = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cerrar
              Row(
                children: [
                  Text('Detalle', style: AppTextStyles.h4),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _selectedSupplierId = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppDimensions.md),

              // Info
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: supplier.logoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                              child: Image.network(
                                supplier.logoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  supplier.type.icon,
                                  color: AppColors.primary,
                                  size: 36,
                                ),
                              ),
                            )
                          : Icon(
                              supplier.type.icon,
                              color: AppColors.primary,
                              size: 36,
                            ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      supplier.name,
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      supplier.code,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // Datos
              _DetailStatRow(
                icon: Icons.email_rounded,
                label: 'Email',
                value: supplier.email,
              ),
              if (supplier.phone != null)
                _DetailStatRow(
                  icon: Icons.phone_rounded,
                  label: 'Teléfono',
                  value: supplier.phone!,
                ),
              _DetailStatRow(
                icon: Icons.payment_rounded,
                label: 'Términos de pago',
                value: supplier.paymentTerms.label,
              ),
              if (supplier.rating != null)
                _DetailStatRow(
                  icon: Icons.star_rounded,
                  label: 'Calificación',
                  value: '${supplier.rating!.toStringAsFixed(1)} / 5',
                  valueColor: AppColors.warning,
                ),
              if (supplier.onTimeDeliveryRate != null)
                _DetailStatRow(
                  icon: Icons.local_shipping_rounded,
                  label: 'Entrega a tiempo',
                  value: '${supplier.onTimeDeliveryRate!.toStringAsFixed(0)}%',
                  valueColor: supplier.onTimeDeliveryRate! >= 90
                      ? AppColors.success
                      : AppColors.warning,
                ),
              if (supplier.fullAddress.isNotEmpty)
                _DetailStatRow(
                  icon: Icons.location_on_rounded,
                  label: 'Dirección',
                  value: supplier.fullAddress,
                ),

              const SizedBox(height: AppDimensions.xl),

              // Acciones rápidas
              if (_isAdmin)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showSupplierForm(context, supplier: supplier),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar proveedor'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════

  void _showSupplierForm(BuildContext context, {InventorySupplier? supplier}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              supplier != null ? 'Editar Proveedor' : 'Nuevo Proveedor',
            ),
          ),
          body: SupplierForm(
            supplier: supplier,
            onSaved: () {
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    supplier != null
                        ? 'Proveedor actualizado'
                        : 'Proveedor creado',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            onCancel: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(InventorySupplier supplier) async {
    final canDelete = await _supplierService.canDeleteSupplier(supplier.id);

    if (!canDelete) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar: tiene productos asociados'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    await ConfirmDeleteDialog.show(
      context,
      title: 'Eliminar proveedor',
      message: '¿Estás seguro de eliminar este proveedor?',
      itemName: supplier.name,
      onConfirm: () async {
        await _supplierService.deleteSupplier(supplier.id);
        if (mounted) {
          setState(() {
            if (_selectedSupplierId == supplier.id) {
              _selectedSupplierId = null;
            }
          });
        }
      },
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _DetailStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _DetailStatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
