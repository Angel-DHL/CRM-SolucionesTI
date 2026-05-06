// lib/ventas/pages/opportunities_list_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/sale_opportunity.dart';
import '../models/ventas_enums.dart';
import '../services/ventas_service.dart';
import 'opportunity_form_page.dart';
import 'opportunity_detail_page.dart';

class OpportunitiesListPage extends StatefulWidget {
  const OpportunitiesListPage({super.key});

  @override
  State<OpportunitiesListPage> createState() => _OpportunitiesListPageState();
}

class _OpportunitiesListPageState extends State<OpportunitiesListPage> {
  OpportunityStatus? _filterStatus;
  final _nf = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtros por status
        _buildFilters(),
        // Lista
        Expanded(
          child: StreamBuilder<List<SaleOpportunity>>(
            stream: VentasService.instance.streamOpportunities(status: _filterStatus),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final opps = snapshot.data ?? [];
              if (opps.isEmpty) return _buildEmpty();
              return ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.md),
                itemCount: opps.length,
                itemBuilder: (context, index) => _buildOppCard(opps[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      child: Row(
        children: [
          _filterChip(null, 'Todas'),
          ...OpportunityStatus.values.map((s) => _filterChip(s, s.label)),
        ],
      ),
    );
  }

  Widget _filterChip(OpportunityStatus? status, String label) {
    final selected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filterStatus = status),
        selectedColor: status != null
            ? Color(status.colorValue).withValues(alpha: 0.2)
            : AppColors.primarySurface,
        checkmarkColor: status != null ? Color(status.colorValue) : AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected
              ? (status != null ? Color(status.colorValue) : AppColors.primary)
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildOppCard(SaleOpportunity opp) {
    final statusColor = Color(opp.status.colorValue);
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OpportunityDetailPage(oppId: opp.id))),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Center(child: Text(opp.status.emoji, style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(opp.folio, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                            const SizedBox(width: AppDimensions.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                              ),
                              child: Text(opp.status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(opp.titulo, style: AppTextStyles.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_nf.format(opp.valorEstimado), style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
                      Text('${opp.probabilidad.toStringAsFixed(0)}% prob.', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(opp.contactoNombre, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  if (opp.contactoEmpresa != null) ...[
                    Text(' — ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
                    Text(opp.contactoEmpresa!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                  const Spacer(),
                  if (opp.fechaCierreEstimada != null) ...[
                    Icon(Icons.event_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yy').format(opp.fechaCierreEstimada!),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                  ],
                  if (opp.totalCotizaciones > 0) ...[
                    const SizedBox(width: AppDimensions.md),
                    Icon(Icons.request_quote_outlined, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Text('${opp.totalCotizaciones}', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                  ],
                ],
              ),
              // Progress bar de probabilidad
              const SizedBox(height: AppDimensions.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: opp.probabilidad / 100,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.md),
          Text('No hay oportunidades', style: AppTextStyles.h4.copyWith(color: AppColors.textHint)),
          const SizedBox(height: AppDimensions.sm),
          Text('Crea tu primera oportunidad de venta', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint)),
          const SizedBox(height: AppDimensions.lg),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpportunityFormPage())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva oportunidad'),
          ),
        ],
      ),
    );
  }
}
