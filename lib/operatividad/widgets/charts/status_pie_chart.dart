// lib/operatividad/widgets/charts/status_pie_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/oper_activity.dart';

class StatusPieChart extends StatefulWidget {
  final List<OperActivity> activities;

  const StatusPieChart({super.key, required this.activities});

  @override
  State<StatusPieChart> createState() => _StatusPieChartState();
}

class _StatusPieChartState extends State<StatusPieChart> {
  int _touchedIndex = -1;

  Map<OperStatus, int> get _statusCounts {
    final counts = <OperStatus, int>{};
    for (final status in OperStatus.values) {
      counts[status] = widget.activities
          .where((a) => a.status == status)
          .length;
    }
    return counts;
  }

  Color _getStatusColor(OperStatus status) {
    switch (status) {
      case OperStatus.planned:
        return AppColors.info;
      case OperStatus.inProgress:
        return AppColors.warning;
      case OperStatus.done:
        return AppColors.success;
      case OperStatus.verified:
        return AppColors.primary;
      case OperStatus.blocked:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final counts = _statusCounts;
    final total = widget.activities.length;

    if (total == 0) {
      return _buildEmptyState();
    }

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
                  Icons.pie_chart_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Distribución por estado',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Chart + Legend
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  // Pie Chart
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 45,
                        sections: _buildSections(counts, total),
                      ),
                      swapAnimationDuration: AppDimensions.animNormal,
                      swapAnimationCurve: Curves.easeInOut,
                    ),
                  ),

                  const SizedBox(width: AppDimensions.lg),

                  // Legend
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: OperStatus.values.map((status) {
                        final count = counts[status] ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        final percentage = (count / total * 100)
                            .toStringAsFixed(0);

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppDimensions.sm,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.sm),
                              Expanded(
                                child: Text(
                                  status.label,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '$count ($percentage%)',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    Map<OperStatus, int> counts,
    int total,
  ) {
    final sections = <PieChartSectionData>[];
    int index = 0;

    for (final status in OperStatus.values) {
      final count = counts[status] ?? 0;
      if (count == 0) {
        index++;
        continue;
      }

      final isTouched = index == _touchedIndex;
      final percentage = (count / total * 100).toStringAsFixed(0);

      sections.add(
        PieChartSectionData(
          color: _getStatusColor(status),
          value: count.toDouble(),
          title: isTouched ? '$percentage%' : '',
          radius: isTouched ? 55 : 45,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.55,
          badgePositionPercentageOffset: 1.1,
        ),
      );
      index++;
    }

    return sections;
  }

  Widget _buildEmptyState() {
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
            'Sin datos para mostrar',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
        ),
      ),
    );
  }
}
