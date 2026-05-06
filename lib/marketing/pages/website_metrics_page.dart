// lib/marketing/pages/website_metrics_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/social_metrics.dart';
import '../models/marketing_enums.dart';
import '../services/marketing_service.dart';

class WebsiteMetricsPage extends StatefulWidget {
  const WebsiteMetricsPage({super.key});

  @override
  State<WebsiteMetricsPage> createState() => _WebsiteMetricsPageState();
}

class _WebsiteMetricsPageState extends State<WebsiteMetricsPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(child: Text('Métricas del Sitio Web', style: AppTextStyles.h3)),
              // GA4 sync pendiente
              OutlinedButton.icon(
                onPressed: null,  // GA4 pendiente de configurar
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Sync GA4'),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4285F4)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _showManualForm(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Registrar Manual'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: AppColors.info, size: 20),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'La sincronización automática con Google Analytics 4 estará disponible cuando se configure el archivo de credenciales de Service Account.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // KPIs del sitio web
          StreamBuilder<List<SocialMetrics>>(
            stream: MarketingService.instance.streamMetrics(platform: SocialPlatform.sitioWeb, limit: 1),
            builder: (context, snap) {
              final latest = snap.data?.isNotEmpty == true ? snap.data!.first : null;
              return _WebsiteKpis(metrics: latest);
            },
          ),
          const SizedBox(height: AppDimensions.xl),

          // Historial
          Text('Historial de Métricas', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.md),

          StreamBuilder<List<SocialMetrics>>(
            stream: MarketingService.instance.streamMetrics(platform: SocialPlatform.sitioWeb, limit: 30),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
              }
              final metrics = snap.data ?? [];
              if (metrics.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.divider)),
                  child: Column(children: [
                    Icon(Icons.language_rounded, size: 48, color: AppColors.textHint.withOpacity(0.3)),
                    const SizedBox(height: AppDimensions.md),
                    Text('No hay métricas del sitio web', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                  ]),
                );
              }

              return Column(
                children: metrics.map((m) => _WebMetricCard(metric: m, onDelete: () => MarketingService.instance.deleteMetric(m.id))).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showManualForm(BuildContext context) {
    final usuariosCtrl = TextEditingController();
    final sesionesCtrl = TextEditingController();
    final paginasCtrl = TextEditingController();
    final bounceCtrl = TextEditingController();
    final duracionCtrl = TextEditingController();
    final conversionesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🌐 Métricas del Sitio Web'),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(child: TextField(controller: usuariosCtrl, decoration: const InputDecoration(labelText: 'Usuarios'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: sesionesCtrl, decoration: const InputDecoration(labelText: 'Sesiones'), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: paginasCtrl, decoration: const InputDecoration(labelText: 'Páginas vistas'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: bounceCtrl, decoration: const InputDecoration(labelText: 'Bounce Rate %'), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: duracionCtrl, decoration: const InputDecoration(labelText: 'Duración sesión (seg)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: conversionesCtrl, decoration: const InputDecoration(labelText: 'Conversiones'), keyboardType: TextInputType.number)),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final metric = SocialMetrics(
                id: '',
                plataforma: SocialPlatform.sitioWeb,
                fecha: DateTime.now(),
                periodo: MetricPeriod.mensual,
                usuarios: int.tryParse(usuariosCtrl.text) ?? 0,
                sesiones: int.tryParse(sesionesCtrl.text) ?? 0,
                impresiones: int.tryParse(paginasCtrl.text) ?? 0,
                bounceRate: double.tryParse(bounceCtrl.text) ?? 0,
                duracionSesion: double.tryParse(duracionCtrl.text) ?? 0,
                conversiones: int.tryParse(conversionesCtrl.text) ?? 0,
                fuenteDatos: 'manual',
                createdAt: DateTime.now(),
              );
              await MarketingService.instance.addMetric(metric);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _WebsiteKpis extends StatelessWidget {
  final SocialMetrics? metrics;
  const _WebsiteKpis({this.metrics});

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Row(
      children: [
        _WebKpi('Usuarios', m != null ? '${m.usuarios}' : '—', Icons.person_rounded, const Color(0xFF4285F4)),
        const SizedBox(width: AppDimensions.md),
        _WebKpi('Sesiones', m != null ? '${m.sesiones}' : '—', Icons.browse_gallery_rounded, const Color(0xFF34A853)),
        const SizedBox(width: AppDimensions.md),
        _WebKpi('Bounce Rate', m != null ? '${m.bounceRate.toStringAsFixed(1)}%' : '—', Icons.exit_to_app_rounded, const Color(0xFFEA4335)),
        const SizedBox(width: AppDimensions.md),
        _WebKpi('Duración', m != null ? '${m.duracionSesion.toStringAsFixed(0)}s' : '—', Icons.timer_rounded, const Color(0xFFFBBC05)),
        const SizedBox(width: AppDimensions.md),
        _WebKpi('Páginas', m != null ? '${m.impresiones}' : '—', Icons.web_rounded, const Color(0xFF9B59B6)),
        const SizedBox(width: AppDimensions.md),
        _WebKpi('Conversiones', m != null ? '${m.conversiones}' : '—', Icons.check_circle_rounded, AppColors.success),
      ],
    );
  }
}

class _WebKpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _WebKpi(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

class _WebMetricCard extends StatelessWidget {
  final SocialMetrics metric;
  final VoidCallback onDelete;

  const _WebMetricCard({required this.metric, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), side: BorderSide(color: AppColors.divider)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Row(
          children: [
            Icon(Icons.language_rounded, color: AppColors.primaryLight, size: 24),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${metric.fecha.day}/${metric.fecha.month}/${metric.fecha.year}', style: AppTextStyles.labelMedium),
                  Text(metric.isFromApi ? 'Fuente: GA4 API' : 'Fuente: Manual', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                ],
              ),
            ),
            _MiniStat('Usuarios', '${metric.usuarios}'),
            _MiniStat('Sesiones', '${metric.sesiones}'),
            _MiniStat('Bounce', '${metric.bounceRate.toStringAsFixed(1)}%'),
            _MiniStat('Conv.', '${metric.conversiones}'),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.close_rounded, size: 18), color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
