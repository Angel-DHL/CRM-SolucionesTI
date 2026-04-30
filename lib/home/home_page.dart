import 'package:crm_solucionesti/crm/pages/crm_home_page.dart';
import 'package:crm_solucionesti/inventory/pages/inventory_home_page.dart';
import 'package:crm_solucionesti/ventas/pages/ventas_home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/responsive.dart';
import '../core/role.dart';
import '../core/role_access.dart';
import '../admin/create_user_page.dart';
import '../admin/user_management_page.dart';
import '../admin/role_management_page.dart';
import '../home/profile_settings_page.dart';
import '../operatividad/pages/operatividad_page.dart';
import '../core/services/role_service.dart';
import '../core/firebase_helper.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  UserRole? _role;
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  
  // Datos del dashboard
  int _activeActivities = 0;
  int _inventoryCount = 0;
  int _leadsCount = 0;
  bool _statsLoading = true;

  late AnimationController _statsController;
  late AnimationController _modulesController;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _setupAnimations();
  }

  void _setupAnimations() {
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _modulesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _statsController.dispose();
    _modulesController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdTokenResult(true);
      final claimRole = token.claims?['role'] as String?;
      setState(() {
        _role = UserRole.fromClaim(claimRole);
      });

      // Iniciar animaciones después de cargar
      if (mounted) {
        _statsController.forward();
        _modulesController.forward();
        _loadDashboardStats();
        
        // Sembrar roles iniciales si es necesario
        if (_role?.id == 'admin') {
          RoleService.seedInitialRoles();
        }
      }
    } catch (_) {
      setState(
        () => _error = 'No se pudo cargar el rol. Intenta reiniciar sesión.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final activities = await FirebaseHelper.operActivities.count().get();
      final inventory = await FirebaseHelper.inventoryItems.count().get();
      final leads = await FirebaseHelper.leads.count().get();

      if (mounted) {
        setState(() {
          _activeActivities = activities.count ?? 0;
          _inventoryCount = inventory.count ?? 0;
          _leadsCount = leads.count ?? 0;
          _statsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando stats: $e');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  List<AppModule> _getFilteredModules() {
    final role = _role ?? UserRole.soporteTecnico;
    final modules = RoleAccess.allModules
        .where((m) => RoleAccess.canAccess(role, m))
        .toList();

    if (_searchQuery.isEmpty) return modules;

    return modules
        .where(
          (m) => m.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    Responsive.isMobile(context);

    if (_loading) {
      return const _LoadingSkeleton();
    }

    if (_error != null) {
      return _ErrorScreen(
        message: _error!,
        onRetry: _loadRole,
        onLogout: _logout,
      );
    }

    final role = _role ?? UserRole.soporteTecnico;
    final modules = _getFilteredModules();
    final user = FirebaseAuth.instance.currentUser;

    return _MainScaffold(
      role: role,
      modules: modules,
      user: user,
      selectedIndex: _selectedIndex,
      isSidebarCollapsed: _isSidebarCollapsed,
      onToggleSidebar: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
      onItemSelected: (index) {
        // Si es un módulo, navegar directamente
        if (index >= 1 && index <= modules.length) {
          _navigateToModule(modules[index - 1]);
          return;
        }

        if (index == modules.length + 2) {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsPage()));
           return;
        }
        setState(() => _selectedIndex = index);
      },
      onSearchChanged: (query) => setState(() => _searchQuery = query),
      onModuleTap: _navigateToModule,
      onCreateUser: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateUserPage()),
      ),
      onLogout: _logout,
      onRefresh: () {
        _loadRole();
        _loadDashboardStats();
      },
      statsController: _statsController,
      modulesController: _modulesController,
      activeActivities: _activeActivities,
      inventoryCount: _inventoryCount,
      leadsCount: _leadsCount,
      statsLoading: _statsLoading,
    );
  }

  void _navigateToModule(AppModule module) {
    // Resetear al Dashboard para que al regresar no se re-navegue
    setState(() => _selectedIndex = 0);
    
    switch (module) {
      case AppModule.operatividad:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OperatividadPage()));
        break;
      case AppModule.crm:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CrmHomePage()));
        break;
      case AppModule.inventario:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InventoryHomePage()));
        break;
      case AppModule.ventas:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VentasHomePage()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Módulo ${module.title} en desarrollo')),
        );
    }
  }
}

