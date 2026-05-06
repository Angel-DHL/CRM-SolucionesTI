// lib/marketing/pages/social_metrics_page.dart


import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/social_metrics.dart';
import '../models/marketing_enums.dart';
import '../services/marketing_service.dart';

class SocialMetricsPage extends StatefulWidget {
  const SocialMetricsPage({super.key});

  @override
  State<SocialMetricsPage> createState() => _SocialMetricsPageState();
}

class _SocialMetricsPageState extends State<SocialMetricsPage> {
  SocialPlatform? _selectedPlatform;
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con acciones
          Row(
            children: [
              Expanded(child: Text('Métricas de Redes Sociales', style: AppTextStyles.h3)),
              // Sync YouTube
              OutlinedButton.icon(
                onPressed: _syncing ? null : _syncYouTube,
                icon: _syncing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Sync YouTube'),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF0000)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _showManualForm(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Registrar Manual'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          // Platform overview cards
          _PlatformOverview(),
          const SizedBox(height: AppDimensions.xl),

          // Filtros
          Row(
            children: [
              Text('Historial', style: AppTextStyles.h3),
              const Spacer(),
              SegmentedButton<SocialPlatform?>(
                segments: [
                  const ButtonSegment(value: null, label: Text('Todas', style: TextStyle(fontSize: 12))),
                  ...SocialPlatform.values.where((p) => p != SocialPlatform.sitioWeb).map((p) => ButtonSegment(
                    value: p,
                    label: Text(p.label, style: const TextStyle(fontSize: 11)),
                    icon: Icon(p.icon, size: 16),
                  )),
                ],
                selected: {_selectedPlatform},
                onSelectionChanged: (s) => setState(() => _selectedPlatform = s.first),
                multiSelectionEnabled: false,
                showSelectedIcon: false,
                style: ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Metrics list
          StreamBuilder<List<SocialMetrics>>(
            stream: MarketingService.instance.streamMetrics(platform: _selectedPlatform, limit: 50),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
              }
              final metrics = (snap.data ?? []).where((m) => m.plataforma != SocialPlatform.sitioWeb).toList();
              if (metrics.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.xl),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.divider)),
                  child: Column(children: [
                    Icon(Icons.analytics_rounded, size: 48, color: AppColors.textHint.withOpacity(0.3)),
                    const SizedBox(height: AppDimensions.md),
                    Text('No hay métricas registradas', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                    const SizedBox(height: AppDimensions.sm),
                    Text('Usa "Sync YouTube" o "Registrar Manual" para agregar datos', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                  ]),
                );
              }

              return Column(
                children: metrics.map((m) => _MetricCard(metric: m, onDelete: () => _deleteMetric(m.id))).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _syncYouTube() async {
    setState(() => _syncing = true);
    try {
      final result = await MarketingService.instance.syncYouTubeMetrics();
      if (mounted) {
        if (result != null && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Métricas de YouTube sincronizadas'), backgroundColor: AppColors.success));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result?['error'] ?? 'No se pudo sincronizar'}'), backgroundColor: AppColors.error));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _deleteMetric(String id) async {
    await MarketingService.instance.deleteMetric(id);
  }

  void _showManualForm(BuildContext context) {
    var platform = SocialPlatform.facebook;
    final seguidoresCtrl = TextEditingController();
    final nuevosCtrl = TextEditingController();
    final alcanceCtrl = TextEditingController();
    final impresionesCtrl = TextEditingController();
    final likesCtrl = TextEditingController();
    final comentariosCtrl = TextEditingController();
    final compartidosCtrl = TextEditingController();
    final publicacionesCtrl = TextEditingController();
    final vistasCtrl = TextEditingController();
    final suscriptoresCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('📊 Registrar Métricas'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<SocialPlatform>(
                    value: platform,
                    decoration: const InputDecoration(labelText: 'Plataforma'),
                    items: SocialPlatform.values.where((p) => p != SocialPlatform.sitioWeb).map((p) => DropdownMenuItem(
                      value: p,
                      child: Row(children: [
                        Icon(p.icon, size: 18, color: p.color),
                        const SizedBox(width: 8),
                        Text(p.label),
                      ]),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => platform = v ?? platform),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: seguidoresCtrl, decoration: const InputDecoration(labelText: 'Seguidores'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: nuevosCtrl, decoration: const InputDecoration(labelText: 'Nuevos'), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: alcanceCtrl, decoration: const InputDecoration(labelText: 'Alcance'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: impresionesCtrl, decoration: const InputDecoration(labelText: 'Impresiones'), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: likesCtrl, decoration: const InputDecoration(labelText: 'Likes'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: comentariosCtrl, decoration: const InputDecoration(labelText: 'Comentarios'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: compartidosCtrl, decoration: const InputDecoration(labelText: 'Compartidos'), keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(controller: publicacionesCtrl, decoration: const InputDecoration(labelText: 'Publicaciones'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: vistasCtrl, decoration: const InputDecoration(labelText: 'Vistas (video)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: suscriptoresCtrl, decoration: const InputDecoration(labelText: 'Suscriptores'), keyboardType: TextInputType.number)),
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
                  plataforma: platform,
                  fecha: DateTime.now(),
                  periodo: MetricPeriod.mensual,
                  seguidores: int.tryParse(seguidoresCtrl.text) ?? 0,
                  nuevosSeguidores: int.tryParse(nuevosCtrl.text) ?? 0,
                  alcance: int.tryParse(alcanceCtrl.text) ?? 0,
                  impresiones: int.tryParse(impresionesCtrl.text) ?? 0,
                  likes: int.tryParse(likesCtrl.text) ?? 0,
                  comentarios: int.tryParse(comentariosCtrl.text) ?? 0,
                  compartidos: int.tryParse(compartidosCtrl.text) ?? 0,
                  publicaciones: int.tryParse(publicacionesCtrl.text) ?? 0,
                  vistas: int.tryParse(vistasCtrl.text) ?? 0,
                  suscriptores: int.tryParse(suscriptoresCtrl.text) ?? 0,
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
      ),
    );
  }
}

class _PlatformOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<SocialPlatform, SocialMetrics>>(
      future: MarketingService.instance.getLatestMetricsPerPlatform(),
      builder: (context, snap) {
        final data = snap.data ?? {};
        final platforms = SocialPlatform.values.where((p) => p != SocialPlatform.sitioWeb).toList();

        return Wrap(
          spacing: AppDimensions.md,
          runSpacing: AppDimensions.md,
          children: platforms.map((p) {
            final m = data[p];
            return Container(
              width: 180,
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: m != null ? p.color.withOpacity(0.3) : AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(p.icon, color: p.color, size: 22),
                    const SizedBox(width: 8),
                    Text(p.label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary)),
                    const Spacer(),
                    if (p.hasApi) Icon(Icons.api_rounded, size: 14, color: AppColors.info),
                  ]),
                  const SizedBox(height: AppDimensions.sm),
                  if (m != null) ...[
                    Text('${m.seguidores + m.suscriptores}', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Row(children: [
                      Icon(m.nuevosSeguidores >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: m.nuevosSeguidores >= 0 ? AppColors.success : AppColors.error),
                      const SizedBox(width: 4),
                      Text('+${m.nuevosSeguidores}', style: TextStyle(fontSize: 12, color: m.nuevosSeguidores >= 0 ? AppColors.success : AppColors.error)),
                    ]),
                    Text('Engagement: ${m.engagementRate.toStringAsFixed(1)}%', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                  ] else
                    Text('Sin datos', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final SocialMetrics metric;
  final VoidCallback onDelete;

  const _MetricCard({required this.metric, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = metric.plataforma;
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), side: BorderSide(color: AppColors.divider)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Row(
          children: [
            Icon(p.icon, color: p.color, size: 24),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(p.label, style: AppTextStyles.labelMedium),
                    const SizedBox(width: 8),
                    if (metric.isFromApi)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text('API', style: TextStyle(fontSize: 10, color: AppColors.info, fontWeight: FontWeight.w600)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.textHint.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text('Manual', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                      ),
                  ]),
                  Text('${metric.fecha.day}/${metric.fecha.month}/${metric.fecha.year}', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                ],
              ),
            ),
            _MiniStat('Seg.', '${metric.seguidores + metric.suscriptores}'),
            _MiniStat('Alc.', '${metric.alcance}'),
            _MiniStat('Eng.', '${metric.engagementRate.toStringAsFixed(1)}%'),
            _MiniStat('Pub.', '${metric.publicaciones}'),
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
