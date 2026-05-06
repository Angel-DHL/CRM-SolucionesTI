// lib/marketing/pages/marketing_home_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/marketing_enums.dart';
import '../models/social_metrics.dart';
import '../services/marketing_service.dart';
import 'campaigns_list_page.dart';
import 'campaign_form_page.dart';
import 'audience_page.dart';
import 'social_metrics_page.dart';
import 'website_metrics_page.dart';
import 'marketing_reports_page.dart';

class MarketingHomePage extends StatefulWidget {
  const MarketingHomePage({super.key});

  @override
  State<MarketingHomePage> createState() => _MarketingHomePageState();
}

class _MarketingHomePageState extends State<MarketingHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final stats = await MarketingService.instance.getDashboardStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Marketing'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primaryLight,
          indicatorWeight: 3,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            Tab(icon: Icon(Icons.campaign_rounded), text: 'Campañas'),
            Tab(icon: Icon(Icons.people_rounded), text: 'Audiencias'),
            Tab(icon: Icon(Icons.share_rounded), text: 'Redes Sociales'),
            Tab(icon: Icon(Icons.language_rounded), text: 'Sitio Web'),
            Tab(icon: Icon(Icons.assessment_rounded), text: 'Reportes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTab(stats: _stats, loading: _loading, onRefresh: _loadStats),
          const CampaignsListPage(),
          const AudiencePage(),
          const SocialMetricsPage(),
          const WebsiteMetricsPage(),
          const MarketingReportsPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CampaignFormPage()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Campaña'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DASHBOARD TAB
// ═══════════════════════════════════════════════════════════

class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool loading;
  final VoidCallback onRefresh;

  const _DashboardTab({required this.stats, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dashboard de Marketing',
                    style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // KPIs Grid - 4 columnas
            _buildKpiGrid(context),
            const SizedBox(height: AppDimensions.xl),

            // Gráficos
            _buildChartsSection(context),
            const SizedBox(height: AppDimensions.xl),

            // Alertas
            _buildAlertsSection(context),
            const SizedBox(height: AppDimensions.xl),

            // Plataformas sociales resumen
            _buildSocialOverview(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 1200 ? 4 : (width > 800 ? 3 : 2);

    final kpis = [
      _KpiData('Campañas Activas', '${stats['campanasActivas'] ?? 0}', Icons.campaign_rounded, AppColors.primary, '+${stats['campanasActivas'] ?? 0} este mes'),
      _KpiData('Presupuesto', '\$${_fmt(stats['totalPresupuesto'] ?? 0)}', Icons.account_balance_wallet_rounded, const Color(0xFF4A90D9), 'Gastado: \$${_fmt(stats['totalGasto'] ?? 0)}'),
      _KpiData('Leads Generados', '${stats['totalLeads'] ?? 0}', Icons.people_alt_rounded, AppColors.success, 'Este mes: ${stats['leadsEsteMes'] ?? 0}'),
      _KpiData('Tasa Conversión', '${(stats['tasaConversion'] ?? 0.0).toStringAsFixed(1)}%', Icons.trending_up_rounded, const Color(0xFFE8A838), '${stats['totalConversiones'] ?? 0} conversiones'),
      _KpiData('ROI Promedio', '${(stats['roiPromedio'] ?? 0.0).toStringAsFixed(1)}%', Icons.show_chart_rounded, (stats['roiPromedio'] ?? 0.0) >= 0 ? AppColors.success : AppColors.error, (stats['roiPromedio'] ?? 0.0) >= 0 ? 'Rentable' : 'Negativo'),
      _KpiData('Alcance Total', _fmtNum(stats['totalAlcance'] ?? 0), Icons.visibility_rounded, const Color(0xFF9B59B6), 'Impresiones totales'),
      _KpiData('Seguidores', _fmtNum(stats['seguidoresTotales'] ?? 0), Icons.group_rounded, const Color(0xFF1877F2), '+${stats['nuevosSeguidoresSemana'] ?? 0} esta semana'),
      _KpiData('Costo/Lead', '\$${(stats['costoPorLead'] ?? 0.0).toStringAsFixed(2)}', Icons.monetization_on_rounded, const Color(0xFFE74C3C), 'Promedio global'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 1.8,
        crossAxisSpacing: AppDimensions.md,
        mainAxisSpacing: AppDimensions.md,
      ),
      itemCount: kpis.length,
      itemBuilder: (ctx, i) => _KpiCard(data: kpis[i]),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rendimiento', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppDimensions.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Funnel de conversión
            Expanded(child: _FunnelChart(stats: stats)),
            const SizedBox(width: AppDimensions.md),
            // Distribución por canal
            Expanded(child: _ChannelDistribution()),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertsSection(BuildContext context) {
    final alerts = <Widget>[];

    final gasto = (stats['totalGasto'] ?? 0.0) as double;
    final presupuesto = (stats['totalPresupuesto'] ?? 0.0) as double;
    if (presupuesto > 0 && gasto > presupuesto * 0.9) {
      alerts.add(_AlertTile(
        icon: Icons.warning_rounded,
        color: AppColors.warning,
        title: 'Presupuesto al límite',
        subtitle: 'Has gastado el ${(gasto / presupuesto * 100).toStringAsFixed(0)}% del presupuesto total',
      ));
    }

    final roi = (stats['roiPromedio'] ?? 0.0) as double;
    if (roi < 0) {
      alerts.add(_AlertTile(
        icon: Icons.trending_down_rounded,
        color: AppColors.error,
        title: 'ROI Negativo',
        subtitle: 'El ROI promedio es ${roi.toStringAsFixed(1)}%. Revisa tus campañas',
      ));
    }

    if (alerts.isEmpty) {
      alerts.add(_AlertTile(
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        title: 'Todo en orden',
        subtitle: 'No hay alertas activas en este momento',
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertas', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppDimensions.md),
        ...alerts,
      ],
    );
  }

  Widget _buildSocialOverview(BuildContext context) {
    final latestMetrics = stats['latestMetrics'] as Map<SocialPlatform, SocialMetrics>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Redes Sociales — Resumen', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppDimensions.md),
        if (latestMetrics.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(children: [
              Icon(Icons.share_rounded, size: 48, color: AppColors.textHint),
              const SizedBox(height: AppDimensions.md),
              Text('No hay métricas registradas aún', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
              const SizedBox(height: AppDimensions.sm),
              Text('Ve a la pestaña "Redes Sociales" para registrar o sincronizar métricas', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
            ]),
          )
        else
          Wrap(
            spacing: AppDimensions.md,
            runSpacing: AppDimensions.md,
            children: latestMetrics.entries.map((e) => _SocialCard(platform: e.key, metrics: e.value)).toList(),
          ),
      ],
    );
  }

  String _fmt(dynamic value) {
    if (value is double) return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    return value.toString();
  }

  String _fmtNum(dynamic value) {
    final n = (value is int) ? value : (value as double).toInt();
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  _KpiData(this.title, this.value, this.icon, this.color, this.subtitle);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(data.value, style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          Text(data.title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(data.subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textHint, fontSize: 11)),
        ],
      ),
    );
  }
}

class _FunnelChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _FunnelChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final alcance = (stats['totalAlcance'] ?? 0) as int;
    final leads = (stats['totalLeads'] ?? 0) as int;
    final conversiones = (stats['totalConversiones'] ?? 0) as int;

    final maxVal = alcance > 0 ? alcance.toDouble() : 1.0;

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
          Text('Funnel de Conversión', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.lg),
          _FunnelBar('Alcance', alcance, maxVal, const Color(0xFF4A90D9)),
          const SizedBox(height: AppDimensions.md),
          _FunnelBar('Leads', leads, maxVal, AppColors.primaryLight),
          const SizedBox(height: AppDimensions.md),
          _FunnelBar('Conversiones', conversiones, maxVal, AppColors.success),
        ],
      ),
    );
  }
}

