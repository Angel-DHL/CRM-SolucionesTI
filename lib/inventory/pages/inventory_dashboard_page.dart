// lib/inventory/pages/inventory_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/inventory_enums.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';
import '../widgets/cards/inventory_stat_card.dart';
import '../widgets/cards/inventory_item_card.dart';
import '../widgets/charts/inventory_pie_chart.dart';
import '../widgets/charts/stock_bar_chart.dart';
import '../widgets/common/inventory_loading.dart';
import '../widgets/common/inventory_empty_state.dart';
import '../widgets/common/inventory_error_view.dart';
import 'inventory_detail_page.dart';
import 'inventory_form_page.dart';

class InventoryDashboardPage extends StatefulWidget {
  final UserRole role;

  const InventoryDashboardPage({super.key, required this.role});

  @override
  State<InventoryDashboardPage> createState() => _InventoryDashboardPageState();
}

class _InventoryDashboardPageState extends State<InventoryDashboardPage> {
  final _inventoryService = InventoryService.instance;
  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: FutureBuilder<InventoryStats>(
        future: _inventoryService.getStats(),
        builder: (context, statsSnapshot) {
          if (statsSnapshot.connectionState == ConnectionState.waiting) {
            return const InventoryLoading(message: 'Cargando dashboard...');
          }

          if (statsSnapshot.hasError) {
            return InventoryErrorView.loadError(
              errorMessage: statsSnapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          final stats = statsSnapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(
              isMobile ? AppDimensions.md : AppDimensions.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(stats),
                const SizedBox(height: AppDimensions.lg),

                // Stats cards
                _buildStatsGrid(stats, isMobile),
                const SizedBox(height: AppDimensions.xl),

                // Charts row
                if (!isMobile) ...[
                  _buildChartsRow(stats),
                  const SizedBox(height: AppDimensions.xl),
                ] else ...[
                  _buildChartsMobile(stats),
                  const SizedBox(height: AppDimensions.xl),
                ],

                // Alerts section
                _buildAlertsSection(),
                const SizedBox(height: AppDimensions.xl),

                // Recent items
                _buildRecentItemsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(InventoryStats stats) {
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
              const SizedBox(height: AppDimensions.xs),
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
            onPressed: () => _showCreateItemDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nuevo Item'),
          ),
      ],
    );
  }

  Widget _buildStatsGrid(InventoryStats stats, bool isMobile) {
    final cards = [
      InventoryStatCard.totalItems(stats.totalItems),
      InventoryStatCard.products(stats.totalProducts),
      InventoryStatCard.services(stats.totalServices),
      InventoryStatCard.assets(stats.totalAssets),
      InventoryStatCard.lowStock(stats.lowStockItems),
      InventoryStatCard.totalValue(stats.totalInventoryValue),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: AppDimensions.md),
              Expanded(child: cards[4]),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(child: cards[1]),
              const SizedBox(width: AppDimensions.md),
              Expanded(child: cards[2]),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          cards[5],
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppDimensions.md,
        mainAxisSpacing: AppDimensions.md,
        childAspectRatio: 1.8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildChartsRow(InventoryStats stats) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pie chart - Distribution by type
        Expanded(
          child: _ChartCard(
            title: 'Distribución por Tipo',
            child: InventoryPieChart(
              data: {
                InventoryItemType.product: stats.totalProducts,
                InventoryItemType.service: stats.totalServices,
                InventoryItemType.asset: stats.totalAssets,
              },
              size: 180,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.lg),

        // Bar chart - Top categories
        Expanded(
          flex: 2,
          child: _ChartCard(
            title: 'Stock por Categoría',
            subtitle: 'Top 5 categorías',
            child: FutureBuilder<List<StockBarData>>(
              future: _getTopCategoriesData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StockBarChart(data: snapshot.data!, height: 200);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartsMobile(InventoryStats stats) {
    return Column(
      children: [
        _ChartCard(
          title: 'Distribución por Tipo',
          child: InventoryPieChart(
            data: {
              InventoryItemType.product: stats.totalProducts,
              InventoryItemType.service: stats.totalServices,
              InventoryItemType.asset: stats.totalAssets,
            },
            size: 150,
          ),
        ),
      ],
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
            const SizedBox(width: AppDimensions.sm),
            Text(
              'Alertas',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),

        // Low stock items
        StreamBuilder<List<InventoryItem>>(
          stream: _inventoryService.streamLowStockItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _AlertCard(
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
                title: 'Sin alertas',
                subtitle: 'Todos los niveles de stock están bien',
              );
            }

            final lowStockItems = snapshot.data!;
            return _AlertCard(
              icon: Icons.inventory_rounded,
              iconColor: AppColors.warning,
              title: '${lowStockItems.length} items con stock bajo',
              subtitle: 'Requieren reposición pronto',
              onTap: () {
                // Navegar a lista filtrada
              },
              items: lowStockItems.take(3).map((item) => item.name).toList(),
            );
          },
        ),
        const SizedBox(height: AppDimensions.md),

        // Expiring items
        FutureBuilder<List<InventoryItem>>(
          future: _inventoryService.getExpiringItems(daysAhead: 30),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final expiringItems = snapshot.data!;
            return _AlertCard(
              icon: Icons.event_busy_rounded,
              iconColor: AppColors.error,
              title: '${expiringItems.length} items próximos a vencer',
              subtitle: 'Vencen en los próximos 30 días',
              onTap: () {
                // Navegar a lista filtrada
              },
              items: expiringItems.take(3).map((item) => item.name).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentItemsSection() {
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
                // Cambiar a vista de lista
              },
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),

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
              return const InventoryCardSkeleton(count: 3);
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return InventoryEmptyState.items(
                onAddItem: widget.role == UserRole.admin
                    ? _showCreateItemDialog
                    : null,
              );
            }

            return Column(
              children: snapshot.data!.map((item) {
                return InventoryItemCard(
                  item: item,
                  compact: true,
                  onTap: () => _navigateToDetail(item),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<List<StockBarData>> _getTopCategoriesData() async {
    // En producción, esto vendría del servicio
    // Por ahora retornamos datos de ejemplo
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      const StockBarData(
        label: 'Electrónica',
        shortLabel: 'Elec',
        value: 45,
        color: AppColors.primary,
      ),
      const StockBarData(
        label: 'Oficina',
        shortLabel: 'Ofic',
        value: 32,
        color: AppColors.info,
      ),
      const StockBarData(
        label: 'Herramientas',
        shortLabel: 'Herr',
        value: 28,
        color: AppColors.success,
      ),
      const StockBarData(
        label: 'Software',
        shortLabel: 'Soft',
        value: 15,
        color: AppColors.warning,
      ),
      const StockBarData(
        label: 'Otros',
        shortLabel: 'Otros',
        value: 10,
        color: AppColors.textHint,
      ),
    ];
  }

  void _showCreateItemDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryFormPage(
          onSaved: () {
            Navigator.pop(context);
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _navigateToDetail(InventoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InventoryDetailPage(itemId: item.id)),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _ChartCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded),
                color: AppColors.textHint,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          child,
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final List<String>? items;

  const _AlertCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: iconColor.withOpacity(0.3)),
      ),
      color: iconColor.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppDimensions.md),
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
                    if (items != null && items!.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        items!.join(', '),
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
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
