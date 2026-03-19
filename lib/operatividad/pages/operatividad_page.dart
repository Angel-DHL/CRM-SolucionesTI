import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crm_solucionesti/operatividad/widgets/report_config_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/oper_activity.dart';
import '../widgets/operatividad_dashboard.dart';
import '../widgets/operatividad_kanban_view.dart';
import '../widgets/operatividad_calendar_view.dart';
import '../widgets/operatividad_gantt_view.dart';
import '../widgets/operatividad_list_view.dart';
import '../widgets/operatividad_filters.dart';
import 'activity_detail_page.dart';
import 'admin_create_activity_page.dart';
import '../../core/firebase_helper.dart';
import '../widgets/notifications_panel.dart';
import '../services/notification_service.dart';

enum OperView { dashboard, kanban, calendar, gantt, list }

class OperatividadPage extends StatefulWidget {
  const OperatividadPage({super.key});

  @override
  State<OperatividadPage> createState() => _OperatividadPageState();
}

class _OperatividadPageState extends State<OperatividadPage>
    with SingleTickerProviderStateMixin {
  UserRole? _role;
  bool _loadingRole = true;
  OperView _currentView = OperView.dashboard;

  // Filtros
  final Set<OperStatus> _statusFilters = {};
  final Set<String> _assigneeFilters = {};
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _searchQuery = '';

  late AnimationController _viewTransitionController;

  @override
  void initState() {
    super.initState();
    _loadRole();
    // 🔍 Debug temporal - verificar usuario
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('═══════════════════════════════════════');
    debugPrint('🚀 OperatividadPage initState');
    debugPrint('👤 Email: ${user?.email}');
    debugPrint('🆔 UID: ${user?.uid}');
    debugPrint('═══════════════════════════════════════');
    _viewTransitionController = AnimationController(
      vsync: this,
      duration: AppDimensions.animNormal,
    );
  }

  @override
  void dispose() {
    _viewTransitionController.dispose();
    super.dispose();
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

  void _showReportDialog(BuildContext context) {
    // Necesitas acceder a las actividades actuales
    // Si ya tienes un stream, puedes usar las actividades del StreamBuilder
    showDialog(
      context: context,
      builder: (ctx) => StreamBuilder(
        stream: _buildQuery(_role ?? UserRole.soporteTecnico).snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final activities = docs.map(OperActivity.fromDoc).toList();

          return ReportConfigDialog(activities: activities);
        },
      ),
    );
  }

  Query<Map<String, dynamic>> _buildQuery(UserRole role) {
    // ✅ USAR FirebaseHelper en lugar de FirebaseFirestore.instance
    final col = FirebaseHelper.operActivities;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    debugPrint('═══════════════════════════════════════');
    debugPrint('🔍 Construyendo query');
    debugPrint('👤 Rol: ${role.label}');
    debugPrint('🆔 UID: $uid');
    debugPrint('🗄️ Database: ${FirebaseHelper.databaseId}');
    debugPrint('═══════════════════════════════════════');

    if (role == UserRole.admin) {
      return col.orderBy('plannedStartAt', descending: false);
    }

    if (uid == null) {
      debugPrint('⚠️ No hay usuario autenticado');
      return col.where('assigneesUids', arrayContains: 'INVALID_UID_NO_USER');
    }

    return col.where('assigneesUids', arrayContains: uid);
  }

  List<OperActivity> _applyClientFilters(List<OperActivity> activities) {
    var filtered = activities;

    // Filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        final query = _searchQuery.toLowerCase();
        return a.title.toLowerCase().contains(query) ||
            a.description.toLowerCase().contains(query) ||
            a.assigneesEmails.any((e) => e.toLowerCase().contains(query));
      }).toList();
    }

    // Filtro de asignados
    if (_assigneeFilters.isNotEmpty) {
      filtered = filtered.where((a) {
        return a.assigneesUids.any((uid) => _assigneeFilters.contains(uid));
      }).toList();
    }

    // Filtro de rango de fechas
    if (_filterStartDate != null) {
      filtered = filtered.where((a) {
        return a.plannedStartAt.isAfter(_filterStartDate!);
      }).toList();
    }

    if (_filterEndDate != null) {
      filtered = filtered.where((a) {
        return a.plannedEndAt.isBefore(_filterEndDate!);
      }).toList();
    }

    return filtered;
  }

  void _changeView(OperView view) {
    if (_currentView == view) return;
    setState(() => _currentView = view);
    _viewTransitionController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const _LoadingSkeleton();
    }

    final role = _role ?? UserRole.soporteTecnico;
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, role, isMobile),
      drawer: isMobile ? _buildDrawer(role) : null,
      floatingActionButton: role == UserRole.admin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateActivityDialog(context),
              icon: const Icon(Icons.add_task_rounded),
              label: Text(isMobile ? 'Nueva' : 'Nueva actividad'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Row(
        children: [
          // Sidebar (solo desktop)
          if (isDesktop) _buildSidebar(role),

          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Barra de filtros y búsqueda
                _buildFilterBar(context),

                // Vista seleccionada
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _buildQuery(role).snapshots(),
                    builder: (context, snapshot) {
                      // 🔍 Debug logs
                      debugPrint('📡 Estado: ${snapshot.connectionState}');

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        // 🔍 Mostrar error exacto para debugging
                        debugPrint('💥 Error Firestore: ${snapshot.error}');
                        return _ErrorView(
                          message: 'Error al cargar actividades',
                          onRetry: () => setState(() {}),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      debugPrint('📄 Documentos encontrados: ${docs.length}');

                      // Convertir documentos a modelo
                      var activities = docs.map(OperActivity.fromDoc).toList();

                      // ✅ ORDENAR EN EL CLIENTE (ya que quitamos orderBy de la query)
                      activities.sort(
                        (a, b) => a.plannedStartAt.compareTo(b.plannedStartAt),
                      );

                      // Aplicar filtros adicionales
                      activities = _applyClientFilters(activities);

                      // 🔍 Debug
                      for (var a in activities) {
                        debugPrint(
                          '📋 ${a.title} - Asignados: ${a.assigneesUids}',
                        );
                      }

                      if (activities.isEmpty) {
                        return _EmptyView(
                          currentView: _currentView,
                          hasFilters:
                              _searchQuery.isNotEmpty ||
                              _statusFilters.isNotEmpty ||
                              _assigneeFilters.isNotEmpty,
                          onClearFilters: () {
                            setState(() {
                              _searchQuery = '';
                              _statusFilters.clear();
                              _assigneeFilters.clear();
                              _filterStartDate = null;
                              _filterEndDate = null;
                            });
                          },
                        );
                      }

                      return AnimatedSwitcher(
                        duration: AppDimensions.animFast,
                        child: _buildCurrentView(
                          activities,
                          role,
                          Responsive.isMobile(context),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    UserRole role,
    bool isMobile,
  ) {
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
                child: Icon(
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
                Icons.dashboard_customize_rounded,
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
                'Operatividad',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!isMobile)
                Text(
                  'Gestión de actividades',
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
        // ✅ NUEVO: Badge de notificaciones
        NotificationBadge(onTap: () => _showNotificationsPanel(context)),
        const SizedBox(width: AppDimensions.sm),
      ],
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 60, right: AppDimensions.md),
          child: Material(
            color: Colors.transparent,
            child: NotificationsPanel(
              onNotificationTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
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
            isSelected: _currentView == OperView.dashboard,
            onTap: () => _changeView(OperView.dashboard),
          ),
          _ViewButton(
            icon: Icons.view_kanban_rounded,
            label: 'Kanban',
            isSelected: _currentView == OperView.kanban,
            onTap: () => _changeView(OperView.kanban),
          ),
          _ViewButton(
            icon: Icons.calendar_month_rounded,
            label: 'Calendario',
            isSelected: _currentView == OperView.calendar,
            onTap: () => _changeView(OperView.calendar),
          ),
          _ViewButton(
            icon: Icons.timeline_rounded,
            label: 'Gantt',
            isSelected: _currentView == OperView.gantt,
            onTap: () => _changeView(OperView.gantt),
          ),
          _ViewButton(
            icon: Icons.list_rounded,
            label: 'Lista',
            isSelected: _currentView == OperView.list,
            onTap: () => _changeView(OperView.list),
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
          // View selector vertical
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VISTAS',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                _SidebarViewItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: _currentView == OperView.dashboard,
                  onTap: () => _changeView(OperView.dashboard),
                ),
                _SidebarViewItem(
                  icon: Icons.view_kanban_rounded,
                  label: 'Kanban',
                  isSelected: _currentView == OperView.kanban,
                  onTap: () => _changeView(OperView.kanban),
                ),
                _SidebarViewItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Calendario',
                  isSelected: _currentView == OperView.calendar,
                  onTap: () => _changeView(OperView.calendar),
                ),
                _SidebarViewItem(
                  icon: Icons.timeline_rounded,
                  label: 'Gantt',
                  isSelected: _currentView == OperView.gantt,
                  onTap: () => _changeView(OperView.gantt),
                ),
                _SidebarViewItem(
                  icon: Icons.list_rounded,
                  label: 'Lista',
                  isSelected: _currentView == OperView.list,
                  onTap: () => _changeView(OperView.list),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Quick filters
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FILTROS RÁPIDOS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  _QuickFilterChip(
                    label: 'Mis tareas',
                    icon: Icons.person_rounded,
                    onTap: () {
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      setState(() {
                        _assigneeFilters.clear();
                        _assigneeFilters.add(uid);
                      });
                    },
                  ),
                  _QuickFilterChip(
                    label: 'En progreso',
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.warning,
                    onTap: () {
                      setState(() {
                        _statusFilters.clear();
                        _statusFilters.add(OperStatus.inProgress);
                      });
                    },
                  ),
                  _QuickFilterChip(
                    label: 'Urgentes',
                    icon: Icons.priority_high_rounded,
                    color: AppColors.error,
                    onTap: () {
                      // Implementar filtro de prioridad cuando lo agregues
                    },
                  ),
                  _QuickFilterChip(
                    label: 'Esta semana',
                    icon: Icons.date_range_rounded,
                    onTap: () {
                      final now = DateTime.now();
                      setState(() {
                        _filterStartDate = now;
                        _filterEndDate = now.add(const Duration(days: 7));
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(UserRole role) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
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
                      Icons.dashboard_customize_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Text(
                    'Operatividad',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.md),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isSelected: _currentView == OperView.dashboard,
                    onTap: () {
                      _changeView(OperView.dashboard);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.view_kanban_rounded,
                    label: 'Kanban',
                    isSelected: _currentView == OperView.kanban,
                    onTap: () {
                      _changeView(OperView.kanban);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Calendario',
                    isSelected: _currentView == OperView.calendar,
                    onTap: () {
                      _changeView(OperView.calendar);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.timeline_rounded,
                    label: 'Gantt',
                    isSelected: _currentView == OperView.gantt,
                    onTap: () {
                      _changeView(OperView.gantt);
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.list_rounded,
                    label: 'Lista',
                    isSelected: _currentView == OperView.list,
                    onTap: () {
                      _changeView(OperView.list);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hasActiveFilters =
        _searchQuery.isNotEmpty ||
        _statusFilters.isNotEmpty ||
        _assigneeFilters.isNotEmpty ||
        _filterStartDate != null ||
        _filterEndDate != null;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Búsqueda
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar actividades...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppColors.textHint,
                                size: 20,
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                      ),
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
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ),

              const SizedBox(width: AppDimensions.md),

              // Botón de filtros
              IconButton(
                onPressed: () => _showFiltersSheet(context),
                icon: Badge(
                  isLabelVisible: hasActiveFilters,
                  label: Text(
                    '${_statusFilters.length + _assigneeFilters.length + (_filterStartDate != null ? 1 : 0) + (_filterEndDate != null ? 1 : 0)}',
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: hasActiveFilters
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                tooltip: 'Filtros',
              ),

              if (!isMobile)
                IconButton(
                  onPressed: () => _showReportDialog(context),
                  icon: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Generar reporte PDF',
                ),
            ],
          ),

          // Active filters chips
          if (hasActiveFilters) ...[
            const SizedBox(height: AppDimensions.sm),
            Wrap(
              spacing: AppDimensions.sm,
              runSpacing: AppDimensions.sm,
              children: [
                if (_searchQuery.isNotEmpty)
                  _FilterChip(
                    label: 'Búsqueda: "$_searchQuery"',
                    onRemove: () => setState(() => _searchQuery = ''),
                  ),
                ..._statusFilters.map(
                  (status) => _FilterChip(
                    label: status.label,
                    color: _getStatusColor(status),
                    onRemove: () =>
                        setState(() => _statusFilters.remove(status)),
                  ),
                ),
                if (hasActiveFilters)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _statusFilters.clear();
                        _assigneeFilters.clear();
                        _filterStartDate = null;
                        _filterEndDate = null;
                      });
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Limpiar filtros'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentView(
    List<OperActivity> activities,
    UserRole role,
    bool isMobile,
  ) {
    switch (_currentView) {
      case OperView.dashboard:
        return OperatividadDashboard(
          activities: activities,
          role: role,
          onActivityTap: _navigateToDetail,
        );
      case OperView.kanban:
        return OperatividadKanbanView(
          activities: activities,
          onActivityTap: _navigateToDetail,
          onStatusChange: _handleStatusChange,
        );
      case OperView.calendar:
        return OperatividadCalendarView(
          activities: activities,
          onActivityTap: _navigateToDetail,
          onDateSelected: (date) {
            // Handle date selection
          },
        );
      case OperView.gantt:
        return OperatividadGanttView(
          activities: activities,
          onActivityTap: _navigateToDetail,
        );
      case OperView.list:
        return OperatividadListView(
          activities: activities,
          role: role,
          onActivityTap: _navigateToDetail,
        );
    }
  }

  void _navigateToDetail(OperActivity activity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActivityDetailPage(activityId: activity.id),
      ),
    );
  }

  Future<void> _handleStatusChange(
    OperActivity activity,
    OperStatus newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('oper_activities')
          .doc(activity.id)
          .update({
            'status': newStatus.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a ${newStatus.label}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => OperatividadFilters(
        statusFilters: _statusFilters,
        assigneeFilters: _assigneeFilters,
        filterStartDate: _filterStartDate,
        filterEndDate: _filterEndDate,
        onApply: (status, assignees, startDate, endDate) {
          setState(() {
            _statusFilters.clear();
            _statusFilters.addAll(status);
            _assigneeFilters.clear();
            _assigneeFilters.addAll(assignees);
            _filterStartDate = startDate;
            _filterEndDate = endDate;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCreateActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: AdminCreateActivityPage(
              onCreated: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Actividad creada exitosamente'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OperStatus status) {
    switch (status) {
      case OperStatus.planned:
        return AppColors.info;
      case OperStatus.inProgress:
        return AppColors.warning;
      case OperStatus.done:
        return AppColors.success;
      case OperStatus.verified:
        return AppColors.primary;
      case OperStatus.blocked:
        return AppColors.error;
    }
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: UI Components
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

class _SidebarViewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarViewItem({
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

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Material(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: chipColor),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: chipColor,
                    fontWeight: FontWeight.w500,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, this.color, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return Chip(
      label: Text(label),
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: chipColor,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: chipColor.withOpacity(0.1),
      deleteIcon: Icon(Icons.close_rounded, size: 16, color: chipColor),
      onDeleted: onRemove,
      side: BorderSide(color: chipColor.withOpacity(0.3)),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
          const SizedBox(height: AppDimensions.lg),
          Text(
            message,
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.lg),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final OperView currentView;
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyView({
    required this.currentView,
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_alt_off_rounded : Icons.inbox_rounded,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppDimensions.lg),
          Text(
            hasFilters
                ? 'No hay actividades que coincidan'
                : 'No hay actividades',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            hasFilters
                ? 'Intenta con otros filtros'
                : 'Crea tu primera actividad',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          if (hasFilters) ...[
            const SizedBox(height: AppDimensions.lg),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ],
      ),
    );
  }
}
