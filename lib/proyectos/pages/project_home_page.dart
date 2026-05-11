// lib/proyectos/pages/project_home_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import 'project_dashboard_page.dart';
import 'project_list_page.dart';
import 'project_tasks_page.dart';
import 'project_transactions_page.dart';
import 'project_timeline_page.dart';
import 'project_reports_page.dart';
import '../services/project_service.dart';

enum ProjectView {
  dashboard,
  projects,
  tasks,
  transactions,
  timeline,
  reports,
}

class ProjectHomePage extends StatefulWidget {
  const ProjectHomePage({super.key});

  @override
  State<ProjectHomePage> createState() => _ProjectHomePageState();
}

class _ProjectHomePageState extends State<ProjectHomePage> {
  UserRole? _role;
  bool _loadingRole = true;
  ProjectView _currentView = ProjectView.dashboard;

  @override
  void initState() {
    super.initState();
    _loadRole();
    // Migrar datos existentes: recalcular progreso basado en pagos
    ProjectService.instance.recalculateAllProjectsProgress();
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

  void _changeView(ProjectView view) {
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
      body: SafeArea(child: _buildBody(role, isMobile, isDesktop)),
    );
  }

  Widget _buildBody(UserRole role, bool isMobile, bool isDesktop) {
    if (isMobile) return _buildCurrentView(role);
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
                child: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 20),
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
              child: const Icon(Icons.account_tree_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppDimensions.md),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Proyectos', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              if (!isMobile)
                Text(
                  _getViewTitle(_currentView),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewButton(icon: Icons.dashboard_rounded, label: 'Dashboard',
            isSelected: _currentView == ProjectView.dashboard, onTap: () => _changeView(ProjectView.dashboard)),
          _ViewButton(icon: Icons.folder_rounded, label: 'Proyectos',
            isSelected: _currentView == ProjectView.projects, onTap: () => _changeView(ProjectView.projects)),
          _ViewButton(icon: Icons.task_alt_rounded, label: 'Tareas',
            isSelected: _currentView == ProjectView.tasks, onTap: () => _changeView(ProjectView.tasks)),
          _ViewButton(icon: Icons.account_balance_wallet_rounded, label: 'Finanzas',
            isSelected: _currentView == ProjectView.transactions, onTap: () => _changeView(ProjectView.transactions)),
          _ViewButton(icon: Icons.assessment_rounded, label: 'Reportes',
            isSelected: _currentView == ProjectView.reports, onTap: () => _changeView(ProjectView.reports)),
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
                  Text('GESTIÓN', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                  const SizedBox(height: AppDimensions.sm),
                  _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard',
                    isSelected: _currentView == ProjectView.dashboard, onTap: () => _changeView(ProjectView.dashboard)),
                  _SidebarItem(icon: Icons.folder_rounded, label: 'Proyectos',
                    isSelected: _currentView == ProjectView.projects, onTap: () => _changeView(ProjectView.projects)),
                  _SidebarItem(icon: Icons.task_alt_rounded, label: 'Tareas',
                    isSelected: _currentView == ProjectView.tasks, onTap: () => _changeView(ProjectView.tasks)),
                  const SizedBox(height: AppDimensions.lg),
                  const Divider(),
                  const SizedBox(height: AppDimensions.lg),
                  Text('FINANZAS', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                  const SizedBox(height: AppDimensions.sm),
                  _SidebarItem(icon: Icons.account_balance_wallet_rounded, label: 'Transacciones',
                    isSelected: _currentView == ProjectView.transactions, onTap: () => _changeView(ProjectView.transactions)),
                  const SizedBox(height: AppDimensions.lg),
                  const Divider(),
                  const SizedBox(height: AppDimensions.lg),
                  Text('HISTORIAL', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                  const SizedBox(height: AppDimensions.sm),
                  _SidebarItem(icon: Icons.timeline_rounded, label: 'Timeline',
                    isSelected: _currentView == ProjectView.timeline, onTap: () => _changeView(ProjectView.timeline)),
                  _SidebarItem(icon: Icons.assessment_rounded, label: 'Reportes',
                    isSelected: _currentView == ProjectView.reports, onTap: () => _changeView(ProjectView.reports)),
                ],
              ),
            ),
          ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            const Icon(Icons.insights_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: AppDimensions.xs),
            Text('Resumen rápido', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: AppDimensions.sm),
          _QuickStatRow(label: 'Activos', value: '-'),
          _QuickStatRow(label: 'Atrasados', value: '-', isWarning: true),
          _QuickStatRow(label: 'Completados', value: '-'),
        ],
      ),
    );
  }

  Widget _buildDrawer(UserRole role) {
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(color: AppColors.primarySurface),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                child: const Icon(Icons.account_tree_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppDimensions.md),
              Text('Proyectos', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              children: [
                _DrawerItem(icon: Icons.dashboard_rounded, label: 'Dashboard',
                  isSelected: _currentView == ProjectView.dashboard, onTap: () => _changeView(ProjectView.dashboard)),
                _DrawerItem(icon: Icons.folder_rounded, label: 'Proyectos',
                  isSelected: _currentView == ProjectView.projects, onTap: () => _changeView(ProjectView.projects)),
                _DrawerItem(icon: Icons.task_alt_rounded, label: 'Tareas',
                  isSelected: _currentView == ProjectView.tasks, onTap: () => _changeView(ProjectView.tasks)),
                const Divider(height: AppDimensions.xl),
                _DrawerItem(icon: Icons.account_balance_wallet_rounded, label: 'Transacciones',
                  isSelected: _currentView == ProjectView.transactions, onTap: () => _changeView(ProjectView.transactions)),
                const Divider(height: AppDimensions.xl),
                _DrawerItem(icon: Icons.timeline_rounded, label: 'Timeline',
                  isSelected: _currentView == ProjectView.timeline, onTap: () => _changeView(ProjectView.timeline)),
                _DrawerItem(icon: Icons.assessment_rounded, label: 'Reportes',
                  isSelected: _currentView == ProjectView.reports, onTap: () => _changeView(ProjectView.reports)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCurrentView(UserRole role) {
    return KeyedSubtree(
      key: ValueKey(_currentView),
      child: switch (_currentView) {
        ProjectView.dashboard => ProjectDashboardPage(role: role),
        ProjectView.projects => ProjectListPage(role: role),
        ProjectView.tasks => ProjectTasksPage(role: role),
        ProjectView.transactions => ProjectTransactionsPage(role: role),
        ProjectView.timeline => ProjectTimelinePage(role: role),
        ProjectView.reports => ProjectReportsPage(role: role),
      },
    );
  }

  String _getViewTitle(ProjectView view) {
    return switch (view) {
      ProjectView.dashboard => 'Panel de control',
      ProjectView.projects => 'Lista de proyectos',
      ProjectView.tasks => 'Gestión de tareas',
      ProjectView.transactions => 'Transacciones financieras',
      ProjectView.timeline => 'Historial de actividad',
      ProjectView.reports => 'Reportes',
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

  const _ViewButton({required this.icon, required this.label, required this.isSelected, required this.onTap});

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
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            child: Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
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

  const _SidebarItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

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
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.md),
            child: Row(children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: AppDimensions.md),
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ))),
            ]),
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

  const _DrawerItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
        title: Text(label, style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
        selected: isSelected,
        selectedTileColor: AppColors.primarySurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        onTap: onTap,
      ),
    );
  }
}

class _QuickStatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;

  const _QuickStatRow({required this.label, required this.value, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: isWarning ? AppColors.warning : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
