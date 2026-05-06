// lib/marketing/pages/campaigns_list_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/marketing_campaign.dart';
import '../models/marketing_enums.dart';
import '../services/marketing_service.dart';

import 'campaign_detail_page.dart';

class CampaignsListPage extends StatefulWidget {
  const CampaignsListPage({super.key});

  @override
  State<CampaignsListPage> createState() => _CampaignsListPageState();
}

class _CampaignsListPageState extends State<CampaignsListPage> {
  CampaignStatus? _filterStatus;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar campaña...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd), borderSide: BorderSide(color: AppColors.divider)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              // Status filter chips
              ...CampaignStatus.values.map((s) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: FilterChip(
                  label: Text(s.label, style: const TextStyle(fontSize: 12)),
                  selected: _filterStatus == s,
                  onSelected: (sel) => setState(() => _filterStatus = sel ? s : null),
                  selectedColor: s.bgColor,
                  checkmarkColor: s.color,
                  side: BorderSide(color: _filterStatus == s ? s.color : AppColors.divider),
                ),
              )),
            ],
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<List<MarketingCampaign>>(
            stream: MarketingService.instance.streamCampaigns(status: _filterStatus),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var campaigns = snapshot.data ?? [];
              if (_search.isNotEmpty) {
                campaigns = campaigns.where((c) =>
                  c.nombre.toLowerCase().contains(_search.toLowerCase()) ||
                  c.folio.toLowerCase().contains(_search.toLowerCase())).toList();
              }

              if (campaigns.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.campaign_rounded, size: 64, color: AppColors.textHint.withOpacity(0.3)),
                    const SizedBox(height: AppDimensions.md),
                    Text('No hay campañas', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
                    const SizedBox(height: AppDimensions.sm),
                    Text('Crea una nueva campaña para comenzar', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                  ]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                itemCount: campaigns.length,
                itemBuilder: (ctx, i) => _CampaignCard(campaign: campaigns[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final MarketingCampaign campaign;
  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => CampaignDetailPage(campaignId: campaign.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: campaign.tipo.icon == Icons.email_rounded
                          ? AppColors.info.withOpacity(0.1)
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: Icon(campaign.tipo.icon, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(campaign.nombre, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                        Row(
                          children: [
                            Text(campaign.folio, style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                            const SizedBox(width: 8),
                            Text('• ${campaign.tipo.label}', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: campaign.status.bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${campaign.status.emoji} ${campaign.status.label}',
                      style: TextStyle(color: campaign.status.color, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),

              // Canales
              if (campaign.canales.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: campaign.canales.map((c) => Chip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    avatar: Icon(c.icon, size: 14, color: c.color),
                    label: Text(c.label, style: TextStyle(fontSize: 11, color: c.color)),
                    backgroundColor: c.color.withOpacity(0.08),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
              const SizedBox(height: AppDimensions.md),

              // Metrics row
              Row(
                children: [
                  _MetricPill(Icons.people_alt_rounded, '${campaign.leadsGenerados}', 'leads', AppColors.primary),
                  const SizedBox(width: AppDimensions.md),
                  _MetricPill(Icons.check_circle_rounded, '${campaign.conversionesLogradas}', 'conv.', AppColors.success),
                  const SizedBox(width: AppDimensions.md),
                  _MetricPill(Icons.show_chart_rounded, '${campaign.roi.toStringAsFixed(0)}%', 'ROI', campaign.roi >= 0 ? AppColors.success : AppColors.error),
                  const Spacer(),
                  if (campaign.presupuesto > 0) ...[
                    Text('\$${campaign.gastoReal.toStringAsFixed(0)}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                    Text(' / \$${campaign.presupuesto.toStringAsFixed(0)}', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                  ],
                ],
              ),

              // Progress bar
              if (campaign.presupuesto > 0) ...[
                const SizedBox(height: AppDimensions.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (campaign.progresoPpresupuesto / 100).clamp(0, 1),
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      campaign.superoPpresupuesto ? AppColors.error : AppColors.primary,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricPill(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.textHint)),
      ],
    );
  }
}
