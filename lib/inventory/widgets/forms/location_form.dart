// lib/inventory/widgets/forms/location_form.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_location.dart';
import '../../services/inventory_location_service.dart';
import '../dialogs/location_picker_dialog.dart';

class LocationForm extends StatefulWidget {
  final InventoryLocation? location;
  final String? parentLocationId;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;

  const LocationForm({
    super.key,
    this.location,
    this.parentLocationId,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = InventoryLocationService.instance;

  // Controllers
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerEmailController = TextEditingController();
  final _managerPhoneController = TextEditingController();
  final _maxCapacityController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();

  LocationType _selectedType = LocationType.warehouse;
  InventoryLocation? _parentLocation;
  bool _isActive = true;
  bool _acceptsReturns = true;
  bool _isShippingOrigin = false;
  bool _isPickupLocation = false;

  bool _isLoading = false;
  bool get _isEditing => widget.location != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.location != null) {
      final l = widget.location!;
      _nameController.text = l.name;
      _codeController.text = l.code;
      _descriptionController.text = l.description ?? '';
      _addressLine1Controller.text = l.addressLine1 ?? '';
      _addressLine2Controller.text = l.addressLine2 ?? '';
      _cityController.text = l.city ?? '';
      _stateController.text = l.state ?? '';
      _postalCodeController.text = l.postalCode ?? '';
      _countryController.text = l.country ?? '';
      _phoneController.text = l.phone ?? '';
      _managerNameController.text = l.managerName ?? '';
      _managerEmailController.text = l.managerEmail ?? '';
      _managerPhoneController.text = l.managerPhone ?? '';
      _maxCapacityController.text = l.maxCapacity?.toString() ?? '';
      _areaController.text = l.areaSquareMeters?.toString() ?? '';
      _notesController.text = l.notes ?? '';
      _selectedType = l.type;
      _isActive = l.isActive;
      _acceptsReturns = l.acceptsReturns;
      _isShippingOrigin = l.isShippingOrigin;
      _isPickupLocation = l.isPickupLocation;
      _loadParentLocation(l.parentId);
    } else if (widget.parentLocationId != null) {
      _loadParentLocation(widget.parentLocationId);
    }
  }

  Future<void> _loadParentLocation(String? parentId) async {
    if (parentId == null) return;
    final parent = await _locationService.getLocationById(parentId);
    if (mounted) {
      setState(() => _parentLocation = parent);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _managerNameController.dispose();
    _managerEmailController.dispose();
    _managerPhoneController.dispose();
    _maxCapacityController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      if (_isEditing) {
        final updated = widget.location!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          type: _selectedType,
          addressLine1: _addressLine1Controller.text.trim().isNotEmpty
              ? _addressLine1Controller.text.trim()
              : null,
          city: _cityController.text.trim().isNotEmpty
              ? _cityController.text.trim()
              : null,
          state: _stateController.text.trim().isNotEmpty
              ? _stateController.text.trim()
              : null,
          postalCode: _postalCodeController.text.trim().isNotEmpty
              ? _postalCodeController.text.trim()
              : null,
          country: _countryController.text.trim().isNotEmpty
              ? _countryController.text.trim()
              : null,
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          managerName: _managerNameController.text.trim().isNotEmpty
              ? _managerNameController.text.trim()
              : null,
          managerEmail: _managerEmailController.text.trim().isNotEmpty
              ? _managerEmailController.text.trim()
              : null,
          maxCapacity: int.tryParse(_maxCapacityController.text),
          areaSquareMeters: double.tryParse(_areaController.text),
          isActive: _isActive,
          acceptsReturns: _acceptsReturns,
          isShippingOrigin: _isShippingOrigin,
          isPickupLocation: _isPickupLocation,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          updatedAt: now,
        );

        await _locationService.updateLocation(updated);
      } else {
        final newLocation = InventoryLocation(
          id: '',
          parentId: _parentLocation?.id,
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          type: _selectedType,
          addressLine1: _addressLine1Controller.text.trim().isNotEmpty
              ? _addressLine1Controller.text.trim()
              : null,
          addressLine2: _addressLine2Controller.text.trim().isNotEmpty
              ? _addressLine2Controller.text.trim()
              : null,
          city: _cityController.text.trim().isNotEmpty
              ? _cityController.text.trim()
              : null,
          state: _stateController.text.trim().isNotEmpty
              ? _stateController.text.trim()
              : null,
          postalCode: _postalCodeController.text.trim().isNotEmpty
              ? _postalCodeController.text.trim()
              : null,
          country: _countryController.text.trim().isNotEmpty
              ? _countryController.text.trim()
              : null,
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          managerName: _managerNameController.text.trim().isNotEmpty
              ? _managerNameController.text.trim()
              : null,
          managerEmail: _managerEmailController.text.trim().isNotEmpty
              ? _managerEmailController.text.trim()
              : null,
          managerPhone: _managerPhoneController.text.trim().isNotEmpty
              ? _managerPhoneController.text.trim()
              : null,
          maxCapacity: int.tryParse(_maxCapacityController.text),
          areaSquareMeters: double.tryParse(_areaController.text),
          isActive: _isActive,
          acceptsReturns: _acceptsReturns,
          isShippingOrigin: _isShippingOrigin,
          isPickupLocation: _isPickupLocation,
          level: _parentLocation != null ? _parentLocation!.level + 1 : 0,
          path: _codeController.text.trim(),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          createdAt: now,
          updatedAt: now,
          createdBy: '',
        );

        await _locationService.createLocation(newLocation);
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
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(
                    _selectedType.icon,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Editar Ubicación' : 'Nueva Ubicación',
                        style: AppTextStyles.h3,
                      ),
                      if (_parentLocation != null)
                        Text(
                          'Sub-ubicación de: ${_parentLocation!.name}',
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

            // Type selector
            Text('Tipo de ubicación *', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: AppDimensions.sm,
              runSpacing: AppDimensions.sm,
              children: LocationType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedType = type),
                  avatar: Icon(type.icon, size: 18),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimensions.lg),

            // Name and code
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
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
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Código',
                      hintText: 'Auto',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                    ),
                    enabled: !_isEditing,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppDimensions.lg),