class _MainScaffold extends StatelessWidget {
  final UserRole role;
  final List<AppModule> modules;
  final User? user;
  final int selectedIndex;
  final bool isSidebarCollapsed;
  final VoidCallback onToggleSidebar;
  final ValueChanged<int> onItemSelected;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AppModule> onModuleTap;
  final VoidCallback onCreateUser;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final AnimationController statsController;
  final AnimationController modulesController;
  
  final int activeActivities;
  final int inventoryCount;
  final int leadsCount;
  final bool statsLoading;

  const _MainScaffold({
    required this.role,
    required this.modules,
    required this.user,
    required this.selectedIndex,
    required this.isSidebarCollapsed,
    required this.onToggleSidebar,
    required this.onItemSelected,
    required this.onSearchChanged,
    required this.onModuleTap,
    required this.onCreateUser,
    required this.onLogout,
    required this.onRefresh,
    required this.statsController,
    required this.modulesController,
    required this.activeActivities,
    required this.inventoryCount,
    required this.leadsCount,
    required this.statsLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    Widget content;
    if (selectedIndex == 0) {
      content = _DashboardView(
        role: role,
        controller: statsController,
        activeActivities: activeActivities,
        inventoryCount: inventoryCount,
        leadsCount: leadsCount,
        loading: statsLoading,
      );
    } else if (selectedIndex <= modules.length) {
      // Los módulos se abren directamente via Navigator.push,
      // así que mostramos el Dashboard como vista base.
      content = _DashboardView(
        role: role,
        controller: statsController,
        activeActivities: activeActivities,
        inventoryCount: inventoryCount,
        leadsCount: leadsCount,
        loading: statsLoading,
      );
      // Auto-navegar al módulo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onModuleTap(modules[selectedIndex - 1]);
      });
    } else if (selectedIndex == modules.length + 1) {
      content = const UserManagementPage();
    } else {
      content = const Center(child: Text('Vista no encontrada'));
    }

    if (isDesktop || isTablet) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              role: role,
              modules: modules,
              selectedIndex: selectedIndex,
              onItemSelected: onItemSelected,
              onLogout: onLogout,
              user: user,
              isCollapsed: isSidebarCollapsed,
              onToggleCollapse: onToggleSidebar,
            ),
            Expanded(
              child: Column(
                children: [
                  _Header(
                    role: role,
                    user: user,
                    onSearchChanged: onSearchChanged,
                    onRefresh: onRefresh,
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: _MobileDrawer(
        role: role,
        user: user,
        selectedIndex: selectedIndex,
        onItemSelected: onItemSelected,
        onLogout: onLogout,
        modules: modules,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _MobileHeader(
              onMenuPressed: () => Scaffold.of(context).openDrawer(),
              onSearchChanged: onSearchChanged,
              onRefresh: onRefresh,
            ),
            Expanded(child: content),
          ],
        ),
      ),
      bottomNavigationBar: _MobileBottomNav(
        selectedIndex: selectedIndex,
        onItemSelected: onItemSelected,
        modulesCount: modules.length,
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final UserRole role;
  final AnimationController controller;
  final int activeActivities;
  final int inventoryCount;
  final int leadsCount;
  final bool loading;

  const _DashboardView({
    required this.role,
    required this.controller,
    required this.activeActivities,
    required this.inventoryCount,
    required this.leadsCount,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeCard(role: role, user: FirebaseAuth.instance.currentUser),
          const SizedBox(height: AppDimensions.xl),
          _DashboardStats(
            controller: controller,
            role: role,
            activeActivities: activeActivities,
            inventoryCount: inventoryCount,
            leadsCount: leadsCount,
            loading: loading,
          ),
          // Aquí podrías agregar una sección de "Actividades Recientes" con datos reales
        ],
      ),
    );
  }
}

class _ModulesView extends StatelessWidget {
  final List<AppModule> modules;
  final AnimationController controller;
  final ValueChanged<AppModule> onModuleTap;

