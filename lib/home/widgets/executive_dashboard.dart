// lib/home/widgets/executive_dashboard.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/services/ai_global_service.dart';
import '../services/dashboard_service.dart';

class ExecutiveDashboard extends StatefulWidget {
  const ExecutiveDashboard({super.key});
  @override
  State<ExecutiveDashboard> createState() => _ExecutiveDashboardState();
}

class _ExecutiveDashboardState extends State<ExecutiveDashboard> {
  DashboardKPIs _kpis = const DashboardKPIs();
  bool _loading = true;
  List<ChartDataPoint> _operChart = [];
  List<ChartDataPoint> _salesChart = [];
  List<ChartDataPoint> _pipelineChart = [];
  List<ChartDataPoint> _supportChart = [];
  List<Map<String, dynamic>> _overdueList = [];
  List<Map<String, dynamic>> _recentQuotes = [];
  List<Map<String, dynamic>> _urgentCases = [];
  String? _aiSummary;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final svc = DashboardService.instance;
    final results = await Future.wait([
      svc.loadKPIs(forceRefresh: true),
      svc.getOperatividadChart(),
      svc.getMonthlySalesChart(),
      svc.getSalesPipelineChart(),
      svc.getSupportChart(),
      svc.getOverdueActivities(),
      svc.getRecentQuotes(),
      svc.getUrgentCases(),
    ]);
    if (!mounted) return;
    setState(() {
      _kpis = results[0] as DashboardKPIs;
      _operChart = results[1] as List<ChartDataPoint>;
      _salesChart = results[2] as List<ChartDataPoint>;
      _pipelineChart = results[3] as List<ChartDataPoint>;
      _supportChart = results[4] as List<ChartDataPoint>;
      _overdueList = results[5] as List<Map<String, dynamic>>;
      _recentQuotes = results[6] as List<Map<String, dynamic>>;
      _urgentCases = results[7] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  Future<void> _generateAiSummary() async {
    setState(() => _aiLoading = true);
    final summary = await AiGlobalService.instance.generateExecutiveSummary(_kpis.toMap());
    if (mounted) setState(() { _aiSummary = summary; _aiLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final pad = isMobile ? AppDimensions.md : AppDimensions.xl;

    if (_loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildKPIGrid(isMobile),
          SizedBox(height: pad),
          _buildChartsRow(isMobile),
          SizedBox(height: pad),
          _buildSecondaryChartsRow(isMobile),
          SizedBox(height: pad),
          _buildActionLists(isMobile),
          SizedBox(height: pad),
          _buildAiSection(),
        ]),
      ),
    );
  }

  // ═══════════════ KPI GRID ═══════════════

  Widget _buildKPIGrid(bool isMobile) {
    final kpis = [
      _KPI('Actividades', '${_kpis.activeActivities}', Icons.assignment_rounded, AppColors.primary, 'Operatividad'),
      _KPI('Vencidas', '${_kpis.overdueActivities}', Icons.warning_rounded, _kpis.overdueActivities > 0 ? AppColors.error : AppColors.success, 'Atención'),
      _KPI('Proyectos', '${_kpis.activeProjects}', Icons.folder_rounded, const Color(0xFF8B5CF6), 'Activos'),
      _KPI('Ventas Mes', '\$${_formatNum(_kpis.monthlySales)}', Icons.attach_money_rounded, AppColors.success, 'Ingresos'),
      _KPI('Cotizaciones', '${_kpis.openQuotes}', Icons.description_rounded, const Color(0xFFF59E0B), 'Abiertas'),
      _KPI('Leads', '${_kpis.newLeads}', Icons.people_rounded, const Color(0xFF3B82F6), 'Este mes'),
      _KPI('Soporte', '${_kpis.openCases}', Icons.support_agent_rounded, const Color(0xFF6366F1), 'Abiertos'),
      _KPI('Inventario', '${_kpis.inventoryCount}', Icons.inventory_2_rounded, const Color(0xFF10B981), 'Productos'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isMobile ? 200 : 240,
        crossAxisSpacing: AppDimensions.md,
        mainAxisSpacing: AppDimensions.md,
        childAspectRatio: isMobile ? 1.2 : 1.5,
      ),
      itemCount: kpis.length,
      itemBuilder: (_, i) => _buildKPICard(kpis[i]),
    );
  }

  Widget _buildKPICard(_KPI kpi) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kpi.color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            child: Icon(kpi.icon, color: kpi.color, size: 20),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: kpi.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(kpi.subtitle, style: TextStyle(fontSize: 9, color: kpi.color, fontWeight: FontWeight.w600)),
          ),
        ]),
        const Spacer(),
        Text(kpi.value, style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(kpi.title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }

  // ═══════════════ CHARTS ROW 1 ═══════════════

  Widget _buildChartsRow(bool isMobile) {
    if (isMobile) {
      return Column(children: [
        _buildSalesLineChart(),
        const SizedBox(height: AppDimensions.md),
        _buildOperDonutChart(),
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 3, child: _buildSalesLineChart()),
      const SizedBox(width: AppDimensions.md),
      Expanded(flex: 2, child: _buildOperDonutChart()),
    ]);
  }

  Widget _buildSalesLineChart() {
    final maxY = _salesChart.isEmpty ? 10.0 : _salesChart.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;
    return _chartCard(
      title: 'Ventas Mensuales',
      icon: Icons.trending_up_rounded,
      height: 260,
      child: _salesChart.isEmpty
          ? const Center(child: Text('Sin datos de ventas'))
          : BarChart(BarChartData(
              maxY: maxY == 0 ? 10 : maxY,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (g, gi, r, ri) => BarTooltipItem('\$${_formatNum(r.toY)}', const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50,
                  getTitlesWidget: (v, _) => Text('\$${_formatNum(v)}', style: const TextStyle(fontSize: 9, color: AppColors.textHint)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(v.toInt() < _salesChart.length ? _salesChart[v.toInt()].label : '', style: const TextStyle(fontSize: 10, color: AppColors.textHint))))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(color: AppColors.divider, strokeWidth: 0.5)),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(_salesChart.length, (i) => BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: _salesChart[i].value, width: 20, color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
              ])),
            )),
    );
  }

  Widget _buildOperDonutChart() {
    final colors = [AppColors.info, AppColors.warning, AppColors.success, const Color(0xFF10B981), AppColors.error];
    final total = _operChart.fold<double>(0, (s, e) => s + e.value);
    return _chartCard(
      title: 'Operatividad',
      icon: Icons.donut_large_rounded,
      height: 260,
      child: _operChart.isEmpty
          ? const Center(child: Text('Sin datos'))
          : Column(children: [
              SizedBox(height: 150, child: PieChart(PieChartData(
                centerSpaceRadius: 35,
                sectionsSpace: 2,
                sections: List.generate(_operChart.length, (i) => PieChartSectionData(
                  value: _operChart[i].value,
                  color: colors[i % colors.length],
                  radius: 30,
                  title: '${(_operChart[i].value / (total == 0 ? 1 : total) * 100).toInt()}%',
                  titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                )),
              ))),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 4, children: List.generate(_operChart.length, (i) => Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Text('${_operChart[i].label} (${_operChart[i].value.toInt()})', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ]))),
            ]),
    );
  }

  // ═══════════════ CHARTS ROW 2 ═══════════════

  Widget _buildSecondaryChartsRow(bool isMobile) {
    if (isMobile) {
      return Column(children: [
        _buildPipelineChart(),
        const SizedBox(height: AppDimensions.md),
        _buildSupportChart(),
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _buildPipelineChart()),
      const SizedBox(width: AppDimensions.md),
      Expanded(child: _buildSupportChart()),
    ]);
  }

  Widget _buildPipelineChart() {
    final colors = [const Color(0xFF94A3B8), const Color(0xFF3B82F6), const Color(0xFF8B5CF6), const Color(0xFFF59E0B), const Color(0xFF10B981), AppColors.error];
    return _chartCard(
      title: 'Pipeline de Ventas',
      icon: Icons.filter_list_rounded,
      height: 200,
      child: _pipelineChart.isEmpty
          ? const Center(child: Text('Sin oportunidades'))
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_pipelineChart.length, (i) {
              final maxVal = _pipelineChart.map((e) => e.value).reduce((a, b) => a > b ? a : b);
              final pct = maxVal > 0 ? _pipelineChart[i].value / maxVal : 0.0;
              return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                SizedBox(width: 80, child: Text(_pipelineChart[i].label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                Expanded(child: Stack(children: [
                  Container(height: 20, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4))),
                  FractionallySizedBox(widthFactor: pct, child: Container(height: 20, decoration: BoxDecoration(
                    color: colors[i % colors.length], borderRadius: BorderRadius.circular(4)))),
                ])),
                const SizedBox(width: 8),
                Text('${_pipelineChart[i].value.toInt()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]));
            })),
    );
  }

  Widget _buildSupportChart() {
    final colors = [const Color(0xFF6366F1), const Color(0xFF3B82F6), const Color(0xFFF59E0B), const Color(0xFF10B981), AppColors.error, const Color(0xFF8B5CF6)];
    return _chartCard(
      title: 'Soporte por Categoría',
      icon: Icons.support_agent_rounded,
      height: 200,
      child: _supportChart.isEmpty
          ? const Center(child: Text('Sin casos'))
          : BarChart(BarChartData(
              maxY: (_supportChart.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.3).clamp(1, double.infinity),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                  getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(v.toInt() < _supportChart.length ? _supportChart[v.toInt()].label : '',
                      style: const TextStyle(fontSize: 9, color: AppColors.textHint), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)))),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(_supportChart.length, (i) => BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: _supportChart[i].value, width: 24, color: colors[i % colors.length],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
              ])),
            )),
    );
  }

  // ═══════════════ ACTION LISTS ═══════════════

  Widget _buildActionLists(bool isMobile) {
    if (isMobile) {
      return Column(children: [
        _buildListCard('Actividades Vencidas', Icons.warning_rounded, AppColors.error, _overdueList, (item) =>
          _listTile(item['title'] ?? '', 'Vencida hace ${item['daysOverdue']} días', AppColors.error)),
        const SizedBox(height: AppDimensions.md),
        _buildListCard('Últimas Cotizaciones', Icons.description_rounded, const Color(0xFFF59E0B), _recentQuotes, (item) =>
          _listTile('${item['folio']}', '${item['clientName']} — \$${_formatNum((item['total'] as num).toDouble())}', const Color(0xFFF59E0B))),
        const SizedBox(height: AppDimensions.md),
        _buildListCard('Casos Urgentes', Icons.support_agent_rounded, const Color(0xFF6366F1), _urgentCases, (item) =>
          _listTile(item['folio'] ?? '', item['titulo'] ?? '', const Color(0xFF6366F1))),
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _buildListCard('Actividades Vencidas', Icons.warning_rounded, AppColors.error, _overdueList, (item) =>
        _listTile(item['title'] ?? '', 'Vencida hace ${item['daysOverdue']} días', AppColors.error))),
      const SizedBox(width: AppDimensions.md),
      Expanded(child: _buildListCard('Últimas Cotizaciones', Icons.description_rounded, const Color(0xFFF59E0B), _recentQuotes, (item) =>
        _listTile('${item['folio']}', '${item['clientName']} — \$${_formatNum((item['total'] as num).toDouble())}', const Color(0xFFF59E0B)))),
      const SizedBox(width: AppDimensions.md),
      Expanded(child: _buildListCard('Casos Urgentes', Icons.support_agent_rounded, const Color(0xFF6366F1), _urgentCases, (item) =>
        _listTile(item['folio'] ?? '', item['titulo'] ?? '', const Color(0xFF6366F1)))),
    ]);
  }

  Widget _buildListCard(String title, IconData icon, Color color, List<Map<String, dynamic>> items, Widget Function(Map<String, dynamic>) builder) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('${items.length}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: AppDimensions.sm),
        if (items.isEmpty)
          Padding(padding: const EdgeInsets.all(AppDimensions.lg),
            child: Center(child: Text('Sin elementos', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint))))
        else
          ...items.map(builder),
      ]),
    );
  }

  Widget _listTile(String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.04), borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
      child: Row(children: [
        Container(width: 4, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: TextStyle(fontSize: 10, color: AppColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ═══════════════ AI SECTION ═══════════════

  Widget _buildAiSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF6366F1).withOpacity(0.06), const Color(0xFF8B5CF6).withOpacity(0.06)]),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Asistente IA Ejecutivo', style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700)),
            Text('Genera un resumen inteligente del estado de la empresa', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ])),
          _aiLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : FilledButton.icon(
                  onPressed: _generateAiSummary,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Generar Resumen'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                ),
        ]),
        if (_aiSummary != null) ...[
          const SizedBox(height: AppDimensions.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
            child: SelectableText(_aiSummary!, style: AppTextStyles.bodySmall.copyWith(height: 1.7)),
          ),
        ],
      ]),
    );
  }

  // ═══════════════ HELPERS ═══════════════

  Widget _chartCard({required String title, required IconData icon, required double height, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: AppDimensions.md),
        SizedBox(height: height, child: child),
      ]),
    );
  }

  String _formatNum(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
  }
}

class _KPI {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  const _KPI(this.title, this.value, this.icon, this.color, this.subtitle);
}
