// lib/soporte/pages/soporte_home_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import 'cases_list_page.dart';
import 'case_form_page.dart';
import 'knowledge_base_page.dart';
import 'manuals_page.dart';
import 'ai_insights_page.dart';
import 'support_dashboard_page.dart';

enum SoporteView { dashboard, cases, knowledge, manuals, aiInsights }

class SoporteHomePage extends StatefulWidget {
  const SoporteHomePage({super.key});

  @override
  State<SoporteHomePage> createState() => _SoporteHomePageState();
}

class _SoporteHomePageState extends State<SoporteHomePage> {
  UserRole? _role; // ignore: unused_field — reserved for permission checks
  bool _loadingRole = true;
  SoporteView _currentView = SoporteView.dashboard;

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

  void _changeView(SoporteView view) {
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

    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, isMobile),
      drawer: isMobile ? _buildDrawer() : null,
      floatingActionButton: _currentView == SoporteView.cases
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CaseFormPage()),
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Nuevo Caso', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: SafeArea(child: _buildBody(isMobile, isDesktop)),
    );
  }

  Widget _buildBody(bool isMobile, bool isDesktop) {
    if (isMobile) return _buildCurrentView();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop) _buildSidebar(),
        Expanded(child: _buildCurrentView()),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppDimensions.md),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Soporte', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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
          _ViewBtn(icon: Icons.dashboard_rounded, label: 'Dashboard',
            isSelected: _currentView == SoporteView.dashboard, onTap: () => _changeView(SoporteView.dashboard)),
          _ViewBtn(icon: Icons.confirmation_number_rounded, label: 'Casos',
            isSelected: _currentView == SoporteView.cases, onTap: () => _changeView(SoporteView.cases)),
          _ViewBtn(icon: Icons.menu_book_rounded, label: 'Base de Conocimiento',
            isSelected: _currentView == SoporteView.knowledge, onTap: () => _changeView(SoporteView.knowledge)),
          _ViewBtn(icon: Icons.description_rounded, label: 'Manuales',
            isSelected: _currentView == SoporteView.manuals, onTap: () => _changeView(SoporteView.manuals)),
          _ViewBtn(icon: Icons.auto_awesome_rounded, label: 'IA Insights',
            isSelected: _currentView == SoporteView.aiInsights, onTap: () => _changeView(SoporteView.aiInsights)),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GESTIÓN', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
            const SizedBox(height: AppDimensions.sm),
            _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard',
              isSelected: _currentView == SoporteView.dashboard, onTap: () => _changeView(SoporteView.dashboard)),
            _SidebarItem(icon: Icons.confirmation_number_rounded, label: 'Casos',
              isSelected: _currentView == SoporteView.cases, onTap: () => _changeView(SoporteView.cases)),
            const SizedBox(height: AppDimensions.lg),
            const Divider(),
            const SizedBox(height: AppDimensions.lg),
            Text('CONOCIMIENTO', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
            const SizedBox(height: AppDimensions.sm),
            _SidebarItem(icon: Icons.menu_book_rounded, label: 'Base de Conocimiento',
              isSelected: _currentView == SoporteView.knowledge, onTap: () => _changeView(SoporteView.knowledge)),
            _SidebarItem(icon: Icons.description_rounded, label: 'Manuales y Guías',
              isSelected: _currentView == SoporteView.manuals, onTap: () => _changeView(SoporteView.manuals)),
            const SizedBox(height: AppDimensions.lg),
            const Divider(),
            const SizedBox(height: AppDimensions.lg),
            Text('INTELIGENCIA', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
            const SizedBox(height: AppDimensions.sm),
            _SidebarItem(icon: Icons.auto_awesome_rounded, label: 'IA Insights',
              isSelected: _currentView == SoporteView.aiInsights, onTap: () => _changeView(SoporteView.aiInsights)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: const BoxDecoration(color: AppColors.primarySurface),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppDimensions.md),
              Text('Soporte', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              children: [
                _DrawerItem(icon: Icons.dashboard_rounded, label: 'Dashboard',
                  isSelected: _currentView == SoporteView.dashboard, onTap: () => _changeView(SoporteView.dashboard)),
                _DrawerItem(icon: Icons.confirmation_number_rounded, label: 'Casos',
                  isSelected: _currentView == SoporteView.cases, onTap: () => _changeView(SoporteView.cases)),
                const Divider(height: AppDimensions.xl),
                _DrawerItem(icon: Icons.menu_book_rounded, label: 'Base de Conocimiento',
                  isSelected: _currentView == SoporteView.knowledge, onTap: () => _changeView(SoporteView.knowledge)),
                _DrawerItem(icon: Icons.description_rounded, label: 'Manuales',
                  isSelected: _currentView == SoporteView.manuals, onTap: () => _changeView(SoporteView.manuals)),
                const Divider(height: AppDimensions.xl),
                _DrawerItem(icon: Icons.auto_awesome_rounded, label: 'IA Insights',
                  isSelected: _currentView == SoporteView.aiInsights, onTap: () => _changeView(SoporteView.aiInsights)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCurrentView() {
    return KeyedSubtree(
      key: ValueKey(_currentView),
      child: switch (_currentView) {
        SoporteView.dashboard => const SupportDashboardPage(),
        SoporteView.cases => const CasesListPage(),
        SoporteView.knowledge => const KnowledgeBasePage(),
        SoporteView.manuals => ManualsPage(role: _role),
        SoporteView.aiInsights => const AiInsightsPage(),
      },
    );
  }

  String _getViewTitle(SoporteView view) {
    return switch (view) {
      SoporteView.dashboard => 'Panel de control',
      SoporteView.cases => 'Gestión de casos',
      SoporteView.knowledge => 'Base de conocimiento',
      SoporteView.manuals => 'Manuales y guías',
      SoporteView.aiInsights => 'Análisis con IA',
    };
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════

class _ViewBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ViewBtn({required this.icon, required this.label, required this.isSelected, required this.onTap});

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
