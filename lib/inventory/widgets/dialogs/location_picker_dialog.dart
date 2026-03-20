// lib/inventory/widgets/dialogs/location_picker_dialog.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_location.dart';
import '../../services/inventory_location_service.dart';
import '../cards/location_card.dart';
import '../common/inventory_loading.dart';
import '../common/inventory_empty_state.dart';

class LocationPickerDialog extends StatefulWidget {
  final String? selectedLocationId;
  final String? excludeLocationId;
  final LocationType? filterType;

  const LocationPickerDialog({
    super.key,
    this.selectedLocationId,
    this.excludeLocationId,
    this.filterType,
  });

  static Future<InventoryLocation?> show(
    BuildContext context, {
    String? selectedLocationId,
    String? excludeLocationId,
    LocationType? filterType,
  }) async {
    return showDialog<InventoryLocation>(
      context: context,
      builder: (_) => LocationPickerDialog(
        selectedLocationId: selectedLocationId,
        excludeLocationId: excludeLocationId,
        filterType: filterType,
      ),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final _searchController = TextEditingController();
  final _locationService = InventoryLocationService.instance;

  String? _selectedId;
  String _searchQuery = '';
  LocationType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedLocationId;
    _selectedType = widget.filterType;
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text('Seleccionar Ubicación', style: AppTextStyles.h3),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search and filter
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar ubicación...',
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

                  // Type filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Todas'),
                          selected: _selectedType == null,
                          onSelected: (_) =>
                              setState(() => _selectedType = null),
                        ),
                        const SizedBox(width: AppDimensions.xs),
                        ...LocationType.values.map(
                          (type) => Padding(
                            padding: const EdgeInsets.only(
                              right: AppDimensions.xs,
                            ),
                            child: FilterChip(
                              avatar: Icon(type.icon, size: 16),
                              label: Text(type.label),
                              selected: _selectedType == type,
                              onSelected: (_) =>
                                  setState(() => _selectedType = type),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Locations list
            Expanded(
              child: StreamBuilder<List<InventoryLocation>>(
                stream: _locationService.streamLocations(
                  filters: LocationFilters(type: _selectedType),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const InventoryLoading(
                      message: 'Cargando ubicaciones...',
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  var locations = snapshot.data ?? [];

                  // Exclude specific location
                  if (widget.excludeLocationId != null) {
                    locations = locations
                        .where((l) => l.id != widget.excludeLocationId)
                        .toList();
                  }

                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    locations = locations.where((l) {
                      return l.name.toLowerCase().contains(query) ||
                          l.code.toLowerCase().contains(query) ||
                          l.fullAddress.toLowerCase().contains(query);
                    }).toList();
                  }

                  if (locations.isEmpty) {
                    return InventoryEmptyState.locations();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                    ),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      return LocationCard(
                        location: location,
                        compact: true,
                        isSelected: _selectedId == location.id,
                        showActions: false,
                        onTap: () {
                          setState(() => _selectedId = location.id);
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
                            final location = await _locationService
                                .getLocationById(_selectedId!);
                            if (!mounted) return;
                            Navigator.of(context).pop(location);
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
