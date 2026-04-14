// lib/crm/pages/crm_dashboard_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/crm_enums.dart';
import '../services/crm_service.dart';
import '../widgets/crm_leads_inbox.dart';

class CrmDashboardPage extends StatelessWidget {
  final UserRole role;

  const CrmDashboardPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ HEADER ═══
          _WelcomeSection(isMobile: isMobile),
          SizedBox(height: isMobile ? AppDimensions.lg : AppDimensions.xl),

          // ═══ KPI CARDS ═══
          _KpiSection(isMobile: isMobile),
          SizedBox(height: isMobile ? AppDimensions.lg : AppDimensions.xl),

          // ═══ EMBUDO + LEADS RECIENTES ═══
          if (!isMobile)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _FunnelSection(),
                ),
                const SizedBox(width: AppDimensions.lg),
                Expanded(
                  flex: 2,
                  child: _RecentLeadsSection(),
                ),
              ],
            )
          else ...[
            _FunnelSection(),
            const SizedBox(height: AppDimensions.lg),
            _RecentLeadsSection(),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WELCOME SECTION
// ══════════════════════════════════════════════════════════════

class _WelcomeSection extends StatelessWidget {
  final bool isMobile;

  const _WelcomeSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Clientes',
                  style: (isMobile ? AppTextStyles.h3 : AppTextStyles.h2).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  'Administra leads, prospectos y clientes',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// KPI CARDS
// ══════════════════════════════════════════════════════════════

class _KpiSection extends StatelessWidget {
  final bool isMobile;

  const _KpiSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<ContactStatus, int>>(
      stream: CrmService.instance.streamStatusCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {};
        final totalContacts = counts.values.fold(0, (a, b) => a + b);
        final leads = counts[ContactStatus.lead] ?? 0;
        final prospectos = counts[ContactStatus.prospecto] ?? 0;
        final potenciales = counts[ContactStatus.clientePotencial] ?? 0;
        final clientes = counts[ContactStatus.cliente] ?? 0;
        final inactivos = counts[ContactStatus.inactivo] ?? 0;

        // Tasa de conversión
        final totalInPipeline = leads + prospectos + potenciales + clientes;
        final conversionRate = totalInPipeline > 0
            ? ((clientes / totalInPipeline) * 100).toStringAsFixed(1)
            : '0.0';

        final cards = [
          _KpiData(
            title: 'Total contactos',
            value: '$totalContacts',
            icon: Icons.people_rounded,
            color: AppColors.primary,
            bgColor: AppColors.primarySurface,
          ),
          _KpiData(
            title: 'Leads nuevos',
            value: '$leads',
            icon: Icons.inbox_rounded,
            color: AppColors.info,
            bgColor: AppColors.infoLight,
          ),
          _KpiData(
            title: 'Clientes activos',
            value: '$clientes',
            icon: Icons.verified_rounded,
            color: AppColors.success,
            bgColor: AppColors.successLight,
          ),
          _KpiData(
            title: 'Tasa conversión',
            value: '$conversionRate%',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFFE67E22),
            bgColor: const Color(0xFFFFF0E0),
          ),
        ];

        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppDimensions.sm,
            mainAxisSpacing: AppDimensions.sm,
            childAspectRatio: 1.5,
            children: cards.map((d) => _KpiCard(data: d, compact: true)).toList(),
          );
        }

        return Row(
          children: cards.map((d) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: d == cards.last ? 0 : AppDimensions.md,
                ),
                child: _KpiCard(data: d),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  final bool compact;

  const _KpiCard({required this.data, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? AppDimensions.md : AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 6 : AppDimensions.sm),
                decoration: BoxDecoration(
                  color: data.bgColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(data.icon, size: compact ? 16 : 20, color: data.color),
              ),
              if (!compact) const Spacer(),
            ],
          ),
          SizedBox(height: compact ? AppDimensions.sm : AppDimensions.md),
          Text(
            data.value,
            style: (compact ? AppTextStyles.h3 : AppTextStyles.h1).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// FUNNEL / EMBUDO DE CONVERSIÓN
// ══════════════════════════════════════════════════════════════

class _FunnelSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'Embudo de conversión',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          StreamBuilder<Map<ContactStatus, int>>(
            stream: CrmService.instance.streamStatusCounts(),
            builder: (context, snapshot) {
              final counts = snapshot.data ?? {};
              final maxCount = counts.values.fold(0, (a, b) => a > b ? a : b);

              final funnelStatuses = [
                ContactStatus.lead,
                ContactStatus.prospecto,
                ContactStatus.clientePotencial,
                ContactStatus.cliente,
              ];

              return Column(
                children: funnelStatuses.map((status) {
                  final count = counts[status] ?? 0;
                  final ratio = maxCount > 0 ? count / maxCount : 0.0;

                  return _FunnelBar(
                    status: status,
                    count: count,
                    ratio: ratio,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FunnelBar extends StatelessWidget {
  final ContactStatus status;
  final int count;
  final double ratio;

  const _FunnelBar({
    required this.status,
    required this.count,
    required this.ratio,
  });

  Color get _color => switch (status) {
    ContactStatus.lead => AppColors.info,
    ContactStatus.prospecto => AppColors.warning,
    ContactStatus.clientePotencial => const Color(0xFFE67E22),
    ContactStatus.cliente => AppColors.success,
    ContactStatus.inactivo => AppColors.textHint,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${status.emoji} ${status.label}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$count',
                style: AppTextStyles.labelLarge.copyWith(
                  color: _color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: _color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(_color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LEADS RECIENTES
// ══════════════════════════════════════════════════════════════

class _RecentLeadsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StreamBuilder<int>(
                stream: CrmService.instance.streamUnreadLeadsCount(),
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return Row(
                    children: [
                      Icon(Icons.inbox_rounded, size: 20, color: AppColors.info),
                      const SizedBox(width: AppDimensions.sm),
                      Text(
                        'Leads del sitio web',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: AppDimensions.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: Text(
                            '$unread',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          const CrmLeadsInbox(limit: 5),
        ],
      ),
    );
  }
}
