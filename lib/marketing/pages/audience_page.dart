// lib/marketing/pages/audience_page.dart


import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/campaign_audience.dart';
import '../models/marketing_enums.dart';
import '../services/marketing_service.dart';

class AudiencePage extends StatelessWidget {
  const AudiencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Row(
            children: [
              Expanded(child: Text('Segmentos de Audiencia', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary))),
              FilledButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva Audiencia'),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<CampaignAudience>>(
            stream: MarketingService.instance.streamAudiences(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final audiences = snap.data ?? [];
              if (audiences.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.people_rounded, size: 64, color: AppColors.textHint.withOpacity(0.3)),
                    const SizedBox(height: AppDimensions.md),
                    Text('Sin audiencias definidas', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                  ]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
                itemCount: audiences.length,
                itemBuilder: (ctx, i) => _AudienceCard(audience: audiences[i], onEdit: () => _showForm(context, audiences[i]), onDelete: () => _delete(context, audiences[i])),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showForm(BuildContext context, [CampaignAudience? audience]) {
    final isEdit = audience != null;
    final nombreCtrl = TextEditingController(text: audience?.nombre ?? '');
    final descCtrl = TextEditingController(text: audience?.descripcion ?? '');
    final tamanioCtrl = TextEditingController(text: '${audience?.tamanioEstimado ?? 0}');
    var segmento = audience?.segmento ?? AudienceSegment.todos;

    // Criterios
    final industriaCtrl = TextEditingController(text: (audience?.criterios['industria'] ?? '') as String);
    final ubicacionCtrl = TextEditingController(text: (audience?.criterios['ubicacion'] ?? '') as String);
    final edadCtrl = TextEditingController(text: (audience?.criterios['edad'] ?? '') as String);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar Audiencia' : 'Nueva Audiencia'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *')),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AudienceSegment>(
                    value: segmento,
                    decoration: const InputDecoration(labelText: 'Segmento'),
                    items: AudienceSegment.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                    onChanged: (v) => setDialogState(() => segmento = v ?? segmento),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: tamanioCtrl, decoration: const InputDecoration(labelText: 'Tamaño estimado'), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerLeft, child: Text('Criterios', style: AppTextStyles.labelLarge)),
                  const SizedBox(height: 8),
                  TextField(controller: industriaCtrl, decoration: const InputDecoration(labelText: 'Industria')),
                  const SizedBox(height: 8),
                  TextField(controller: ubicacionCtrl, decoration: const InputDecoration(labelText: 'Ubicación')),
                  const SizedBox(height: 8),
                  TextField(controller: edadCtrl, decoration: const InputDecoration(labelText: 'Rango de edad')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty) return;
                final data = {
                  'nombre': nombreCtrl.text.trim(),
                  'descripcion': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  'segmento': segmento.value,
                  'tamanioEstimado': int.tryParse(tamanioCtrl.text) ?? 0,
                  'criterios': {
                    'industria': industriaCtrl.text.trim(),
                    'ubicacion': ubicacionCtrl.text.trim(),
                    'edad': edadCtrl.text.trim(),
                  },
                };
                if (isEdit) {
                  await MarketingService.instance.updateAudience(audience.id, data);
                } else {
                  await MarketingService.instance.createAudience(data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _delete(BuildContext context, CampaignAudience audience) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Audiencia'),
        content: Text('¿Eliminar "${audience.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) await MarketingService.instance.deleteAudience(audience.id);
  }
}

class _AudienceCard extends StatelessWidget {
  final CampaignAudience audience;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AudienceCard({required this.audience, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg), side: BorderSide(color: AppColors.divider)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
              child: const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: AppDimensions.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(audience.nombre, style: AppTextStyles.labelLarge),
                  Text(audience.segmento.label, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  if (audience.descripcion != null) Text(audience.descripcion!, style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                ],
              ),
            ),
            Column(
              children: [
                Text('${audience.tamanioEstimado}', style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                Text('estimados', style: AppTextStyles.caption.copyWith(color: AppColors.textHint, fontSize: 10)),
              ],
            ),
            const SizedBox(width: AppDimensions.md),
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 20), color: AppColors.textSecondary),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_rounded, size: 20), color: AppColors.error),
          ],
        ),
      ),
    );
  }
}