  const _ModulesView({
    required this.modules,
    required this.controller,
    required this.onModuleTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: _ModulesSection(
        modules: modules,
        controller: controller,
        onModuleTap: onModuleTap,
        role: UserRole.admin, // Solo para la lógica de visualización
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
// WIDGETS: SIDEBAR & NAVIGATION
// ══════════════════════════════════════════════════════════════

class _Sidebar extends StatelessWidget {
  final UserRole role;
  final List<AppModule> modules;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final User? user;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const _Sidebar({
    required this.role,
    required this.modules,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.user,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final width = isCollapsed
        ? AppDimensions.sidebarCollapsedWidth
        : AppDimensions.sidebarWidth;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            height: 72,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? AppDimensions.sm : AppDimensions.lg,
            ),
            alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
            child: isCollapsed
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CRM',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Soluciones TI',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onToggleCollapse,
                        icon: const Icon(Icons.chevron_left_rounded),
                        color: AppColors.textHint,
                        tooltip: 'Compactar menú',
                      ),
                    ],
                  ),
          ),

          if (isCollapsed)
            IconButton(
              onPressed: onToggleCollapse,
              icon: const Icon(Icons.chevron_right_rounded),
              color: AppColors.textHint,
              tooltip: 'Expandir menú',
            ),

          const Divider(height: 1),

          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                vertical: AppDimensions.md,
                horizontal: isCollapsed ? AppDimensions.xs : AppDimensions.sm,
              ),
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemSelected(0),
                  isCollapsed: isCollapsed,
                ),
                
                const SizedBox(height: AppDimensions.md),
                if (!isCollapsed)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.xs,
                    ),
                    child: Text(
                      'MÓDULOS',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                
                // Render each module
                ...List.generate(modules.length, (index) {
                  final module = modules[index];
                  return _NavItem(
                    icon: _getModuleIcon(module),
                    label: module.title,
                    isSelected: selectedIndex == index + 1,
                    onTap: () => onItemSelected(index + 1),
                    isCollapsed: isCollapsed,
                  );
                }),

                if (role.id == 'admin') ...[
                  const SizedBox(height: AppDimensions.md),
                  if (!isCollapsed)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: AppDimensions.xs,
                      ),
                      child: Text(
                        'ADMINISTRACIÓN',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  _NavItem(
                    icon: Icons.people_rounded,
                    label: 'Usuarios',
                    isSelected: selectedIndex == modules.length + 1,
                    onTap: () => onItemSelected(modules.length + 1),
                    isCollapsed: isCollapsed,
                  ),
                ],
                const SizedBox(height: AppDimensions.md),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Configuración',
                  isSelected: selectedIndex == modules.length + 2,
                  onTap: () => onItemSelected(modules.length + 2),
                  isCollapsed: isCollapsed,
                ),
              ],
            ),
          ),

          // User section
          const Divider(height: 1),
          _UserSection(
            user: user,
            role: role,
            onLogout: onLogout,
            isCollapsed: isCollapsed,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCollapsed;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDimensions.animFast,
      margin: EdgeInsets.symmetric(
        horizontal: isCollapsed ? AppDimensions.xs : AppDimensions.xs,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: isSelected
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? AppDimensions.sm : AppDimensions.md,
              vertical: AppDimensions.md,
            ),
            child: isCollapsed
                ? Center(
                    child: Icon(
                      icon,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: AppDimensions.iconMd,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: AppDimensions.iconMd,
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Text(
                          label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
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

class _UserSection extends StatelessWidget {
  final User? user;
  final UserRole role;
  final VoidCallback onLogout;
  final bool isCollapsed;

  const _UserSection({
    required this.user,
    required this.role,
    required this.onLogout,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        isCollapsed ? AppDimensions.sm : AppDimensions.md,
      ),
      child: isCollapsed
          ? IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
              color: AppColors.textSecondary,
            )
          : Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email?.split('@')[0] ?? 'Usuario',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            role.label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textHint,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: HEADER & DASHBOARD
// ══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final UserRole role;
  final User? user;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onCreateUser;

  const _Header({
    required this.role,
    required this.user,
    required this.onSearchChanged,
    required this.onRefresh,
    this.onCreateUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 44,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar módulos...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: onSearchChanged,
              ),
            ),
          ),

          const SizedBox(width: AppDimensions.lg),

          // Actions
          Row(
            children: [
              if (onCreateUser != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.sm),
                  child: FilledButton.icon(
                    onPressed: onCreateUser,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Crear usuario'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refrescar',
                color: AppColors.textSecondary,
              ),

              const SizedBox(width: AppDimensions.sm),

              // Profile quick access
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  final AnimationController controller;
  final UserRole role;
  final bool isMobile;
  final int activeActivities;
  final int inventoryCount;
  final int leadsCount;
  final bool loading;

  const _DashboardStats({
    required this.controller,
    required this.role,
    this.isMobile = false,
    required this.activeActivities,
    required this.inventoryCount,
    required this.leadsCount,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _getStats();

    return FadeTransition(
      opacity: controller,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) ...[
              Text(
                'Resumen en tiempo real',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
            ],
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                crossAxisSpacing: AppDimensions.md,
                mainAxisSpacing: AppDimensions.md,
                childAspectRatio: isMobile ? 1.3 : 1.4,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final stat = stats[index];
                return _StatCard(
                  title: stat.title,
                  value: loading ? '...' : stat.value,
                  icon: stat.icon,
                  color: stat.color,
                  trend: stat.trend,
                  delay: index * 100,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<_StatData> _getStats() {
    return [
      _StatData(
        title: 'Actividades',
        value: activeActivities.toString(),
        icon: Icons.assignment_rounded,
        color: AppColors.primary,
        trend: 'Operatividad',
      ),
      _StatData(
        title: 'Productos',
        value: inventoryCount.toString(),
        icon: Icons.inventory_2_rounded,
        color: AppColors.success,
        trend: 'Inventario',
      ),
      _StatData(
        title: 'Leads',
        value: leadsCount.toString(),
        icon: Icons.people_alt_rounded,
        color: AppColors.warning,
        trend: 'CRM',
      ),
    ];
  }
}

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final int delay;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    this.delay = 0,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: AppDimensions.animFast,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.sm),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.color,
                            size: AppDimensions.iconMd,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.xs,
                            vertical: AppDimensions.xs / 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                          ),
                          child: Text(
                            widget.trend,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: widget.color,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      widget.value,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      widget.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: MODULES SECTION
// ══════════════════════════════════════════════════════════════

class _ModulesSection extends StatelessWidget {
  final List<AppModule> modules;
  final AnimationController controller;
  final ValueChanged<AppModule> onModuleTap;
  final UserRole role;
  final bool isMobile;

  const _ModulesSection({
    required this.modules,
    required this.controller,
    required this.onModuleTap,
    required this.role,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Módulos disponibles',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                  '${modules.length} módulos',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          modules.isEmpty
              ? _EmptyState()
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    crossAxisSpacing: AppDimensions.md,
                    mainAxisSpacing: AppDimensions.md,
                    childAspectRatio: isMobile ? 1.0 : 1.1,
                  ),
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    final module = modules[index];
                    return _ModuleCard(
                      module: module,
                      icon: _iconForModule(module),
                      onTap: () => onModuleTap(module),
                      delay: index * 50,
                    );
                  },
                ),
        ],
      ),
    );
  }

  IconData _iconForModule(AppModule m) {
    switch (m) {
      case AppModule.operatividad:
        return Icons.dashboard_customize_rounded;
      case AppModule.crm:
        return Icons.people_alt_rounded;
      case AppModule.inventario:
        return Icons.inventory_2_rounded;
      case AppModule.ventas:
        return Icons.point_of_sale_rounded;
      case AppModule.marketing:
        return Icons.campaign_rounded;
      case AppModule.soporte:
        return Icons.support_agent_rounded;
      case AppModule.proyectos:
        return Icons.account_tree_rounded;
    }
  }
}

class _ModuleCard extends StatefulWidget {
  final AppModule module;
  final IconData icon;
  final VoidCallback onTap;
  final int delay;

  const _ModuleCard({
    required this.module,
    required this.icon,
    required this.onTap,
    this.delay = 0,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: AppDimensions.animFast,
            transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(
                color: _isHovered
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.divider,
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: AppDimensions.animFast,
                        padding: const EdgeInsets.all(AppDimensions.md),
                        decoration: BoxDecoration(
                          gradient: _isHovered
                              ? AppColors.primaryGradient
                              : null,
                          color: _isHovered ? null : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: AppDimensions.iconXl,
                          color: _isHovered ? Colors.white : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        widget.module.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        'Acceder',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: MOBILE COMPONENTS
// ══════════════════════════════════════════════════════════════

class _MobileHeader extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;

  const _MobileHeader({
    required this.onMenuPressed,
    required this.onSearchChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu_rounded),
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppDimensions.sm),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CRM Soluciones TI',
                      style: AppTextStyles.h3.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final UserRole role;
  final User? user;

  const _WelcomeCard({required this.role, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              user?.email?.substring(0, 1).toUpperCase() ?? 'U',
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  user?.email?.split('@')[0] ?? 'Usuario',
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: AppDimensions.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: AppDimensions.xs / 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    role.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final UserRole role;
  final User? user;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final List<AppModule> modules;

  const _MobileDrawer({
    required this.role,
    required this.user,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.modules,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.surface,
        child: Column(
          children: [
            _DrawerHeader(user: user, role: role),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: AppDimensions.md),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: selectedIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(0);
                    },
                  ),
                  
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'MÓDULOS',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
                    ),
                  ),
                  
                  ...List.generate(modules.length, (index) {
                    final module = modules[index];
                    return _DrawerItem(
                      icon: _getModuleIcon(module),
                      label: module.title,
                      isSelected: selectedIndex == index + 1,
                      onTap: () {
                        Navigator.pop(context);
                        onItemSelected(index + 1);
                      },
                    );
                  }),

                  if (role.id == 'admin') ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'ADMINISTRACIÓN',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
                      ),
                    ),
                    _DrawerItem(
                      icon: Icons.people_rounded,
                      label: 'Usuarios',
                      isSelected: selectedIndex == modules.length + 1,
                      onTap: () {
                        Navigator.pop(context);
                        onItemSelected(modules.length + 1);
                      },
                    ),
                  ],
                  
                  const Divider(),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Configuración',
                    isSelected: selectedIndex == modules.length + 2,
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected(modules.length + 2);
                    },
                  ),
                ],
              ),
            ),

            // Logout
            Padding(
              padding: EdgeInsets.all(AppDimensions.md),
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final User? user;
  final UserRole role;

  const _DrawerHeader({required this.user, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              'CRM Soluciones TI',
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              user?.email ?? '',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
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

class _MobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final int modulesCount;

  const _MobileBottomNav({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.modulesCount,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex == 0 ? 0 : (selectedIndex == modulesCount + 2 ? 2 : 1),
      onDestinationSelected: (index) {
        if (index == 0) onItemSelected(0);
        else if (index == 2) onItemSelected(modulesCount + 2);
        else {
          // If they click the middle item, we could open the drawer or something,
          // but for now let's just go to the first module or keep it as is.
          Scaffold.of(context).openDrawer();
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_rounded),
          label: 'Módulos',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Ajustes',
        ),
      ],
    );
  }
}

IconData _getModuleIcon(AppModule module) {
  switch (module) {
    case AppModule.operatividad:
      return Icons.assignment_rounded;
    case AppModule.crm:
      return Icons.people_alt_rounded;
    case AppModule.inventario:
      return Icons.inventory_2_rounded;
    case AppModule.ventas:
      return Icons.point_of_sale_rounded;
    case AppModule.marketing:
      return Icons.campaign_rounded;
    case AppModule.soporte:
      return Icons.support_agent_rounded;
    case AppModule.proyectos:
      return Icons.account_tree_rounded;
    default:
      return Icons.apps_rounded;
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: LOADING & ERROR STATES
// ══════════════════════════════════════════════════════════════

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                'Cargando dashboard...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
                Text(
                  'Error al cargar',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.md),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Cerrar sesión'),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.md),
          Text(
            'No se encontraron módulos',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Intenta con otra búsqueda',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
