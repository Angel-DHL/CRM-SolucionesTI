// lib/proyectos/pages/project_dashboard_page.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/project.dart';
import '../models/project_enums.dart';
import '../services/project_service.dart';

class ProjectDashboardPage extends StatelessWidget {
  final UserRole role;
  const ProjectDashboardPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final isMobile = Responsive.isMobile(context);

    return StreamBuilder<ProjectStats>(
      stream: ProjectService.instance.streamStats(),
      builder: (context, statsSnap) {
        final stats = statsSnap.data ?? const ProjectStats();

        return StreamBuilder<List<Project>>(
          stream: ProjectService.instance.streamProjects(),
          builder: (context, projectsSnap) {
            final projects = projectsSnap.data ?? [];

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Cards
                  _buildKpiCards(stats, nf, isMobile),
                  const SizedBox(height: AppDimensions.xl),

                  // Charts row
                  if (!isMobile)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildStatusChart(stats)),
                        const SizedBox(width: AppDimensions.lg),
                        Expanded(flex: 4, child: _buildFinancialChart(projects, nf)),
                      ],
                    )
                  else ...[
                    _buildStatusChart(stats),
                    const SizedBox(height: AppDimensions.lg),
                    _buildFinancialChart(projects, nf),
                  ],

                  const SizedBox(height: AppDimensions.xl),

                  // Proyectos recientes y atrasados
                  if (!isMobile)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRecentProjects(projects)),
                        const SizedBox(width: AppDimensions.lg),
                        Expanded(child: _buildOverdueProjects(projects)),
                      ],
                    )
                  else ...[
                    _buildRecentProjects(projects),
                    const SizedBox(height: AppDimensions.lg),
                    _buildOverdueProjects(projects),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // KPI CARDS
  // ═══════════════════════════════════════════════════════════

  Widget _buildKpiCards(ProjectStats stats, NumberFormat nf, bool isMobile) {
    final cards = [
      _KpiData('Activos', '${stats.activosCount}', Icons.play_circle_rounded, AppColors.primaryMedium),
      _KpiData('Completados', '${stats.completadosCount}', Icons.check_circle_rounded, AppColors.success),
      _KpiData('Atrasados', '${stats.proyectosAtrasados}', Icons.warning_rounded, AppColors.error),
      _KpiData('Valor Total', nf.format(stats.valorTotalProyectos), Icons.attach_money_rounded, AppColors.info),
      _KpiData('Ingresos', nf.format(stats.totalIngresos), Icons.trending_up_rounded, AppColors.success),
      _KpiData('Egresos', nf.format(stats.totalEgresos), Icons.trending_down_rounded, AppColors.error),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppDimensions.sm,
        crossAxisSpacing: AppDimensions.sm,
        childAspectRatio: 1.6,
        children: cards.map(_buildKpiCard).toList(),
      );
    }

    return Row(
      children: cards.map((data) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildKpiCard(data),
        ),
      )).toList(),
    );
  }

  Widget _buildKpiCard(_KpiData data) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(data.icon, size: 18, color: data.color),
            ),
            const Spacer(),
          ]),
          const SizedBox(height: AppDimensions.sm),
          Text(data.value, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(data.label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STATUS PIE CHART
  // ═══════════════════════════════════════════════════════════

  Widget _buildStatusChart(ProjectStats stats) {
    final sections = <PieChartSectionData>[
      _pieSection(stats.planificacionCount.toDouble(), ProjectStatus.planificacion.color, 'Plan.'),
      _pieSection(stats.activosCount.toDouble(), ProjectStatus.enProgreso.color, 'Activos'),
      _pieSection(stats.pausadosCount.toDouble(), ProjectStatus.pausado.color, 'Pausados'),
      _pieSection(stats.completadosCount.toDouble(), ProjectStatus.completado.color, 'Complet.'),
      _pieSection(stats.canceladosCount.toDouble(), ProjectStatus.cancelado.color, 'Cancel.'),
    ].where((s) => s.value > 0).toList();

    if (sections.isEmpty) {
      sections.add(_pieSection(1, AppColors.divider, 'Sin datos'));
    }

    return _buildCard(
      title: 'Distribución por Estado',
      child: SizedBox(
        height: 220,
        child: Row(children: [
          Expanded(child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          ))),
          const SizedBox(width: AppDimensions.md),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendItem('Planificación', ProjectStatus.planificacion.color, stats.planificacionCount),
              _legendItem('En Progreso', ProjectStatus.enProgreso.color, stats.activosCount),
              _legendItem('Pausados', ProjectStatus.pausado.color, stats.pausadosCount),
              _legendItem('Completados', ProjectStatus.completado.color, stats.completadosCount),
              _legendItem('Cancelados', ProjectStatus.cancelado.color, stats.canceladosCount),
            ],
          ),
        ]),
      ),
    );
  }

  PieChartSectionData _pieSection(double value, Color color, String title) {
    return PieChartSectionData(
      value: value,
      color: color,
      radius: 30,
      title: value > 0 ? '${value.toInt()}' : '',
      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _legendItem(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text('$label ($count)', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FINANCIAL BAR CHART
  // ═══════════════════════════════════════════════════════════

  Widget _buildFinancialChart(List<Project> projects, NumberFormat nf) {
    final activeProjects = projects
        .where((p) => p.status != ProjectStatus.cancelado && p.valorProyecto > 0)
        .take(6)
        .toList();

    return _buildCard(
      title: 'Top Proyectos por Valor',
      child: SizedBox(
        height: 220,
        child: activeProjects.isEmpty
            ? Center(child: Text('Sin datos', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)))
            : BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: activeProjects.fold<double>(0, (m, p) => p.valorProyecto > m ? p.valorProyecto : m) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(nf.format(rod.toY), const TextStyle(color: Colors.white, fontSize: 11));
                    },
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx >= activeProjects.length) return const SizedBox();
                      final name = activeProjects[idx].nombre;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(name.length > 8 ? '${name.substring(0, 8)}…' : name,
                          style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
                      );
                    },
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 50,
                    getTitlesWidget: (v, meta) => Text(nf.format(v), style: const TextStyle(fontSize: 8, color: AppColors.textHint)),
                  )),
                ),
                barGroups: activeProjects.asMap().entries.map((e) {
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value.valorProyecto,
                      color: e.value.status.color,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ]);
                }).toList(),
              )),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LISTAS
  // ═══════════════════════════════════════════════════════════

  Widget _buildRecentProjects(List<Project> projects) {
    final recent = projects.take(5).toList();
    return _buildCard(
      title: 'Proyectos Recientes',
      child: Column(
        children: recent.isEmpty
            ? [Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Text('Sin proyectos', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)))]
            : recent.map((p) => _projectTile(p)).toList(),
      ),
    );
  }

  Widget _buildOverdueProjects(List<Project> projects) {
    final overdue = projects.where((p) => p.estaAtrasado).take(5).toList();
    return _buildCard(
      title: 'Proyectos Atrasados',
      titleColor: AppColors.error,
      child: Column(
        children: overdue.isEmpty
            ? [Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Text('Todo al día 🎉', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
              ]))]
            : overdue.map((p) => _projectTile(p, showDelay: true)).toList(),
      ),
    );
  }

  Widget _projectTile(Project p, {bool showDelay = false}) {
    final df = DateFormat('dd MMM yyyy', 'es_MX');
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: p.status.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.nombre, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(p.clienteNombre, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 11)),
          ],
        )),
        if (showDelay && p.diasRestantes < 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(4)),
            child: Text('${p.diasRestantes.abs()}d', style: const TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w600)),
          )
        else
          Text('${p.progreso}%', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CARD WRAPPER
  // ═══════════════════════════════════════════════════════════

  Widget _buildCard({required String title, required Widget child, Color? titleColor}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600, color: titleColor ?? AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.md),
          child,
        ],
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.value, this.icon, this.color);
}
