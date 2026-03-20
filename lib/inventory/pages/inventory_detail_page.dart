// lib/inventory/pages/inventory_detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/inventory_item.dart';
import '../models/inventory_enums.dart';
import '../models/inventory_movement.dart';
import '../services/inventory_service.dart';
import '../services/inventory_movement_service.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/stock_indicator.dart';
import '../widgets/common/price_display.dart';
import '../widgets/common/image_gallery.dart';
import '../widgets/common/inventory_loading.dart';
import '../widgets/common/inventory_error_view.dart';
import '../widgets/dialogs/stock_movement_dialog.dart';
import 'inventory_form_page.dart';

class InventoryDetailPage extends StatefulWidget {
  final String itemId;

  const InventoryDetailPage({super.key, required this.itemId});

  @override
  State<InventoryDetailPage> createState() => _InventoryDetailPageState();
}

class _InventoryDetailPageState extends State<InventoryDetailPage>
    with SingleTickerProviderStateMixin {
  final _inventoryService = InventoryService.instance;
  final _movementService = InventoryMovementService.instance;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return StreamBuilder<InventoryItem?>(
      stream: _inventoryService.streamItem(widget.itemId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const InventoryLoading(message: 'Cargando item...'),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: InventoryErrorView.loadError(
              errorMessage: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            ),
          );
        }

        final item = snapshot.data;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: InventoryErrorView.notFound(
              itemType: 'Item',
              onRetry: () => Navigator.pop(context),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: isMobile ? _buildMobileLayout(item) : _buildDesktopLayout(item),
        );
      },
    );
  }

  Widget _buildMobileLayout(InventoryItem item) {
    return CustomScrollView(
      slivers: [
        // App bar con imagen
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(background: _buildHeaderImage(item)),
          actions: [_buildActionsMenu(item)],
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildHeaderInfo(item),
              const SizedBox(height: AppDimensions.md),

              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Detalles'),
                  Tab(text: 'Stock'),
                  Tab(text: 'Historial'),
                ],
              ),
            ],
          ),
        ),

        // Tab content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(item),
              _buildStockTab(item),
              _buildHistoryTab(item),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(InventoryItem item) {
    return Row(
      children: [
        // Left panel - Info
        Expanded(
          flex: 2,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(item.name),
                actions: [_buildActionsMenu(item)],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Image gallery
                    ImageGallery(
                      primaryImage: item.primaryImageUrl,
                      additionalImages: item.additionalImageUrls,
                      height: 300,
                    ),
                    const SizedBox(height: AppDimensions.lg),

                    // Header info
                    _buildHeaderInfo(item),
                    const SizedBox(height: AppDimensions.lg),

                    // Details
                    _buildDetailsSection(item),
                  ]),
                ),
              ),
            ],
          ),
        ),

        // Right panel - Stock & History
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(left: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Stock'),
                  Tab(text: 'Historial'),
                  Tab(text: 'Info'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStockTab(item),
                    _buildHistoryTab(item),
                    _buildMetadataTab(item),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderImage(InventoryItem item) {
    if (item.primaryImageUrl != null) {
      return Image.network(
        item.primaryImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(item),
      );
    }
    return _buildPlaceholderImage(item);
  }

  Widget _buildPlaceholderImage(InventoryItem item) {
    return Container(
      color: item.type.color.withOpacity(0.1),
      child: Center(
        child: Icon(
          item.type.icon,
          size: 80,
          color: item.type.color.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(InventoryItem item) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges
          Wrap(
            spacing: AppDimensions.sm,
            runSpacing: AppDimensions.sm,
            children: [
              StatusBadge.itemType(item.type),
              StatusBadge.itemStatus(item.status),
              if (item.isStockLow) StatusBadge.lowStock(),
              if (item.isExpired) StatusBadge.expired(),
              if (item.isFeatured)
                const StatusBadge(
                  label: 'Destacado',
                  color: AppColors.warning,
                  icon: Icons.star_rounded,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Name
          Text(
            item.name,
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.xs),

          // SKU
          Text(
            'SKU: ${item.sku}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // Price
          PriceDisplay(price: item.sellingPrice, currency: item.currency),
          const SizedBox(height: AppDimensions.sm),

          // Description
          if (item.description.isNotEmpty) ...[
            Text(
              item.description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab(InventoryItem item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: _buildDetailsSection(item),
    );
  }

  Widget _buildDetailsSection(InventoryItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pricing
        _DetailCard(
          title: 'Precios',
          icon: Icons.attach_money_rounded,
          child: PricePair(
            purchasePrice: item.purchasePrice,
            sellingPrice: item.sellingPrice,
            currency: item.currency,
          ),
        ),
        const SizedBox(height: AppDimensions.md),

        // Product details
        if (item.type == InventoryItemType.product) ...[
          _DetailCard(
            title: 'Información del Producto',
            icon: Icons.inventory_2_rounded,
            child: Column(
              children: [
                if (item.brand != null) _DetailRow('Marca', item.brand!),
                if (item.model != null) _DetailRow('Modelo', item.model!),
                if (item.manufacturer != null)
                  _DetailRow('Fabricante', item.manufacturer!),
                if (item.serialNumber != null)
                  _DetailRow('Número de serie', item.serialNumber!),
                if (item.barcode != null)
                  _DetailRow('Código de barras', item.barcode!),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.md),
        ],

        // Asset details
        if (item.type == InventoryItemType.asset) ...[
          _DetailCard(
            title: 'Información del Activo',
            icon: Icons.business_center_rounded,
            child: Column(
              children: [
                if (item.assetCondition != null)
                  _DetailRow('Condición', item.assetCondition!.label),
                if (item.purchaseDate != null)
                  _DetailRow(
                    'Fecha de compra',
                    DateFormat('dd/MM/yyyy').format(item.purchaseDate!),
                  ),
                if (item.warrantyExpiryDate != null)
                  _DetailRow(
                    'Vencimiento garantía',
                    DateFormat('dd/MM/yyyy').format(item.warrantyExpiryDate!),
                  ),
                if (item.assignedToUserId != null)
                  _DetailRow('Asignado a', item.assignedToUserId!),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.md),
        ],

        // Tags
        if (item.tags.isNotEmpty) ...[
          _DetailCard(
            title: 'Etiquetas',
            icon: Icons.label_rounded,
            child: Wrap(
              spacing: AppDimensions.xs,
              runSpacing: AppDimensions.xs,
              children: item.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockTab(InventoryItem item) {
    if (item.type == InventoryItemType.service) {
      return const Center(
        child: Text('Los servicios no tienen control de stock'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        children: [
          // Stock indicator
          StockIndicator(
            currentStock: item.stock,
            minStock: item.minStock,
            maxStock: item.maxStock,
          ),
          const SizedBox(height: AppDimensions.lg),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showStockMovement(item, isIn: true),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Entrada'),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showStockMovement(item, isIn: false),
                  icon: const Icon(Icons.remove_rounded),
                  label: const Text('Salida'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          // Stock info
          _DetailCard(
            title: 'Configuración de Stock',
            icon: Icons.settings_rounded,
            child: Column(
              children: [
                _DetailRow(
                  'Stock actual',
                  '${item.stock} ${item.unitOfMeasure.abbreviation}',
                ),
                _DetailRow('Stock mínimo', '${item.minStock}'),
                if (item.maxStock != null)
                  _DetailRow('Stock máximo', '${item.maxStock}'),
                if (item.reorderPoint != null)
                  _DetailRow('Punto de reorden', '${item.reorderPoint}'),
                _DetailRow(
                  'Valor en inventario',
                  NumberFormat.currency(
                    locale: 'es_MX',
                    symbol: '\$',
                  ).format(item.totalInventoryValue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(InventoryItem item) {
    return StreamBuilder<List<InventoryMovement>>(
      stream: _movementService.streamItemMovements(item.id, limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Sin movimientos registrados'));
        }

        final movements = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.md),
          itemCount: movements.length,
          itemBuilder: (context, index) {
            final movement = movements[index];
            return _MovementTile(movement: movement);
          },
        );
      },
    );
  }

  Widget _buildMetadataTab(InventoryItem item) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        children: [
          _DetailCard(
            title: 'Metadatos',
            icon: Icons.info_rounded,
            child: Column(
              children: [
                _DetailRow('ID', item.id),
                _DetailRow('SKU', item.sku),
                _DetailRow('Creado', dateFormat.format(item.createdAt)),
                _DetailRow('Actualizado', dateFormat.format(item.updatedAt)),
                _DetailRow('Creado por', item.createdBy),
                if (item.lastModifiedBy != null)
                  _DetailRow('Modificado por', item.lastModifiedBy!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(InventoryItem item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editItem(item);
            break;
          case 'movement':
            _showStockMovement(item);
            break;
          case 'duplicate':
            _duplicateItem(item);
            break;
          case 'delete':
            _deleteItem(item);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_rounded),
            title: Text('Editar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (item.type != InventoryItemType.service)
          const PopupMenuItem(
            value: 'movement',
            child: ListTile(
              leading: Icon(Icons.swap_horiz_rounded),
              title: Text('Movimiento'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem(
          value: 'duplicate',
          child: ListTile(
            leading: Icon(Icons.copy_rounded),
            title: Text('Duplicar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_rounded, color: AppColors.error),
            title: Text('Eliminar', style: TextStyle(color: AppColors.error)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _editItem(InventoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryFormPage(
          item: item,
          onSaved: () => Navigator.pop(context),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showStockMovement(InventoryItem item, {bool? isIn}) {
    StockMovementDialog.show(context, item: item);
  }

  void _duplicateItem(InventoryItem item) {
    // Navegar al formulario con datos pre-llenados
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryFormPage(
          duplicateFrom: item,
          onSaved: () => Navigator.pop(context),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _deleteItem(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar item'),
        content: Text('¿Estás seguro de eliminar "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _inventoryService.softDeleteItem(item.id);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final InventoryMovement movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppDimensions.sm),
        decoration: BoxDecoration(
          color: movement.type.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Icon(movement.type.icon, color: movement.type.color, size: 20),
      ),
      title: Text(
        movement.type.label,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${movement.reason}\n${dateFormat.format(movement.createdAt)}',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
      ),
      trailing: Text(
        '${movement.type.isIncoming ? '+' : '-'}${movement.quantity}',
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: movement.type.isIncoming ? AppColors.success : AppColors.error,
        ),
      ),
      isThreeLine: true,
    );
  }
}