            // Parent location
            Text('Ubicación padre', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppDimensions.sm),
            _ParentLocationSelector(
              selectedLocation: _parentLocation,
              excludeLocationId: widget.location?.id,
              onChanged: (location) {
                setState(() => _parentLocation = location);
              },
            ),
            const SizedBox(height: AppDimensions.lg),

            // Address section
            Text('Dirección', style: AppTextStyles.h4),
            const SizedBox(height: AppDimensions.md),

            TextFormField(
              controller: _addressLine1Controller,
              decoration: InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                prefixIcon: const Icon(Icons.location_on_rounded),
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'Ciudad',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Capacity
            Text('Capacidad', style: AppTextStyles.h4),
            const SizedBox(height: AppDimensions.md),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxCapacityController,
                    decoration: InputDecoration(
                      labelText: 'Capacidad máxima',
                      suffixText: 'unidades',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.inventory_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: InputDecoration(
                      labelText: 'Área',
                      suffixText: 'm²',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      prefixIcon: const Icon(Icons.square_foot_rounded),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Features
            Text('Características', style: AppTextStyles.h4),
            const SizedBox(height: AppDimensions.md),

            SwitchListTile(
              title: const Text('Ubicación activa'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Acepta devoluciones'),
              value: _acceptsReturns,
              onChanged: (v) => setState(() => _acceptsReturns = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Punto de envío'),
              subtitle: const Text('Puede enviar productos a clientes'),
              value: _isShippingOrigin,
              onChanged: (v) => setState(() => _isShippingOrigin = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Punto de recogida'),
              subtitle: const Text('Clientes pueden recoger aquí'),
              value: _isPickupLocation,
              onChanged: (v) => setState(() => _isPickupLocation = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppDimensions.lg),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
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

class _ParentLocationSelector extends StatelessWidget {
  final InventoryLocation? selectedLocation;
  final String? excludeLocationId;
  final ValueChanged<InventoryLocation?> onChanged;

  const _ParentLocationSelector({
    this.selectedLocation,
    this.excludeLocationId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final location = await LocationPickerDialog.show(
          context,
          selectedLocationId: selectedLocation?.id,
          excludeLocationId: excludeLocationId,
        );
        onChanged(location);
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
            if (selectedLocation != null) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  selectedLocation!.type.icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedLocation!.name,
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      selectedLocation!.code,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ] else ...[
              const Icon(Icons.location_off_rounded, color: AppColors.textHint),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Text(
                  'Sin ubicación padre (ubicación raíz)',
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
