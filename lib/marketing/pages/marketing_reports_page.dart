// lib/marketing/pages/marketing_reports_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/marketing_campaign.dart';
import '../services/marketing_service.dart';

class MarketingReportsPage extends StatefulWidget {
  const MarketingReportsPage({super.key});

  @override
  State<MarketingReportsPage> createState() => _MarketingReportsPageState();
}

class _MarketingReportsPageState extends State<MarketingReportsPage> {
  String _selectedReport = 'general';
  String _selectedPeriod = 'mes';
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reportes de Marketing', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.lg),

          // Selector de tipo de reporte
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo de Reporte', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppDimensions.md),
                Wrap(
                  spacing: AppDimensions.md,
                  runSpacing: AppDimensions.md,
                  children: [
                    _ReportOption('general', '📊 Reporte General', 'Resumen ejecutivo de todas las métricas'),
                    _ReportOption('campaigns', '🎯 Por Campaña', 'Rendimiento detallado por campaña'),
                    _ReportOption('social', '📱 Redes Sociales', 'Métricas de todas las plataformas'),
                    _ReportOption('website', '🌐 Sitio Web', 'Análisis de tráfico web'),
                    _ReportOption('roi', '💰 ROI Comparativo', 'Ranking de campañas por ROI'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Selector de periodo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Periodo', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppDimensions.md),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'mes', label: Text('Último Mes')),
                    ButtonSegment(value: 'trimestre', label: Text('Trimestre')),
                    ButtonSegment(value: 'semestre', label: Text('Semestre')),
                    ButtonSegment(value: 'anio', label: Text('Año')),
                  ],
                  selected: {_selectedPeriod},
                  onSelectionChanged: (s) => setState(() => _selectedPeriod = s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Preview del reporte
          _ReportPreview(reportType: _selectedReport, period: _selectedPeriod),
          const SizedBox(height: AppDimensions.lg),

          // Botón generar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _generating ? null : _generateReport,
              icon: _generating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Generar Reporte PDF'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ReportOption(String id, String title, String subtitle) {
    final selected = _selectedReport == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedReport = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.labelMedium.copyWith(color: selected ? AppColors.primary : AppColors.textPrimary)),
            Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textHint, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    setState(() => _generating = true);

    // Simular generación (aquí iría el PDF generator)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📄 Reporte generado. La funcionalidad de PDF se activará con la integración completa.'),
          backgroundColor: AppColors.info,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class _ReportPreview extends StatelessWidget {
  final String reportType;
  final String period;

  const _ReportPreview({required this.reportType, required this.period});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: MarketingService.instance.getDashboardStats(),
      builder: (context, snap) {
        final stats = snap.data ?? {};

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.xl),
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
                  Icon(Icons.preview_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Vista Previa del Reporte', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ],
              ),
              const Divider(height: 24),

              // Preview content basado en tipo
              _buildPreviewContent(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewContent(Map<String, dynamic> stats) {
    switch (reportType) {
      case 'general':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reporte General de Marketing', style: AppTextStyles.h3),
            Text('Periodo: ${_periodLabel}', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
            const SizedBox(height: AppDimensions.lg),
            _PreviewRow('Campañas activas', '${stats['campanasActivas'] ?? 0}'),
            _PreviewRow('Total de leads generados', '${stats['totalLeads'] ?? 0}'),
            _PreviewRow('Tasa de conversión', '${(stats['tasaConversion'] ?? 0.0).toStringAsFixed(1)}%'),
            _PreviewRow('ROI promedio', '${(stats['roiPromedio'] ?? 0.0).toStringAsFixed(1)}%'),
            _PreviewRow('Presupuesto gastado', '\$${(stats['totalGasto'] ?? 0.0).toStringAsFixed(2)}'),
            _PreviewRow('Seguidores totales', '${stats['seguidoresTotales'] ?? 0}'),
          ],
        );
      case 'roi':
        return FutureBuilder<List<MarketingCampaign>>(
          future: MarketingService.instance.getTopCampaigns(),
          builder: (context, snap) {
            final top = snap.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Campañas por ROI', style: AppTextStyles.h3),
                Text('Periodo: ${_periodLabel}', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                const SizedBox(height: AppDimensions.lg),
                if (top.isEmpty)
                  Text('Sin campañas con gasto registrado', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint))
                else
                  ...top.asMap().entries.map((e) => _PreviewRow(
                    '${e.key + 1}. ${e.value.nombre}',
                    'ROI: ${e.value.roi.toStringAsFixed(1)}% — \$${e.value.gastoReal.toStringAsFixed(0)}',
                  )),
              ],
            );
          },
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vista previa no disponible', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
            Text('El reporte completo se generará como PDF', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          ],
        );
    }
  }

  String get _periodLabel => switch (period) {
    'mes' => 'Último mes',
    'trimestre' => 'Último trimestre',
    'semestre' => 'Último semestre',
    'anio' => 'Último año',
    _ => period,
  };
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _PreviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
