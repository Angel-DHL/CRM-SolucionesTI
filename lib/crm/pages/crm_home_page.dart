// lib/crm/pages/crm_home_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../services/crm_service.dart';
import '../widgets/crm_leads_inbox.dart';
import 'crm_dashboard_page.dart';
import 'crm_contacts_page.dart';

enum CrmView {
  dashboard,
  contacts,
  leads,
}

class CrmHomePage extends StatefulWidget {
  const CrmHomePage({super.key});

  @override
  State<CrmHomePage> createState() => _CrmHomePageState();
}

class _CrmHomePageState extends State<CrmHomePage> {
  UserRole? _role;
  bool _loadingRole = true;
  CrmView _currentView = CrmView.dashboard;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdTokenResult(true);
      final claimRole = token.claims?['role'] as String?;
      setState(() {
        _role = UserRole.fromClaim(claimRole);
        _loadingRole = false;
      });
    } catch (e) {
      setState(() {
        _role = UserRole.soporteTecnico;
        _loadingRole = false;
      });
    }
  }

  void _changeView(CrmView view) {
    setState(() => _currentView = view);
    if (Responsive.isMobile(context) && Navigator.of(context).canPop()) {
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
      floatingActionButton: isMobile && _currentView == CrmView.contacts
          ? FloatingActionButton(
              onPressed: () {
                // Trigger create from contacts page
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add_rounded),
            )
          : null,
      body: SafeArea(child: _buildBody(role, isMobile, isDesktop)),
    );
  }

  Widget _buildBody(UserRole role, bool isMobile, bool isDesktop) {
    if (isMobile) {
      return _buildCurrentView(role);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop) _buildSidebar(role),
        Expanded(child: _buildCurrentView(role)),
      ],
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
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CRM',
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
        // Leads badge
        StreamBuilder<int>(
          stream: CrmService.instance.streamUnreadLeadsCount(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Stack(
              children: [
                IconButton(
                  onPressed: () => _changeView(CrmView.leads),
                  icon: Icon(
                    Icons.inbox_rounded,
                    color: _currentView == CrmView.leads
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  tooltip: 'Leads del sitio web',
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewButton(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isSelected: _currentView == CrmView.dashboard,
            onTap: () => _changeView(CrmView.dashboard),
          ),
          _ViewButton(
            icon: Icons.people_rounded,
            label: 'Contactos',
            isSelected: _currentView == CrmView.contacts,
            onTap: () => _changeView(CrmView.contacts),
          ),
          _ViewButton(
            icon: Icons.inbox_rounded,
            label: 'Leads',
            isSelected: _currentView == CrmView.leads,
            onTap: () => _changeView(CrmView.leads),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(UserRole role) {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NAVEGACIÓN',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  _SidebarItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: _currentView == CrmView.dashboard,
                    onTap: () => _changeView(CrmView.dashboard),
                  ),
                  _SidebarItem(
                    icon: Icons.people_rounded,
                    label: 'Contactos',
                    isSelected: _currentView == CrmView.contacts,
                    onTap: () => _changeView(CrmView.contacts),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  const Divider(),
                  const SizedBox(height: AppDimensions.lg),
                  Text(
                    'CAPTACIÓN',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  StreamBuilder<int>(
                    stream: CrmService.instance.streamUnreadLeadsCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _SidebarItem(
                        icon: Icons.inbox_rounded,
                        label: 'Leads del sitio web',
                        isSelected: _currentView == CrmView.leads,
                        onTap: () => _changeView(CrmView.leads),
                        badge: count > 0 ? '$count' : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Quick stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<Map<dynamic, int>>(
      stream: CrmService.instance.streamStatusCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {};
        final total = counts.values.fold(0, (a, b) => a + b);

        return Container(
          margin: const EdgeInsets.all(AppDimensions.md),
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_rounded, size: 16, color: AppColors.primary),
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
              _QuickStatRow(label: 'Total contactos', value: '$total'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(UserRole role) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(color: AppColors.primarySurface),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Text(
                    'CRM',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: _currentView == CrmView.dashboard,
                    onTap: () => _changeView(CrmView.dashboard),
                  ),
                  _DrawerItem(
                    icon: Icons.people_rounded,
                    label: 'Contactos',
                    isSelected: _currentView == CrmView.contacts,
                    onTap: () => _changeView(CrmView.contacts),
                  ),
                  const Divider(height: AppDimensions.xl),
                  _DrawerItem(
                    icon: Icons.inbox_rounded,
                    label: 'Leads del sitio web',
                    isSelected: _currentView == CrmView.leads,
                    onTap: () => _changeView(CrmView.leads),
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
    return KeyedSubtree(
      key: ValueKey(_currentView),
      child: switch (_currentView) {
        CrmView.dashboard => CrmDashboardPage(role: role),
        CrmView.contacts => CrmContactsPage(role: role),
        CrmView.leads => _buildLeadsFullPage(),
      },
    );
  }

  Widget _buildLeadsFullPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inbox_rounded, size: 24, color: AppColors.info),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leads del sitio web',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Contactos que llegan del formulario web de la empresa',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          const CrmLeadsInbox(),
        ],
      ),
    );
  }

  String _getViewTitle(CrmView view) {
    return switch (view) {
      CrmView.dashboard => 'Panel de control',
      CrmView.contacts => 'Contactos',
      CrmView.leads => 'Leads del sitio web',
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
  final String? badge;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
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
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
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
      ),
    );
  }
}

class _QuickStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
