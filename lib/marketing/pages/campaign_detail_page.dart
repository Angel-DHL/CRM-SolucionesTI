// lib/marketing/pages/campaign_detail_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/marketing_campaign.dart';
import '../models/marketing_enums.dart';
import '../services/marketing_service.dart';
import 'campaign_form_page.dart';

class CampaignDetailPage extends StatelessWidget {
  final String campaignId;
  const CampaignDetailPage({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MarketingCampaign?>(
      stream: MarketingService.instance.streamCampaign(campaignId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final campaign = snapshot.data;
        if (campaign == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Campaña')),
            body: const Center(child: Text('Campaña no encontrada')),
          );
        }
        return _CampaignDetailView(campaign: campaign);
      },
    );
  }
}

class _CampaignDetailView extends StatelessWidget {
  final MarketingCampaign campaign;
  const _CampaignDetailView({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(campaign.folio),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CampaignFormPage(campaign: campaign),
            )),
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Editar',
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(context, action),
            itemBuilder: (_) => [
              if (campaign.status == CampaignStatus.borrador)
                const PopupMenuItem(value: 'activate', child: ListTile(leading: Icon(Icons.rocket_launch_rounded, color: Colors.green), title: Text('Activar'))),
              if (campaign.status == CampaignStatus.activa)
                const PopupMenuItem(value: 'pause', child: ListTile(leading: Icon(Icons.pause_rounded, color: Colors.orange), title: Text('Pausar'))),
              if (campaign.status == CampaignStatus.pausada)
                const PopupMenuItem(value: 'resume', child: ListTile(leading: Icon(Icons.play_arrow_rounded, color: Colors.green), title: Text('Reanudar'))),
              if (campaign.status != CampaignStatus.completada && campaign.status != CampaignStatus.cancelada)
                const PopupMenuItem(value: 'complete', child: ListTile(leading: Icon(Icons.check_circle_rounded, color: Colors.blue), title: Text('Completar'))),
              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_rounded, color: Colors.red), title: Text('Eliminar'))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _HeaderCard(campaign: campaign),
            const SizedBox(height: AppDimensions.lg),

            // KPIs
            _KpisSection(campaign: campaign),
            const SizedBox(height: AppDimensions.lg),

            // Presupuesto
            _BudgetSection(campaign: campaign),
            const SizedBox(height: AppDimensions.lg),

            // Objetivos vs Resultados
            _ObjectivesSection(campaign: campaign),
            const SizedBox(height: AppDimensions.lg),

            // Actualizar Resultados
            _UpdateResultsSection(campaign: campaign),
            const SizedBox(height: AppDimensions.lg),

            // Canales y Tags
            _ChannelsSection(campaign: campaign),
            const SizedBox(height: AppDimensions.lg),

            // Notas
            if (campaign.notas != null && campaign.notas!.isNotEmpty) ...[
              _NotesSection(campaign: campaign),
              const SizedBox(height: AppDimensions.lg),
            ],
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'activate':
        await MarketingService.instance.updateCampaignStatus(campaign.id, CampaignStatus.activa);
        break;
      case 'pause':
        await MarketingService.instance.updateCampaignStatus(campaign.id, CampaignStatus.pausada);
        break;
      case 'resume':
        await MarketingService.instance.updateCampaignStatus(campaign.id, CampaignStatus.activa);
        break;
      case 'complete':
        await MarketingService.instance.updateCampaignStatus(campaign.id, CampaignStatus.completada);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar campaña'),
            content: Text('¿Eliminar "${campaign.nombre}"? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Eliminar')),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await MarketingService.instance.deleteCampaign(campaign.id);
          Navigator.pop(context);
        }
        break;
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final MarketingCampaign campaign;
  const _HeaderCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryMedium]),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(campaign.tipo.icon, color: Colors.white70, size: 32),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign.nombre, style: AppTextStyles.h2.copyWith(color: Colors.white)),
                    Text('${campaign.folio} • ${campaign.tipo.label}', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${campaign.status.emoji} ${campaign.status.label}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (campaign.descripcion != null && campaign.descripcion!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.md),
            Text(campaign.descripcion!, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
          ],
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                '${campaign.fechaInicio.day}/${campaign.fechaInicio.month}/${campaign.fechaInicio.year}',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (campaign.fechaFin != null) ...[
                Text(' → ', style: TextStyle(color: Colors.white70)),
                Text('${campaign.fechaFin!.day}/${campaign.fechaFin!.month}/${campaign.fechaFin!.year}', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
              if (campaign.diasRestantes >= 0) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Text('${campaign.diasRestantes} días restantes', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _KpisSection extends StatelessWidget {
  final MarketingCampaign campaign;
  const _KpisSection({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiMini('Leads', '${campaign.leadsGenerados}', Icons.people_alt_rounded, AppColors.primary),
        const SizedBox(width: AppDimensions.md),
        _KpiMini('Conversiones', '${campaign.conversionesLogradas}', Icons.check_circle_rounded, AppColors.success),
        const SizedBox(width: AppDimensions.md),
        _KpiMini('ROI', '${campaign.roi.toStringAsFixed(1)}%', Icons.show_chart_rounded, campaign.roi >= 0 ? AppColors.success : AppColors.error),
        const SizedBox(width: AppDimensions.md),
        _KpiMini('Costo/Lead', '\$${campaign.costoPorLead.toStringAsFixed(2)}', Icons.monetization_on_rounded, AppColors.warning),
      ],
    );
  }
}

class _KpiMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiMini(this.label, this.value, this.icon, this.color);

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
            Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textHint, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _BudgetSection extends StatelessWidget {
  final MarketingCampaign campaign;
  const _BudgetSection({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final pct = campaign.progresoPpresupuesto;
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
          Text('💰 Presupuesto', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gastado', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text(
                '\$${campaign.gastoReal.toStringAsFixed(2)} / \$${campaign.presupuesto.toStringAsFixed(2)} ${campaign.moneda}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: campaign.superoPpresupuesto ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(campaign.superoPpresupuesto ? AppColors.error : AppColors.primary),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text('${pct.toStringAsFixed(0)}% del presupuesto', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _ObjectivesSection extends StatelessWidget {
  final MarketingCampaign campaign;
  const _ObjectivesSection({required this.campaign});

  @override
  Widget build(BuildContext context) {
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
          Text('🎯 Objetivos vs Resultados', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.md),
          _ObjectiveRow('Leads', campaign.leadsGenerados, campaign.objetivoLeads, AppColors.primary),
          _ObjectiveRow('Conversiones', campaign.conversionesLogradas, campaign.objetivoConversiones, AppColors.success),
          _ObjectiveRow('Alcance', campaign.alcanceReal, campaign.objetivoAlcance, AppColors.info),
        ],
      ),
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  final String label;
  final int actual;
  final int objetivo;
  final Color color;

  const _ObjectiveRow(this.label, this.actual, this.objetivo, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = objetivo > 0 ? (actual / objetivo).clamp(0.0, 1.5) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text('$actual / $objetivo', style: AppTextStyles.labelMedium.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateResultsSection extends StatefulWidget {
  final MarketingCampaign campaign;
  const _UpdateResultsSection({required this.campaign});

  @override
  State<_UpdateResultsSection> createState() => _UpdateResultsSectionState();
}

class _UpdateResultsSectionState extends State<_UpdateResultsSection> {
  late TextEditingController _leadsCtrl;
  late TextEditingController _convCtrl;
  late TextEditingController _alcanceCtrl;
  late TextEditingController _gastoCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _leadsCtrl = TextEditingController(text: '${widget.campaign.leadsGenerados}');
    _convCtrl = TextEditingController(text: '${widget.campaign.conversionesLogradas}');
    _alcanceCtrl = TextEditingController(text: '${widget.campaign.alcanceReal}');
    _gastoCtrl = TextEditingController(text: '${widget.campaign.gastoReal}');
  }

  @override
  void dispose() { _leadsCtrl.dispose(); _convCtrl.dispose(); _alcanceCtrl.dispose(); _gastoCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Actualizar Resultados', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppDimensions.md),
          Row(children: [
            Expanded(child: TextField(controller: _leadsCtrl, decoration: const InputDecoration(labelText: 'Leads', filled: true, fillColor: Colors.white), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _convCtrl, decoration: const InputDecoration(labelText: 'Conversiones', filled: true, fillColor: Colors.white), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _alcanceCtrl, decoration: const InputDecoration(labelText: 'Alcance', filled: true, fillColor: Colors.white), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _gastoCtrl, decoration: const InputDecoration(labelText: 'Gasto \$', filled: true, fillColor: Colors.white), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _updateResults,
              icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded, size: 18),
              label: const Text('Guardar Resultados'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateResults() async {
    setState(() => _saving = true);
    try {
      await MarketingService.instance.updateCampaignResults(
        widget.campaign.id,
        leads: int.tryParse(_leadsCtrl.text),
        conversiones: int.tryParse(_convCtrl.text),
        alcance: int.tryParse(_alcanceCtrl.text),
        gasto: double.tryParse(_gastoCtrl.text),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Resultados actualizados'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ChannelsSection extends StatelessWidget {
  final MarketingCampaign campaign;
  const _ChannelsSection({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📱 Canales', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          if (campaign.canales.isEmpty)
            Text('Sin canales definidos', style: AppTextStyles.caption.copyWith(color: AppColors.textHint))
          else
            Wrap(spacing: 8, runSpacing: 8, children: campaign.canales.map((c) => Chip(
              avatar: Icon(c.icon, size: 16, color: c.color),
              label: Text(c.label),
              backgroundColor: c.color.withOpacity(0.08),
              side: BorderSide.none,
            )).toList()),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  final MarketingCampaign campaign;
  const _NotesSection({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📝 Notas', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          Text(campaign.notas!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