class _FunnelBar extends StatelessWidget {
  final String label;
  final int value;
  final double maxVal;
  final Color color;

  const _FunnelBar(this.label, this.value, this.maxVal, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = maxVal > 0 ? (value / maxVal).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            Text('$value', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }
}

class _ChannelDistribution extends StatelessWidget {
  const _ChannelDistribution();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<CampaignChannel, int>>(
      future: MarketingService.instance.getLeadsByChannel(),
      builder: (context, snap) {
        final data = snap.data ?? {};

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
              Text('Leads por Canal', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppDimensions.lg),
              if (data.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Center(
                    child: Text('Sin datos', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                  ),
                )
              else
                ...data.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                  child: Row(
                    children: [
                      Icon(e.key.icon, color: e.key.color, size: 18),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(child: Text(e.key.label, style: AppTextStyles.bodySmall)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: e.key.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${e.value}', style: AppTextStyles.labelSmall.copyWith(color: e.key.color)),
                      ),
                    ],
                  ),
                )),
            ],
          ),
        );
      },
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _AlertTile({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge.copyWith(color: color)),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  final SocialPlatform platform;
  final SocialMetrics metrics;

  const _SocialCard({required this.platform, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(platform.icon, color: platform.color, size: 24),
              const SizedBox(width: AppDimensions.sm),
              Text(platform.label, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            '${metrics.seguidores + metrics.suscriptores}',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
          Text('seguidores', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              Icon(
                metrics.nuevosSeguidores >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: metrics.nuevosSeguidores >= 0 ? AppColors.success : AppColors.error,
                size: 14,
              ),
              Text(
                '+${metrics.nuevosSeguidores}',
                style: AppTextStyles.caption.copyWith(
                  color: metrics.nuevosSeguidores >= 0 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              if (metrics.isFromApi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('API', style: TextStyle(fontSize: 9, color: AppColors.info)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
