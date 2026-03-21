// lib/inventory/pages/inventory_movements_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/inventory_enums.dart';
import '../models/inventory_movement.dart';
import '../services/inventory_movement_service.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/inventory_loading.dart';
import '../widgets/common/inventory_empty_state.dart';
import '../widgets/common/inventory_error_view.dart';

class InventoryMovementsPage extends StatefulWidget {
  final UserRole role;
  final String? itemId; // Si viene de un item específico

  const InventoryMovementsPage({super.key, required this.role, this.itemId});

  @override
  State<InventoryMovementsPage> createState() => _InventoryMovementsPageState();
}

class _InventoryMovementsPageState extends State<InventoryMovementsPage> {
  final _movementService = InventoryMovementService.instance;
  final _dateFormat = DateFormat('dd/MM/yyyy', 'es_MX');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es_MX');

  MovementType? _selectedType;
  MovementStatus? _selectedStatus;
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  String? _selectedMovementId;

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
                    if (_selectedMovementId != null)
                      Container(
                        width: 420,
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
          // Búsqueda + rango de fechas
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
                      hintText: 'Buscar por item, número...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),

              // Rango de fechas
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_rounded, size: 18),
                label: Text(
                  _dateRange != null
                      ? '${_dateFormat.format(_dateRange!.start)} - ${_dateFormat.format(_dateRange!.end)}'
                      : 'Fechas',
                ),
              ),

              if (_dateRange != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => setState(() => _dateRange = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Chips de tipo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _selectedType == null,
                  onSelected: (_) => setState(() => _selectedType = null),
                ),
                const SizedBox(width: AppDimensions.xs),
                ...MovementType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppDimensions.xs),
                    child: FilterChip(
                      avatar: Icon(type.icon, size: 16),
                      label: Text(type.label),
                      selected: isSelected,
                      selectedColor: type.color.withOpacity(0.2),
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
    return StreamBuilder<List<InventoryMovement>>(
      stream: _movementService.streamMovements(
        type: _selectedType,
        status: _selectedStatus,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        limit: 100,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InventoryLoading(message: 'Cargando movimientos...');
        }

        if (snapshot.hasError) {
          return InventoryErrorView.loadError(
            errorMessage: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        var movements = snapshot.data ?? [];

        // Filtro de búsqueda en cliente
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          movements = movements.where((m) {
            return m.itemName.toLowerCase().contains(q) ||
                m.movementNumber.toLowerCase().contains(q) ||
                m.reason.toLowerCase().contains(q) ||
                m.itemSku.toLowerCase().contains(q);
          }).toList();
        }

        // Filtro por item específico
        if (widget.itemId != null) {
          movements = movements
              .where((m) => m.itemId == widget.itemId)
              .toList();
        }

        if (movements.isEmpty) {
          return InventoryEmptyState.movements();
        }

        // Agrupar por fecha
        final grouped = _groupByDate(movements);

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.md),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              return _buildDateGroup(entry.key, entry.value);
            },
          ),
        );
      },
    );
  }

  Map<String, List<InventoryMovement>> _groupByDate(
    List<InventoryMovement> movements,
  ) {
    final grouped = <String, List<InventoryMovement>>{};
    for (final m in movements) {
      final dateKey = _dateFormat.format(m.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(m);
    }
    return grouped;
  }

  Widget _buildDateGroup(String dateLabel, List<InventoryMovement> movements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Separador de fecha
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  dateLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(child: Divider(color: AppColors.divider)),
              Text(
                '${movements.length} movimientos',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),

        // Movimientos del día
        ...movements.map(
          (m) => _MovementCard(
            movement: m,
            isSelected: _selectedMovementId == m.id,
            onTap: () => setState(() => _selectedMovementId = m.id),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PANEL DE DETALLE
  // ═══════════════════════════════════════════════════════════

  Widget _buildDetailPanel() {
    return FutureBuilder<InventoryMovement?>(
      future: _movementService.getMovementById(_selectedMovementId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const InventoryLoading(fullScreen: false);
        }
        final movement = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Detalle del Movimiento', style: AppTextStyles.h4),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _selectedMovementId = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppDimensions.md),

              // Tipo y estado
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: movement.type.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: Icon(
                        movement.type.icon,
                        color: movement.type.color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(movement.type.label, style: AppTextStyles.h3),
                    Text(
                      movement.movementNumber,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    StatusBadge.movementStatus(movement.status),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // Cantidad
              Container(
                padding: const EdgeInsets.all(AppDimensions.lg),
                decoration: BoxDecoration(
                  color: movement.type.isIncoming
                      ? AppColors.success.withOpacity(0.05)
                      : AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: movement.type.isIncoming
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.error.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn('Anterior', '${movement.previousStock}'),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textHint,
                    ),
                    _StatColumn(
                      movement.type.isIncoming ? 'Entrada' : 'Salida',
                      '${movement.type.isIncoming ? "+" : "-"}${movement.quantity}',
                      color: movement.type.isIncoming
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textHint,
                    ),
                    _StatColumn('Nuevo', '${movement.newStock}'),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.lg),

              // Info
              _InfoRow('Item', movement.itemName),
              _InfoRow('SKU', movement.itemSku),
              _InfoRow('Razón', movement.reason),
              _InfoRow('Fecha', _dateTimeFormat.format(movement.createdAt)),
              if (movement.notes != null) _InfoRow('Notas', movement.notes!),
              if (movement.supplierName != null)
                _InfoRow('Proveedor', movement.supplierName!),
              if (movement.customerName != null)
                _InfoRow('Cliente', movement.customerName!),
              if (movement.referenceNumber != null)
                _InfoRow('Referencia', movement.referenceNumber!),
              if (movement.createdByEmail != null)
                _InfoRow('Creado por', movement.createdByEmail!),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════

class _MovementCard extends StatelessWidget {
  final InventoryMovement movement;
  final bool isSelected;
  final VoidCallback onTap;

  const _MovementCard({
    required this.movement,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isSelected ? movement.type.color : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              // Ícono
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: movement.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  movement.type.icon,
                  color: movement.type.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppDimensions.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            movement.itemName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeFormat.format(movement.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        StatusBadge.movementType(movement.type),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: Text(
                            movement.reason,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textHint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.md),

              // Cantidad
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${movement.type.isIncoming ? "+" : "-"}${movement.quantity}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: movement.type.isIncoming
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                  Text(
                    '→ ${movement.newStock}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatColumn(this.label, this.value, {this.color});

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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
