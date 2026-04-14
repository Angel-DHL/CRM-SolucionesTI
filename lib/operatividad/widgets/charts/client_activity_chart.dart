// lib/operatividad/widgets/charts/client_activity_chart.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/oper_activity.dart';
import 'package:fl_chart/fl_chart.dart';

class ClientActivityChart extends StatelessWidget {
  final List<OperActivity> activities;

  const ClientActivityChart({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    // Filter activities that have a client assigned
    final clientActivities = activities.where((a) => a.clientId != null).toList();

    if (clientActivities.isEmpty) {
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
              Text(
                'Actividades por Cliente',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 48,
                      color: AppColors.textHint.withOpacity(0.3),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      'No hay actividades asignadas a clientes',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      );
    }

    // Group by client
    final Map<String, int> topClients = {};
    for (var act in clientActivities) {
      final name = act.clientName ?? 'Cliente Desconocido';
      topClients[name] = (topClients[name] ?? 0) + 1;
    }

    // Sort by count descending and take top 5
    final sortedClients = topClients.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final displayClients = sortedClients.take(5).toList();
    final maxActivities = displayClients.isNotEmpty ? displayClients.first.value : 1;

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
                Icon(Icons.business_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Actividades por Cliente',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              'Top 5 clientes con más actividades',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxActivities.toDouble() * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${displayClients[group.x.toInt()].key}\n',
                          AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.toY.toInt()} actividades',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= displayClients.length) {
                            return const SizedBox.shrink();
                          }
                          // Extract first word or initials to fit in the chart
                          final name = displayClients[value.toInt()].key;
                          final shortName = name.split(' ').first;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                shortName.length > 10 ? '${shortName.substring(0, 8)}...' : shortName,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textHint,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(displayClients.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: displayClients[index].value.toDouble(),
                          color: AppColors.primary,
                          width: 22,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxActivities.toDouble() * 1.2,
                            color: AppColors.primarySurface,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
