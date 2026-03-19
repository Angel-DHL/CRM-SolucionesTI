// lib/operatividad/widgets/charts/workload_prediction_view.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/oper_activity.dart';
import '../../services/metrics_service.dart';

class WorkloadPredictionView extends StatelessWidget {
  final List<OperActivity> activities;

  const WorkloadPredictionView({super.key, required this.activities});

  Color _getLevelColor(WorkloadLevel level) {
    switch (level) {
      case WorkloadLevel.low:
        return AppColors.info;
      case WorkloadLevel.normal:
        return AppColors.success;
      case WorkloadLevel.high:
        return AppColors.warning;
      case WorkloadLevel.overloaded:
        return AppColors.error;
    }
  }

  String _getLevelLabel(WorkloadLevel level) {
    switch (level) {
      case WorkloadLevel.low:
        return 'Baja carga';
      case WorkloadLevel.normal:
        return 'Normal';
      case WorkloadLevel.high:
        return 'Alta carga';
      case WorkloadLevel.overloaded:
        return 'Sobrecargado';
    }
  }

  IconData _getLevelIcon(WorkloadLevel level) {
    switch (level) {
      case WorkloadLevel.low:
        return Icons.battery_1_bar_rounded;
      case WorkloadLevel.normal:
        return Icons.battery_std_rounded;
      case WorkloadLevel.high:
        return Icons.battery_5_bar_rounded;
      case WorkloadLevel.overloaded:
        return Icons.battery_alert_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final predictions = MetricsService.predictWorkload(activities: activities);

    if (predictions.isEmpty) return const SizedBox.shrink();

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
            Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Predicción de carga',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Próximos 7 días',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Alert for overloaded
            ..._buildAlerts(predictions),

            // Prediction cards
            ...predictions.map(
              (p) => _PredictionCard(
                prediction: p,
                color: _getLevelColor(p.level),
                label: _getLevelLabel(p.level),
                icon: _getLevelIcon(p.level),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAlerts(List<WorkloadPrediction> predictions) {
    final overloaded = predictions
        .where((p) => p.level == WorkloadLevel.overloaded)
        .toList();

    if (overloaded.isEmpty) return [];

    return [
      Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        margin: const EdgeInsets.only(bottom: AppDimensions.lg),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${overloaded.length} colaborador(es) sobrecargado(s)',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Considera redistribuir actividades',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _PredictionCard extends StatelessWidget {
  final WorkloadPrediction prediction;
  final Color color;
  final String label;
  final IconData icon;

  const _PredictionCard({
    required this.prediction,
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final capacityPercent = prediction.capacityPercentage.clamp(0.0, 200.0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.15),
                child: Text(
                  prediction.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${prediction.estimatedHoursNextWeek.toStringAsFixed(1)}h',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${prediction.currentActivities} activas · ${prediction.upcomingActivities} próximas',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textHint,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Capacity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Stack(
                    children: [
                      Container(width: width, color: AppColors.divider),
                      Container(
                        width: width * (capacityPercent / 100).clamp(0.0, 1.0),
                        color: color,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
