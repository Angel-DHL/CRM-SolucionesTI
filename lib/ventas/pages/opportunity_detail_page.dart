// lib/ventas/pages/opportunity_detail_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/sale_opportunity.dart';
import '../models/ventas_enums.dart';
import '../services/ventas_service.dart';
import 'opportunity_form_page.dart';
import 'quote_form_page.dart';

class OpportunityDetailPage extends StatelessWidget {
  final String oppId;
  const OpportunityDetailPage({super.key, required this.oppId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SaleOpportunity?>(
      stream: VentasService.instance.streamOpportunity(oppId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final opp = snapshot.data;
        if (opp == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Oportunidad')),
            body: const Center(child: Text('Oportunidad no encontrada')),
          );
        }
        return _OppDetailContent(opp: opp);
      },
    );
  }
}

class _OppDetailContent extends StatelessWidget {
  final SaleOpportunity opp;
  const _OppDetailContent({required this.opp});

  static final _nf = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  static final _df = DateFormat('dd/MM/yyyy', 'es_MX');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(opp.folio, style: AppTextStyles.h3),
        actions: [
          if (opp.isActive)
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OpportunityFormPage(opportunity: opp))),
              icon: const Icon(Icons.edit_rounded),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: AppDimensions.lg),
                _buildPipeline(),
                const SizedBox(height: AppDimensions.lg),
                _buildClientInfo(),
                const SizedBox(height: AppDimensions.lg),
                _buildDetails(),
                const SizedBox(height: AppDimensions.lg),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final statusColor = Color(opp.status.colorValue);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text('${opp.status.emoji} ${opp.status.label}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: statusColor)),
              ),
              const Spacer(),
              Text(opp.folio, style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Text(opp.titulo, style: AppTextStyles.h3),
          if (opp.descripcion != null) ...[
            const SizedBox(height: AppDimensions.sm),
            Text(opp.descripcion!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
          const Divider(height: 24),
          Row(
            children: [
              _valueCard('Valor Estimado', _nf.format(opp.valorEstimado), AppColors.primary),
              const SizedBox(width: AppDimensions.md),
              _valueCard('Probabilidad', '${opp.probabilidad.toStringAsFixed(0)}%', Color(opp.status.colorValue)),
              const SizedBox(width: AppDimensions.md),
              _valueCard('Valor Ponderado', _nf.format(opp.valorPonderado), AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valueCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.h4.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _buildPipeline() {
    final statuses = [
      OpportunityStatus.nueva,
      OpportunityStatus.calificada,
      OpportunityStatus.propuesta,
      OpportunityStatus.negociacion,
      OpportunityStatus.ganada,
    ];
    final currentIndex = statuses.indexOf(opp.status);
    final isLost = opp.status == OpportunityStatus.perdida;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pipeline', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.md),
          if (isLost)
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: AppColors.error),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Oportunidad Perdida', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                      if (opp.motivoPerdida != null)
                        Text('Motivo: ${opp.motivoPerdida}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  )),
                ],
              ),
            )
          else
            Row(
              children: statuses.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                final isCompleted = currentIndex >= 0 && i <= currentIndex;
                final isCurrent = i == currentIndex;
                final color = isCompleted ? Color(s.colorValue) : AppColors.divider;
                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (i > 0) Expanded(child: Container(height: 3, color: isCompleted ? color : AppColors.divider)),
                          Container(
                            width: isCurrent ? 32 : 24,
                            height: isCurrent ? 32 : 24,
                            decoration: BoxDecoration(
                              color: isCompleted ? color : AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 2),
                            ),
                            child: Center(
                              child: isCompleted
                                  ? Icon(Icons.check_rounded, size: isCurrent ? 18 : 14, color: Colors.white)
                                  : Text('${i + 1}', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                            ),
                          ),
                          if (i < statuses.length - 1) Expanded(child: Container(height: 3, color: i < currentIndex ? Color(statuses[i + 1].colorValue) : AppColors.divider)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(s.label, style: TextStyle(fontSize: 9, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400, color: isCompleted ? Color(s.colorValue) : AppColors.textHint), textAlign: TextAlign.center),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppDimensions.sm),
            Text('Contacto', style: AppTextStyles.labelLarge),
          ]),
          const SizedBox(height: AppDimensions.md),
          Text(opp.contactoNombre, style: AppTextStyles.labelLarge),
          if (opp.contactoEmpresa != null)
            Text(opp.contactoEmpresa!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          if (opp.contactoEmail != null)
            Text(opp.contactoEmail!, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
          if (opp.contactoTelefono != null)
            Text(opp.contactoTelefono!, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppDimensions.sm),
            Text('Información', style: AppTextStyles.labelLarge),
          ]),
          const SizedBox(height: AppDimensions.md),
          _detailRow('Origen', opp.origen.label),
          _detailRow('Creada', _df.format(opp.createdAt)),
          if (opp.fechaCierreEstimada != null)
            _detailRow('Cierre estimado', _df.format(opp.fechaCierreEstimada!)),
          _detailRow('Cotizaciones vinculadas', '${opp.totalCotizaciones}'),
          if (opp.notas != null && opp.notas!.isNotEmpty) ...[
            const Divider(),
            Text('Notas:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(opp.notas!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.md,
      runSpacing: AppDimensions.md,
      children: [
        // Avanzar en pipeline
        if (opp.canAdvance)
          FilledButton.icon(
            onPressed: () async {
              final next = opp.status.nextStatus;
              if (next == null) return;
              await VentasService.instance.changeOpportunityStatus(opp.id, next);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ Avanzada a: ${next.label}'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text('Avanzar a ${opp.status.nextStatus?.label ?? ""}'),
            style: FilledButton.styleFrom(backgroundColor: Color(opp.status.nextStatus?.colorValue ?? 0xFF44562C)),
          ),

        // Crear cotización desde oportunidad
        if (opp.isActive)
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => QuoteFormPage(opportunityId: opp.id, preselectedContactId: opp.contactoId),
            )),
            icon: const Icon(Icons.request_quote_rounded),
            label: const Text('Crear cotización'),
          ),

        // Marcar como ganada
        if (opp.isActive && opp.status != OpportunityStatus.nueva)
          FilledButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('🏆 Marcar como Ganada'),
                  content: const Text('Se marcará la oportunidad como ganada y el contacto pasará a ser Cliente.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
                  ],
                ),
              );
              if (confirm == true) {
                await VentasService.instance.changeOpportunityStatus(opp.id, OpportunityStatus.ganada);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('🏆 ¡Oportunidad ganada!'),
                    backgroundColor: AppColors.success,
                  ));
                }
              }
            },
            icon: const Icon(Icons.emoji_events_rounded),
            label: const Text('Ganada'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          ),

        // Marcar como perdida
        if (opp.isActive)
          OutlinedButton.icon(
            onPressed: () => _showLostDialog(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Perdida'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          ),
      ],
    );
  }

  void _showLostDialog(BuildContext context) {
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como Perdida'),
        content: SizedBox(
          width: 350,
          child: TextFormField(
            controller: motivoCtrl,
            decoration: const InputDecoration(
              labelText: 'Motivo de la pérdida',
              hintText: 'Precio, competencia, timing...',
            ),
            maxLines: 3,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await VentasService.instance.changeOpportunityStatus(
                opp.id,
                OpportunityStatus.perdida,
                motivoPerdida: motivoCtrl.text.isNotEmpty ? motivoCtrl.text : null,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Oportunidad marcada como perdida'),
                  backgroundColor: AppColors.error,
                ));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
