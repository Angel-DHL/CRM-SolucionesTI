// lib/operatividad/widgets/charts/collaborator_metrics_view.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/responsive.dart';
import '../../models/oper_activity.dart';
import '../../services/metrics_service.dart';

class CollaboratorMetricsView extends StatelessWidget {
  final List<OperActivity> activities;
  final List<OperActivity> previousPeriodActivities;

  const CollaboratorMetricsView({
    super.key,
    required this.activities,
    required this.previousPeriodActivities,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = MetricsService.calculateCollaboratorMetrics(
      currentPeriod: activities,
      previousPeriod: previousPeriodActivities,
    );

    if (metrics.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Center(
            child: Text(
              'Sin datos de colaboradores',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
      );
    }

    final isMobile = Responsive.isMobile(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.leaderboard_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'Productividad por colaborador',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Metrics cards
            ...metrics.asMap().entries.map((entry) {
              final index = entry.key;
              final metric = entry.value;

              return _CollaboratorMetricCard(
                metric: metric,
                rank: index + 1,
                isMobile: isMobile,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CollaboratorMetricCard extends StatefulWidget {
  final CollaboratorMetrics metric;
  final int rank;
  final bool isMobile;

  const _CollaboratorMetricCard({
    required this.metric,
    required this.rank,
    required this.isMobile,
  });

  @override
  State<_CollaboratorMetricCard> createState() =>
      _CollaboratorMetricCardState();
}

class _CollaboratorMetricCardState extends State<_CollaboratorMetricCard> {
  bool _expanded = false;

  Color get _rankColor {
    switch (widget.rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.textHint;
    }
  }

  Color _getRateColor(double rate) {
    if (rate >= 0.8) return AppColors.success;
    if (rate >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metric;

    return AnimatedContainer(
      duration: AppDimensions.animFast,
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        color: _expanded ? AppColors.primarySurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    // Rank
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _rankColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: widget.rank <= 3
                            ? Border.all(color: _rankColor, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.rank}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: _rankColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),

                    // Name + email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${m.completed}/${m.totalAssigned} completadas',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick metrics
                    if (!widget.isMobile) ...[
                      _QuickMetric(
                        label: 'Cumplimiento',
                        value: m.completionRateText,
                        color: _getRateColor(m.completionRate),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      _QuickMetric(
                        label: 'A tiempo',
                        value: m.onTimeRateText,
                        color: _getRateColor(m.onTimeRate),
                      ),
                      const SizedBox(width: AppDimensions.md),
                    ],

                    // Trend indicator
                    _TrendIndicator(
                      value: m.completionRateTrend,
                      label: 'vs anterior',
                    ),

                    const SizedBox(width: AppDimensions.sm),

                    // Expand icon
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppDimensions.animFast,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),

                // Expanded details
                if (_expanded) ...[
                  const SizedBox(height: AppDimensions.md),
                  const Divider(),
                  const SizedBox(height: AppDimensions.md),
                  _buildExpandedContent(m),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(CollaboratorMetrics m) {
    return Column(
      children: [
        // Metrics grid
        Row(
          children: [
            Expanded(
              child: _DetailMetric(
                icon: Icons.check_circle_rounded,
                label: 'Cumplimiento',
                value: m.completionRateText,
                color: _getRateColor(m.completionRate),
              ),
            ),
            Expanded(
              child: _DetailMetric(
                icon: Icons.timer_rounded,
                label: 'A tiempo',
                value: m.onTimeRateText,
                color: _getRateColor(m.onTimeRate),
              ),
            ),
            Expanded(
              child: _DetailMetric(
                icon: Icons.speed_rounded,
                label: 'Eficiencia',
                value: m.efficiencyRateText,
                color: _getRateColor(m.efficiencyRate),
              ),
            ),
            if (m.slaCompliant + m.slaBreached > 0)
              Expanded(
                child: _DetailMetric(
                  icon: Icons.verified_rounded,
                  label: 'SLA',
                  value: m.slaComplianceRateText,
                  color: _getRateColor(m.slaComplianceRate),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),

        // Activity breakdown
        Row(
          children: [
            _ActivityCount(
              label: 'En progreso',
              count: m.inProgress,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppDimensions.sm),
            _ActivityCount(
              label: 'Vencidas',
              count: m.overdue,
              color: AppColors.error,
            ),
            const SizedBox(width: AppDimensions.sm),
            _ActivityCount(
              label: 'Bloqueadas',
              count: m.blocked,
              color: AppColors.error,
            ),
          ],
        ),

        if (m.totalEstimatedHours > 0) ...[
          const SizedBox(height: AppDimensions.md),
          // Hours comparison
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: AppColors.textHint),
              const SizedBox(width: AppDimensions.xs),
              Text(
                'Estimado: ${m.totalEstimatedHours.toStringAsFixed(1)}h',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Icon(Icons.timer_rounded, size: 16, color: AppColors.textHint),
              const SizedBox(width: AppDimensions.xs),
              Text(
                'Real: ${m.totalActualHours.toStringAsFixed(1)}h',
                style: AppTextStyles.bodySmall.copyWith(
                  color: m.totalActualHours > m.totalEstimatedHours
                      ? AppColors.error
                      : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _QuickMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _QuickMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  final double value;
  final String label;

  const _TrendIndicator({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    final percentage = (value.abs() * 100).toStringAsFixed(0);

    if (value == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$percentage%',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: AppDimensions.xs),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textHint,
            fontSize: 9,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ActivityCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ActivityCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.sm),
        decoration: BoxDecoration(
          color: count > 0 ? color.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: AppTextStyles.labelLarge.copyWith(
                color: count > 0 ? color : AppColors.textHint,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                  fontSize: 9,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
