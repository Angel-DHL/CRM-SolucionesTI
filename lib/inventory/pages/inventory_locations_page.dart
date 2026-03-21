// lib/inventory/pages/inventory_locations_page.dart

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/inventory_location.dart';
import '../services/inventory_location_service.dart';
import '../widgets/cards/location_card.dart';
import '../widgets/forms/location_form.dart';
import '../widgets/dialogs/confirm_delete_dialog.dart';
import '../widgets/common/inventory_loading.dart';
import '../widgets/common/inventory_empty_state.dart';
import '../widgets/common/inventory_error_view.dart';

class InventoryLocationsPage extends StatefulWidget {
  final UserRole role;

  const InventoryLocationsPage({super.key, required this.role});

  @override
  State<InventoryLocationsPage> createState() => _InventoryLocationsPageState();
}

class _InventoryLocationsPageState extends State<InventoryLocationsPage> {
  final _locationService = InventoryLocationService.instance;

  String _searchQuery = '';
  LocationType? _selectedType;
  bool _showInactive = false;
  String? _selectedLocationId;

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
                    if (_selectedLocationId != null)
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
                      hintText: 'Buscar ubicación...',
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
                  onPressed: () => _showLocationForm(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: isMobile
                      ? const SizedBox.shrink()
                      : const Text('Nueva Ubicación'),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Filtros de tipo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: _selectedType == null,
                  onSelected: (_) => setState(() => _selectedType = null),
                ),
                const SizedBox(width: AppDimensions.xs),
                ...LocationType.values.map((type) {
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
                const SizedBox(width: AppDimensions.sm),
                FilterChip(
                  label: const Text('Inactivas'),
                  selected: _showInactive,
                  onSelected: (v) => setState(() => _showInactive = v),
                ),
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
    return StreamBuilder<List<InventoryLocation>>(
      stream: _locationService.streamLocations(
        filters: LocationFilters(
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          type: _selectedType,
          isActive: _showInactive ? null : true,
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InventoryLoading(message: 'Cargando ubicaciones...');
        }

        if (snapshot.hasError) {
          return InventoryErrorView.loadError(
            errorMessage: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        final locations = snapshot.data ?? [];

        if (locations.isEmpty) {
          return InventoryEmptyState.locations(
            onAddLocation: _isAdmin ? () => _showLocationForm(context) : null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.md),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return LocationCard(
                location: location,
                isSelected: _selectedLocationId == location.id,
                showActions: _isAdmin,
                onTap: () => setState(() => _selectedLocationId = location.id),
                onEdit: _isAdmin
                    ? () => _showLocationForm(context, location: location)
                    : null,
                onDelete: _isAdmin ? () => _confirmDelete(location) : null,
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
    return StreamBuilder<InventoryLocation?>(
      stream: _locationService.streamLocation(_selectedLocationId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const InventoryLoading(fullScreen: false);
        }
        final location = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Detalle', style: AppTextStyles.h4),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _selectedLocationId = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppDimensions.md),

              // Ícono y nombre
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
                      child: Icon(
                        location.type.icon,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      location.name,
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      location.code,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // Stats
              _DetailRow('Tipo', location.type.label),
              _DetailRow('Estado', location.isActive ? 'Activa' : 'Inactiva'),
              _DetailRow('Items almacenados', '${location.currentItemCount}'),
              if (location.maxCapacity != null)
                _DetailRow(
                  'Capacidad',
                  '${location.currentItemCount}/${location.maxCapacity} (${location.capacityUsedPercentage.toStringAsFixed(0)}%)',
                ),
              if (location.childLocationCount > 0)
                _DetailRow('Sub-ubicaciones', '${location.childLocationCount}'),
              if (location.fullAddress.isNotEmpty)
                _DetailRow('Dirección', location.fullAddress),

              const SizedBox(height: AppDimensions.lg),

              // Capacidad visual
              if (location.maxCapacity != null) ...[
                Text('Uso de capacidad', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppDimensions.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: location.capacityUsedPercentage / 100,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      location.isNearCapacity
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
              ],

              // Características
              Text('Características', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppDimensions.sm),
              Wrap(
                spacing: AppDimensions.sm,
                runSpacing: AppDimensions.sm,
                children: [
                  if (location.isShippingOrigin)
                    _FeatureChip(Icons.local_shipping_rounded, 'Envío'),
                  if (location.isPickupLocation)
                    _FeatureChip(Icons.store_rounded, 'Recogida'),
                  if (location.acceptsReturns)
                    _FeatureChip(Icons.keyboard_return_rounded, 'Devoluciones'),
                ],
              ),

              const SizedBox(height: AppDimensions.xl),

              // Acciones
              if (_isAdmin) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLocationForm(
                      context,
                      parentLocationId: location.id,
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text('Crear sub-ubicación'),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showLocationForm(context, location: location),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Editar ubicación'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════

  void _showLocationForm(
    BuildContext context, {
    InventoryLocation? location,
    String? parentLocationId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              location != null ? 'Editar Ubicación' : 'Nueva Ubicación',
            ),
          ),
          body: LocationForm(
            location: location,
            parentLocationId: parentLocationId,
            onSaved: () {
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    location != null
                        ? 'Ubicación actualizada'
                        : 'Ubicación creada',
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

  Future<void> _confirmDelete(InventoryLocation location) async {
    final canDelete = await _locationService.canDeleteLocation(location.id);

    if (!canDelete) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar: tiene sub-ubicaciones o items'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    await ConfirmDeleteDialog.show(
      context,
      title: 'Eliminar ubicación',
      message: '¿Estás seguro de eliminar esta ubicación?',
      itemName: location.name,
      onConfirm: () async {
        await _locationService.deleteLocation(location.id);
        if (mounted) {
          setState(() {
            if (_selectedLocationId == location.id) {
              _selectedLocationId = null;
            }
          });
        }
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: AppColors.primarySurface,
    );
  }
}
