// lib/inventory/pages/inventory_dashboard_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import 'inventory_form_page.dart';

class InventoryDashboardPage extends StatefulWidget {
  final UserRole role;

  const InventoryDashboardPage({super.key, required this.role});

  @override
  State<InventoryDashboardPage> createState() => _InventoryDashboardPageState();
}

class _InventoryDashboardPageState extends State<InventoryDashboardPage> {
  final _inventoryService = InventoryService.instance;

  bool _isLoading = true;
  String? _error;

  // Stats
  int _totalItems = 0;
  int _totalProducts = 0;
  int _totalServices = 0;
  int _totalAssets = 0;
  int _lowStockItems = 0;
  double _totalValue = 0;

  List<CategoryStock> _categoryStock = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cargar estadísticas desde Firebase
      final stats = await _inventoryService.getStats();

      // ✅ AGREGAR: Cargar stock por categoría
      final categoryStock = await _inventoryService.getStockByCategory(
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _totalItems = stats.totalItems;
          _totalProducts = stats.totalProducts;
          _totalServices = stats.totalServices;
          _totalAssets = stats.totalAssets;
          _lowStockItems = stats.lowStockItems;
          _totalValue = stats.totalInventoryValue;
          _categoryStock = categoryStock; // ✅ AGREGAR
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando dashboard...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error al cargar datos', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsGrid(isMobile),
            const SizedBox(height: 32),
            _buildChartsSection(isMobile),
            const SizedBox(height: 32),
            _buildAlertsSection(),
            const SizedBox(height: 32),
            _buildRecentItems(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard de Inventario',
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumen general del inventario',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.role == UserRole.admin) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _navigateToForm,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nuevo Item'),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard de Inventario',
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Resumen general del inventario',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (widget.role == UserRole.admin)
          FilledButton.icon(
            onPressed: _navigateToForm,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nuevo Item'),
          ),
      ],
    );
  }

  void _navigateToForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryFormPage(
          onSaved: () {
            Navigator.pop(context);
            _loadData(); // Recargar datos después de guardar
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    final stats = [
      _StatData(
        'Total Items',
        _totalItems.toString(),
        Icons.inventory_2,
        AppColors.primary,
      ),
      _StatData(
        'Productos',
        _totalProducts.toString(),
        Icons.shopping_bag,
        AppColors.info,
      ),
      _StatData(
        'Servicios',
        _totalServices.toString(),
        Icons.build,
        AppColors.success,
      ),
      _StatData(
        'Activos',
        _totalAssets.toString(),
        Icons.devices,
        AppColors.warning,
      ),
      _StatData(
        'Stock Bajo',
        _lowStockItems.toString(),
        Icons.warning,
        AppColors.error,
      ),
      _StatData(
        'Valor Total',
        '\$${_totalValue.toStringAsFixed(0)}',
        Icons.attach_money,
        AppColors.primary,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(data: stats[0])),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(data: stats[4])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(data: stats[1])),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(data: stats[2])),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(data: stats[5]),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: stats
          .map((s) => SizedBox(width: 200, child: _StatCard(data: s)))
          .toList(),
    );
  }

  Widget _buildChartsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        if (isMobile)
          _buildDistributionCard()
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDistributionCard()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildCategoriesCard()),
            ],
          ),
      ],
    );
  }

  Widget _buildDistributionCard() {
    final items = [
      _DistributionItem('Productos', _totalProducts, AppColors.info),
      _DistributionItem('Servicios', _totalServices, AppColors.success),
      _DistributionItem('Activos', _totalAssets, AppColors.warning),
    ];

    final total = _totalProducts + _totalServices + _totalAssets;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por Tipo',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final percentage = total > 0 ? (item.value / total * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.label, style: AppTextStyles.bodySmall),
                      Text(
                        '${item.value} (${percentage.toStringAsFixed(1)}%)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? percentage / 100 : 0,
                      minHeight: 8,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
    // ✅ USAR DATOS REALES
    if (_categoryStock.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock por Categoría',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sin datos de categorías',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = _categoryStock
        .map((c) => c.totalStock)
        .reduce((a, b) => a > b ? a : b);

    // Colores para las categorías
    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      const Color(0xFF9C27B0),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock por Categoría',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Top ${_categoryStock.length} categorías',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          ..._categoryStock.asMap().entries.map((entry) {
            final index = entry.key;
            final cat = entry.value;
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cat.categoryName,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${cat.totalStock}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxValue > 0 ? cat.totalStock / maxValue : 0,
                      minHeight: 8,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_rounded,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Alertas',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Usar StreamBuilder para alertas en tiempo real
        StreamBuilder<List<InventoryItem>>(
          stream: _inventoryService.streamLowStockItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildAlertCard(
                icon: Icons.error_outline,
                color: AppColors.error,
                title: 'Error al cargar alertas',
                subtitle: snapshot.error.toString(),
              );
            }

            final lowStockItems = snapshot.data ?? [];

            if (lowStockItems.isEmpty) {
              return _buildAlertCard(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                title: 'Sin alertas',
                subtitle: 'Todos los niveles de stock están bien',
              );
            }

            return _buildAlertCard(
              icon: Icons.inventory_rounded,
              color: AppColors.warning,
              title: '${lowStockItems.length} items con stock bajo',
              subtitle: 'Requieren reposición pronto',
              items: lowStockItems.take(3).map((i) => i.name).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    List<String>? items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (items != null && items.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    items.join(', '),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Últimos items agregados',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navegar a lista de items
              },
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Usar StreamBuilder para items recientes
        StreamBuilder<List<InventoryItem>>(
          stream: _inventoryService.streamItems(
            filters: const InventoryFilters(
              sortBy: 'createdAt',
              sortDescending: true,
            ),
            limit: 5,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(height: 8),
                    Text(
                      'Error al cargar items',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              );
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: items.map((item) => _buildItemCard(item)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay items en el inventario',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.role == UserRole.admin) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _navigateToForm,
              icon: const Icon(Icons.add),
              label: const Text('Agregar primer item'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.type.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.type.icon, color: item.type.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          _buildStockBadge(item),
        ],
      ),
    );
  }

  Widget _buildStockBadge(InventoryItem item) {
    final isLowStock = item.stock <= item.stock;
    final color = isLowStock ? AppColors.error : AppColors.success;
    final bgColor = isLowStock ? AppColors.error : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Stock: ${item.stock}',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CLASES AUXILIARES
// ══════════════════════════════════════════════════════════════

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionItem {
  final String label;
  final int value;
  final Color color;

  const _DistributionItem(this.label, this.value, this.color);
}
