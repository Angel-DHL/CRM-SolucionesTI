// lib/soporte/pages/support_dashboard_page.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/support_case.dart';
import '../models/support_enums.dart';
import '../services/support_service.dart';

class SupportDashboardPage extends StatelessWidget {
  const SupportDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: SupportService.instance.getDashboardStats(),
      builder: (context, statsSnap) {
        if (statsSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = statsSnap.data ?? {};

        return StreamBuilder<List<SupportCase>>(
          stream: SupportService.instance.streamCases(),
          builder: (context, casesSnap) {
            final cases = casesSnap.data ?? [];

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpis(stats, isMobile),
                  const SizedBox(height: AppDimensions.xl),
                  if (!isMobile)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildStatusChart(stats)),
                        const SizedBox(width: AppDimensions.lg),
                        Expanded(flex: 4, child: _buildCategoryChart(stats)),
                      ],
                    )
                  else ...[
                    _buildStatusChart(stats),
                    const SizedBox(height: AppDimensions.lg),
                    _buildCategoryChart(stats),
                  ],
                  const SizedBox(height: AppDimensions.xl),
                  if (!isMobile)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRecentCases(cases)),
                        const SizedBox(width: AppDimensions.lg),
                        Expanded(child: _buildUrgentCases(cases)),
                      ],
                    )
                  else ...[
                    _buildRecentCases(cases),
                    const SizedBox(height: AppDimensions.lg),
                    _buildUrgentCases(cases),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKpis(Map<String, dynamic> stats, bool isMobile) {
    final avgMin = (stats['avgResolutionMinutes'] ?? 0.0) as double;
    String avgText;
    if (avgMin > 1440) {
      avgText = '${(avgMin / 1440).toStringAsFixed(1)}d';
    } else if (avgMin > 60) {
      avgText = '${(avgMin / 60).toStringAsFixed(1)}h';
    } else {
      avgText = '${avgMin.toInt()}m';
    }

    final cards = [
      _KpiData('Abiertos', '${stats['abiertos'] ?? 0}', Icons.fiber_new_rounded, AppColors.info),
      _KpiData('En Progreso', '${stats['enProgreso'] ?? 0}', Icons.sync_rounded, AppColors.primary),
      _KpiData('Resueltos', '${stats['resueltos'] ?? 0}', Icons.check_circle_rounded, AppColors.success),
      _KpiData('Urgentes', '${stats['urgentes'] ?? 0}', Icons.priority_high_rounded, AppColors.error),
      _KpiData('Tiempo Prom.', avgText, Icons.timer_rounded, AppColors.warning),
      _KpiData('Total', '${stats['total'] ?? 0}', Icons.confirmation_number_rounded, const Color(0xFF6366F1)),
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
      children: cards.map((d) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildKpiCard(d),
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
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(data.icon, size: 18, color: data.color),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(data.value, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(data.label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }

  Widget _buildStatusChart(Map<String, dynamic> stats) {
    final abiertos = (stats['abiertos'] ?? 0) as int;
    final enProgreso = (stats['enProgreso'] ?? 0) as int;
    final resueltos = (stats['resueltos'] ?? 0) as int;

    final sections = <PieChartSectionData>[
      if (abiertos > 0) PieChartSectionData(value: abiertos.toDouble(), color: CaseStatus.abierto.color, radius: 30, title: '$abiertos', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
      if (enProgreso > 0) PieChartSectionData(value: enProgreso.toDouble(), color: CaseStatus.enProgreso.color, radius: 30, title: '$enProgreso', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
      if (resueltos > 0) PieChartSectionData(value: resueltos.toDouble(), color: CaseStatus.resuelto.color, radius: 30, title: '$resueltos', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
    ];

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(value: 1, color: AppColors.divider, radius: 30, title: '', titleStyle: const TextStyle(fontSize: 0)));
    }

    return _buildCard(
      title: 'Distribución por Estado',
      child: SizedBox(
        height: 200,
        child: Row(children: [
          Expanded(child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 35,
            sectionsSpace: 2,
          ))),
          const SizedBox(width: AppDimensions.md),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legend('Abiertos', CaseStatus.abierto.color, abiertos),
              _legend('En Progreso', CaseStatus.enProgreso.color, enProgreso),
              _legend('Resueltos', CaseStatus.resuelto.color, resueltos),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildCategoryChart(Map<String, dynamic> stats) {
    final porCat = (stats['porCategoria'] as Map<String, int>?) ?? {};

    final entries = CaseCategory.values.where((c) => (porCat[c.value] ?? 0) > 0).toList();

    if (entries.isEmpty) {
      return _buildCard(
        title: 'Casos por Categoría',
        child: SizedBox(
          height: 200,
          child: Center(child: Text('Sin datos', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint))),
        ),
      );
    }

    return _buildCard(
      title: 'Casos por Categoría',
      child: SizedBox(
        height: 200,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: entries.fold<double>(0, (m, c) => (porCat[c.value] ?? 0) > m ? (porCat[c.value]!).toDouble() : m) * 1.3,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 30,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx >= entries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(entries[idx].label, style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
                );
              },
            )),
          ),
          barGroups: entries.asMap().entries.map((e) {
            final count = porCat[e.value.value] ?? 0;
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: const Color(0xFF6366F1),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]);
          }).toList(),
        )),
      ),
    );
  }

  Widget _buildRecentCases(List<SupportCase> cases) {
    final recent = cases.take(5).toList();
    return _buildCard(
      title: 'Casos Recientes',
      child: Column(
        children: recent.isEmpty
            ? [Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Text('Sin casos registrados', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)))]
            : recent.map(_caseTile).toList(),
      ),
    );
  }

  Widget _buildUrgentCases(List<SupportCase> cases) {
    final urgent = cases.where((c) => c.priority == CasePriority.urgente && c.isOpen).take(5).toList();
    return _buildCard(
      title: 'Casos Urgentes',
      titleColor: AppColors.error,
      child: Column(
        children: urgent.isEmpty
            ? [Padding(padding: const EdgeInsets.all(AppDimensions.lg), child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Text('Sin urgencias 🎉', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
              ]))]
            : urgent.map(_caseTile).toList(),
      ),
    );
  }

  Widget _caseTile(SupportCase c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(children: [
        Icon(c.status.icon, size: 18, color: c.status.color),
        const SizedBox(width: AppDimensions.sm),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.titulo, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${c.folio} • ${c.category.label}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 11)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: c.priority.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(c.priority.label, style: TextStyle(fontSize: 10, color: c.priority.color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _legend(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text('$label ($count)', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }

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
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.value, this.icon, this.color);
}
