// lib/ventas/pages/ventas_home_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../services/ventas_service.dart';
import 'quotes_list_page.dart';
import 'orders_list_page.dart';
import 'quote_form_page.dart';

enum VentasView { dashboard, cotizaciones, ordenes }

class VentasHomePage extends StatefulWidget {
  const VentasHomePage({super.key});
  @override
  State<VentasHomePage> createState() => _VentasHomePageState();
}

class _VentasHomePageState extends State<VentasHomePage> {
  VentasView _currentView = VentasView.dashboard;
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await VentasService.instance.getDashboardStats();
      if (mounted) setState(() { _stats = stats; _loadingStats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 20),
          ),
        ),
        title: Text('Ventas', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(child: _buildContent()),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
      floatingActionButton: _currentView == VentasView.cotizaciones
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteFormPage())),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Nueva cotización', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.md),
          _sidebarItem(VentasView.dashboard, Icons.dashboard_rounded, 'Dashboard'),
          _sidebarItem(VentasView.cotizaciones, Icons.request_quote_rounded, 'Cotizaciones'),
          _sidebarItem(VentasView.ordenes, Icons.receipt_long_rounded, 'Órdenes'),
        ],
      ),
    );
  }

  Widget _sidebarItem(VentasView view, IconData icon, String label) {
    final selected = _currentView == view;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primary : AppColors.textHint, size: 20),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      )),
      selected: selected,
      selectedTileColor: AppColors.primarySurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
      onTap: () => setState(() => _currentView = view),
    );
  }

  Widget? _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _currentView.index,
      onDestinationSelected: (i) => setState(() => _currentView = VentasView.values[i]),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.request_quote_rounded), label: 'Cotizaciones'),
        NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Órdenes'),
      ],
    );
  }

  Widget _buildContent() {
    switch (_currentView) {
      case VentasView.dashboard:
        return _buildDashboard();
      case VentasView.cotizaciones:
        return const QuotesListPage();
      case VentasView.ordenes:
        return const OrdersListPage();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildDashboard() {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _stats ?? {};
    final ventasMes = (stats['ventasMes'] ?? 0.0) as double;
    final cotPendientes = (stats['cotizacionesPendientes'] ?? 0) as int;
    final porCobrar = (stats['ordenesPorCobrar'] ?? 0.0) as double;
    final tasa = (stats['tasaConversion'] ?? 0.0) as double;
    final topProducts = (stats['topProducts'] ?? []) as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard de Ventas', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.lg),

          // Stats cards
          Wrap(
            spacing: AppDimensions.md,
            runSpacing: AppDimensions.md,
            children: [
              _StatCard(
                icon: Icons.attach_money_rounded,
                title: 'Ventas del mes',
                value: '\$${ventasMes.toStringAsFixed(0)}',
                color: AppColors.success,
              ),
              _StatCard(
                icon: Icons.request_quote_rounded,
                title: 'Cotizaciones pendientes',
                value: '$cotPendientes',
                color: AppColors.warning,
              ),
              _StatCard(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Por cobrar',
                value: '\$${porCobrar.toStringAsFixed(0)}',
                color: AppColors.error,
              ),
              _StatCard(
                icon: Icons.trending_up_rounded,
                title: 'Tasa de conversión',
                value: '${tasa.toStringAsFixed(1)}%',
                color: AppColors.primary,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.xl),
          Text('Top Productos Vendidos', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.md),

          if (topProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textHint),
                    const SizedBox(height: AppDimensions.md),
                    Text('Aún no hay ventas registradas', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                    const SizedBox(height: AppDimensions.md),
                    FilledButton.icon(
                      onPressed: () => setState(() => _currentView = VentasView.cotizaciones),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Crear primera cotización'),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: topProducts.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: Text('${i + 1}', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                    ),
                    title: Text(p['nombre'] ?? '', style: AppTextStyles.bodyMedium),
                    subtitle: Text('SKU: ${p['sku']}', style: AppTextStyles.caption),
                    trailing: Text('${(p['cantidad'] as double).toStringAsFixed(0)} uds', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
