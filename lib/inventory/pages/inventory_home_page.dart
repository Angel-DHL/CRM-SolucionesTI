// lib/inventory/pages/inventory_home_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import 'inventory_dashboard_page.dart';
import 'inventory_list_page.dart';
import 'inventory_categories_page.dart';
import 'inventory_suppliers_page.dart';
import 'inventory_locations_page.dart';
import 'inventory_movements_page.dart';
import 'inventory_reports_page.dart';

enum InventoryView {
  dashboard,
  items,
  categories,
  suppliers,
  locations,
  movements,
  reports,
}

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({super.key});

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  UserRole? _role;
  bool _loadingRole = true;
  InventoryView _currentView = InventoryView.dashboard;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser!;
    final token = await user.getIdTokenResult(true);
    final claimRole = token.claims?['role'] as String?;
    setState(() {
      _role = UserRole.fromClaim(claimRole);
      _loadingRole = false;
    });
  }

  void _changeView(InventoryView view) {
    setState(() => _currentView = view);
    // Cerrar drawer en móvil
    if (Responsive.isMobile(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = _role ?? UserRole.soporteTecnico;
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, isMobile),
      drawer: isMobile ? _buildDrawer(role) : null,
      body: Row(
        children: [
          // Sidebar (solo desktop)
          if (isDesktop) _buildSidebar(role),

          // Contenido principal
          Expanded(child: _buildCurrentView(role)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isMobile) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: isMobile
          ? null
          : IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
      title: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventario',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!isMobile)
                Text(
                  _getViewTitle(_currentView),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (!isMobile) _buildViewSelector(),
        const SizedBox(width: AppDimensions.sm),
      ],
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          _ViewButton(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isSelected: _currentView == InventoryView.dashboard,
            onTap: () => _changeView(InventoryView.dashboard),
          ),
          _ViewButton(
            icon: Icons.inventory_2_rounded,
            label: 'Items',
            isSelected: _currentView == InventoryView.items,
            onTap: () => _changeView(InventoryView.items),
          ),
          _ViewButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Movimientos',
            isSelected: _currentView == InventoryView.movements,
            onTap: () => _changeView(InventoryView.movements),
          ),
          _ViewButton(
            icon: Icons.assessment_rounded,
            label: 'Reportes',
            isSelected: _currentView == InventoryView.reports,
            onTap: () => _changeView(InventoryView.reports),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(UserRole role) {
    return Container(
      width: AppDimensions.sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MÓDULOS',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: _currentView == InventoryView.dashboard,
                  onTap: () => _changeView(InventoryView.dashboard),
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventario',
                  isSelected: _currentView == InventoryView.items,
                  onTap: () => _changeView(InventoryView.items),
                ),
                _SidebarItem(
                  icon: Icons.category_rounded,
                  label: 'Categorías',
                  isSelected: _currentView == InventoryView.categories,
                  onTap: () => _changeView(InventoryView.categories),
                ),
                _SidebarItem(
                  icon: Icons.local_shipping_rounded,
                  label: 'Proveedores',
                  isSelected: _currentView == InventoryView.suppliers,
                  onTap: () => _changeView(InventoryView.suppliers),
                ),
                _SidebarItem(
                  icon: Icons.location_on_rounded,
                  label: 'Ubicaciones',
                  isSelected: _currentView == InventoryView.locations,
                  onTap: () => _changeView(InventoryView.locations),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERACIONES',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                _SidebarItem(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Movimientos',
                  isSelected: _currentView == InventoryView.movements,
                  onTap: () => _changeView(InventoryView.movements),
                ),
                _SidebarItem(
                  icon: Icons.assessment_rounded,
                  label: 'Reportes',
                  isSelected: _currentView == InventoryView.reports,
                  onTap: () => _changeView(InventoryView.reports),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Quick stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.xs),
              Text(
                'Resumen rápido',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          // Aquí se agregarían stats reales
          _QuickStatRow(label: 'Items activos', value: '-'),
          _QuickStatRow(label: 'Stock bajo', value: '-', isWarning: true),
          _QuickStatRow(label: 'Valor total', value: '-'),
        ],
      ),
    );
  }

  Widget _buildDrawer(UserRole role) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(color: AppColors.primarySurface),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Text(
                    'Inventario',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                ),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: _currentView == InventoryView.dashboard,
                    onTap: () => _changeView(InventoryView.dashboard),
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Inventario',
                    isSelected: _currentView == InventoryView.items,
                    onTap: () => _changeView(InventoryView.items),
                  ),
                  _DrawerItem(
                    icon: Icons.category_rounded,
                    label: 'Categorías',
                    isSelected: _currentView == InventoryView.categories,
                    onTap: () => _changeView(InventoryView.categories),
                  ),
                  _DrawerItem(
                    icon: Icons.local_shipping_rounded,
                    label: 'Proveedores',
                    isSelected: _currentView == InventoryView.suppliers,
                    onTap: () => _changeView(InventoryView.suppliers),
                  ),
                  _DrawerItem(
                    icon: Icons.location_on_rounded,
                    label: 'Ubicaciones',
                    isSelected: _currentView == InventoryView.locations,
                    onTap: () => _changeView(InventoryView.locations),
                  ),
                  const Divider(height: AppDimensions.xl),
                  _DrawerItem(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Movimientos',
                    isSelected: _currentView == InventoryView.movements,
                    onTap: () => _changeView(InventoryView.movements),
                  ),
                  _DrawerItem(
                    icon: Icons.assessment_rounded,
                    label: 'Reportes',
                    isSelected: _currentView == InventoryView.reports,
                    onTap: () => _changeView(InventoryView.reports),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView(UserRole role) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (_currentView) {
        InventoryView.dashboard => InventoryDashboardPage(role: role),
        InventoryView.items => InventoryListPage(role: role),
        InventoryView.categories => InventoryCategoriesPage(role: role),
        InventoryView.suppliers => InventorySuppliersPage(role: role),
        InventoryView.locations => InventoryLocationsPage(role: role),
        InventoryView.movements => InventoryMovementsPage(role: role),
        InventoryView.reports => InventoryReportsPage(role: role),
      },
    );
  }

  String _getViewTitle(InventoryView view) {
    return switch (view) {
      InventoryView.dashboard => 'Panel de control',
      InventoryView.items => 'Lista de items',
      InventoryView.categories => 'Categorías',
      InventoryView.suppliers => 'Proveedores',
      InventoryView.locations => 'Ubicaciones',
      InventoryView.movements => 'Movimientos',
      InventoryView.reports => 'Reportes',
    };
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════

class _ViewButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: isSelected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primarySurface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      onTap: onTap,
    );
  }
}

class _QuickStatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;

  const _QuickStatRow({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
              fontWeight: FontWeight.w600,
              color: isWarning ? AppColors.warning : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
