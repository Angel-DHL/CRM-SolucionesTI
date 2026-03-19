// lib/operatividad/widgets/operatividad_dashboard.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/oper_activity.dart';

import 'charts/collaborator_workload_chart.dart';
import 'charts/compliance_gauge.dart';
import 'charts/status_pie_chart.dart';
import 'charts/time_comparison_chart.dart';
import 'charts/weekly_trend_chart.dart';
import 'report_config_dialog.dart';
import 'collaborator_home_view.dart';
import 'charts/collaborator_metrics_view.dart';
import 'charts/monthly_comparison_chart.dart';
import 'charts/workload_prediction_view.dart';
import '../services/metrics_service.dart';

class OperatividadDashboard extends StatefulWidget {
  final List<OperActivity> activities;
  final UserRole role;
  final ValueChanged<OperActivity> onActivityTap;

  const OperatividadDashboard({
    super.key,
    required this.activities,
    required this.role,
    required this.onActivityTap,
  });

  @override
  State<OperatividadDashboard> createState() => _OperatividadDashboardState();
}

class _OperatividadDashboardState extends State<OperatividadDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Estadísticas calculadas
  int get _totalActivities => widget.activities.length;

  int get _completedActivities => widget.activities
      .where(
        (a) => a.status == OperStatus.done || a.status == OperStatus.verified,
      )
      .length;

  int get _inProgressActivities =>
      widget.activities.where((a) => a.status == OperStatus.inProgress).length;

  int get _blockedActivities =>
      widget.activities.where((a) => a.status == OperStatus.blocked).length;

  int get _plannedActivities =>
      widget.activities.where((a) => a.status == OperStatus.planned).length;

  double get _completionRate => _totalActivities > 0
      ? (_completedActivities / _totalActivities) * 100
      : 0;

  List<OperActivity> get _overdueActivities {
    final now = DateTime.now();
    return widget.activities.where((a) {
      return a.plannedEndAt.isBefore(now) &&
          a.status != OperStatus.done &&
          a.status != OperStatus.verified;
    }).toList();
  }

  List<OperActivity> get _upcomingActivities {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return widget.activities.where((a) {
      return a.plannedStartAt.isAfter(now) &&
          a.plannedStartAt.isBefore(weekFromNow) &&
          a.status == OperStatus.planned;
    }).toList()..sort((a, b) => a.plannedStartAt.compareTo(b.plannedStartAt));
  }

  List<OperActivity> get _myRecentActivities {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return widget.activities
        .where((a) => a.assigneesUids.contains(uid))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ✅ AGREGAR ESTE MÉTODO a la clase _OperatividadDashboardState:
  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReportConfigDialog(activities: widget.activities),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (widget.role != UserRole.admin) {
      return CollaboratorHomeView(
        activities: widget.activities,
        onActivityTap: widget.onActivityTap,
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPIs principales
          _buildKPIsSection(isMobile),
          SizedBox(height: isMobile ? AppDimensions.lg : AppDimensions.xl),

          // ✅ NUEVA SECCIÓN: Analítica con gráficas
          _buildAnalyticsSection(isMobile),
          SizedBox(height: isMobile ? AppDimensions.lg : AppDimensions.xl),

          // Actividades vencidas (si hay)
          if (_overdueActivities.isNotEmpty) ...[
            _buildOverdueSection(isMobile),
            SizedBox(height: isMobile ? AppDimensions.lg : AppDimensions.xl),
          ],

          // Layout de dos columnas en desktop
          if (isMobile) ...[
            _buildUpcomingSection(),
            const SizedBox(height: AppDimensions.lg),
            _buildRecentActivitySection(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildUpcomingSection()),
                const SizedBox(width: AppDimensions.lg),
                Expanded(child: _buildRecentActivitySection()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildKPIsSection(bool isMobile) {
    final kpis = [
      _KPIData(
        title: 'Total',
        value: _totalActivities.toString(),
        icon: Icons.assignment_rounded,
        color: AppColors.primary,
        subtitle: 'actividades',
      ),
      _KPIData(
        title: 'Completadas',
        value: _completedActivities.toString(),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        subtitle: '${_completionRate.toStringAsFixed(0)}% del total',
      ),
      _KPIData(
        title: 'En progreso',
        value: _inProgressActivities.toString(),
        icon: Icons.pending_actions_rounded,
        color: AppColors.warning,
        subtitle: 'activas ahora',
      ),
      _KPIData(
        title: 'Bloqueadas',
        value: _blockedActivities.toString(),
        icon: Icons.block_rounded,
        color: AppColors.error,
        subtitle: 'requieren atención',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de actividades',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: AppDimensions.md,
            mainAxisSpacing: AppDimensions.md,
            childAspectRatio: isMobile ? 1.4 : 1.6,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, index) {
            return _AnimatedKPICard(
              data: kpis[index],
              delay: index * 100,
              animation: _animController,
            );
          },
        ),
      ],
    );
  }

  // ✅ AGREGAR ESTE NUEVO MÉTODO:
  Widget _buildAnalyticsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Row(
          children: [
            Icon(Icons.analytics_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Text(
                'Analítica operativa',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // ✅ NUEVO: Botón de reporte
            FilledButton.icon(
              onPressed: () => _showReportDialog(context),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: Text(isMobile ? 'PDF' : 'Generar reporte'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppDimensions.md : AppDimensions.lg,
                  vertical: AppDimensions.sm,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.lg),

        

        // Fila 1: Pie chart + Cumplimiento
        if (isMobile) ...[
          StatusPieChart(activities: widget.activities),
          const SizedBox(height: AppDimensions.md),
          ComplianceGauge(activities: widget.activities),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: StatusPieChart(activities: widget.activities),
              ),
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                flex: 2,
                child: ComplianceGauge(activities: widget.activities),
              ),
            ],
          ),

        const SizedBox(height: AppDimensions.lg),

        // Fila 2: Tendencia semanal
        WeeklyTrendChart(activities: widget.activities),

        const SizedBox(height: AppDimensions.lg),

        // Fila 3: Tiempo + Colaboradores
        if (isMobile) ...[
          TimeComparisonChart(activities: widget.activities),
          const SizedBox(height: AppDimensions.md),
          CollaboratorWorkloadChart(activities: widget.activities),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TimeComparisonChart(activities: widget.activities),
              ),
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                child: CollaboratorWorkloadChart(activities: widget.activities),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

// ✅ Comparativo mensual
MonthlyComparisonChart(activities: widget.activities),

const SizedBox(height: AppDimensions.lg),

// ✅ Productividad por colaborador
CollaboratorMetricsView(
  activities: widget.activities,
  previousPeriodActivities: _getPreviousPeriodActivities(),
),

const SizedBox(height: AppDimensions.lg),

// ✅ Predicción de carga
WorkloadPredictionView(activities: widget.activities),

// Agregar el método helper:
List<OperActivity> _getPreviousPeriodActivities() {
  final now = DateTime.now();
  final currentMonthStart = DateTime(now.year, now.month, 1);
  final previousMonthStart = DateTime(now.year, now.month - 1, 1);

  return widget.activities.where((a) {
    return a.plannedStartAt.isAfter(previousMonthStart) &&
        a.plannedStartAt.isBefore(currentMonthStart);
  }).toList();
}
      ],
    );
  }

  Widget _buildProgressSection(bool isMobile) {
    final statusDistribution = {
      OperStatus.planned: _plannedActivities,
      OperStatus.inProgress: _inProgressActivities,
      OperStatus.done: _completedActivities,
      OperStatus.blocked: _blockedActivities,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distribución por estado',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                    vertical: AppDimensions.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    '${_completionRate.toStringAsFixed(1)}% completado',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Barra de progreso segmentada
            _SegmentedProgressBar(
              segments: statusDistribution,
              total: _totalActivities,
              animation: _animController,
            ),

            const SizedBox(height: AppDimensions.lg),

            // Leyenda
            Wrap(
              spacing: AppDimensions.lg,
              runSpacing: AppDimensions.sm,
              children: statusDistribution.entries.map((entry) {
                return _LegendItem(
                  status: entry.key,
                  count: entry.value,
                  total: _totalActivities,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueSection(bool isMobile) {
    return Card(
      elevation: 0,
      color: AppColors.errorLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actividades vencidas',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_overdueActivities.length} actividades requieren atención inmediata',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            ...(_overdueActivities.take(3).map((activity) {
              return _OverdueActivityItem(
                activity: activity,
                onTap: () => widget.onActivityTap(activity),
              );
            })),
            if (_overdueActivities.length > 3)
              TextButton(
                onPressed: () {
                  // Mostrar todas las vencidas
                },
                child: Text('Ver todas (${_overdueActivities.length})'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upcoming_rounded, color: AppColors.info, size: 24),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Próximas actividades',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            if (_upcomingActivities.isEmpty)
              _EmptyStateSmall(
                icon: Icons.event_available_rounded,
                message: 'No hay actividades próximas',
              )
            else
              ...(_upcomingActivities.take(5).map((activity) {
                return _UpcomingActivityItem(
                  activity: activity,
                  onTap: () => widget.onActivityTap(activity),
                );
              })),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Mis actividades recientes',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            if (_myRecentActivities.isEmpty)
              _EmptyStateSmall(
                icon: Icons.assignment_ind_rounded,
                message: 'No tienes actividades asignadas',
              )
            else
              ...(_myRecentActivities.take(5).map((activity) {
                return _RecentActivityItem(
                  activity: activity,
                  onTap: () => widget.onActivityTap(activity),
                );
              })),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: KPI Cards
// ══════════════════════════════════════════════════════════════

class _KPIData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  _KPIData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}

class _AnimatedKPICard extends StatelessWidget {
  final _KPIData data;
  final int delay;
  final AnimationController animation;

  const _AnimatedKPICard({
    required this.data,
    required this.delay,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final delayedValue = ((animation.value - (delay / 1000)) * 2).clamp(
          0.0,
          1.0,
        );
        return Transform.translate(
          offset: Offset(0, 20 * (1 - delayedValue)),
          child: Opacity(opacity: delayedValue, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(data.icon, color: data.color, size: 20),
                ),
                Text(
                  data.title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              data.value,
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
            Text(
              data.subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: Progress Bar Segmentado
// ══════════════════════════════════════════════════════════════

class _SegmentedProgressBar extends StatelessWidget {
  final Map<OperStatus, int> segments;
  final int total;
  final AnimationController animation;

  const _SegmentedProgressBar({
    required this.segments,
    required this.total,
    required this.animation,
  });

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

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Container(
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: Container(
            height: 12,
            color: AppColors.divider,
            // ✅ CAMBIAR Row por LayoutBuilder para calcular el ancho disponible
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;

                return Row(
                  children: segments.entries.map((entry) {
                    if (entry.value == 0) return const SizedBox.shrink();

                    final percentage = entry.value / total;
                    // ✅ Calcular el ancho basado en el espacio disponible real
                    final segmentWidth =
                        availableWidth * percentage * animation.value;

                    return Container(
                      width: segmentWidth,
                      color: _getStatusColor(entry.key),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final OperStatus status;
  final int count;
  final int total;

  const _LegendItem({
    required this.status,
    required this.count,
    required this.total,
  });

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

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0
        ? (count / total * 100).toStringAsFixed(0)
        : '0';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppDimensions.xs),
        Text(
          '${status.label} ($count - $percentage%)',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGETS: Activity Items
// ══════════════════════════════════════════════════════════════

class _OverdueActivityItem extends StatelessWidget {
  final OperActivity activity;
  final VoidCallback onTap;

  const _OverdueActivityItem({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysOverdue = DateTime.now().difference(activity.plannedEndAt).inDays;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Vencida hace $daysOverdue días',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.error),
          ],
        ),
      ),
    );
  }
}

class _UpcomingActivityItem extends StatelessWidget {
  final OperActivity activity;
  final VoidCallback onTap;

  const _UpcomingActivityItem({required this.activity, required this.onTap});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Mañana';
    } else {
      return 'En ${difference.inDays} días';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        decoration: BoxDecoration(
          color: AppColors.primarySurface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(Icons.event_rounded, color: AppColors.info, size: 20),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatDate(activity.plannedStartAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  final OperActivity activity;
  final VoidCallback onTap;

  const _RecentActivityItem({required this.activity, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(activity.status),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      _StatusBadgeSmall(status: activity.status),
                      const SizedBox(width: AppDimensions.sm),
                      Text(
                        '${activity.progress}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _StatusBadgeSmall extends StatelessWidget {
  final OperStatus status;

  const _StatusBadgeSmall({required this.status});

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

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _EmptyStateSmall extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateSmall({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: AppDimensions.md),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
