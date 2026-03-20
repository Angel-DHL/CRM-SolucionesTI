// lib/inventory/widgets/charts/inventory_pie_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/inventory_enums.dart';

class InventoryPieChart extends StatefulWidget {
  final Map<InventoryItemType, int> data;
  final double size;
  final bool showLegend;
  final String? title;

  const InventoryPieChart({
    super.key,
    required this.data,
    this.size = 200,
    this.showLegend = true,
    this.title,
  });

  @override
  State<InventoryPieChart> createState() => _InventoryPieChartState();
}

class _InventoryPieChartState extends State<InventoryPieChart> {
  int _touchedIndex = -1;

  int get _total => widget.data.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    if (_total == 0) {
      return SizedBox(
        height: widget.size,
        child: Center(
          child: Text(
            'Sin datos',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (widget.title != null) ...[
          Text(widget.title!, style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.md),
        ],
        Row(
          children: [
            // Chart
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
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
                  sectionsSpace: 2,
                  centerSpaceRadius: widget.size * 0.3,
                  sections: _buildSections(),
                ),
              ),
            ),

            // Legend
            if (widget.showLegend) ...[
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: widget.data.entries.map((entry) {
                    final percentage = (entry.value / _total) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: _LegendItem(
                        color: entry.key.color,
                        icon: entry.key.icon,
                        label: entry.key.label,
                        value: entry.value,
                        percentage: percentage,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    final entries = widget.data.entries.toList();

    return entries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? widget.size * 0.25 : widget.size * 0.2;
      final percentage = (entry.value / _total) * 100;

      return PieChartSectionData(
        color: entry.key.color,
        value: entry.value.toDouble(),
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        badgeWidget: isTouched
            ? null
            : Icon(entry.key.icon, color: Colors.white, size: 16),
        badgePositionPercentageOffset: 0.5,
      );
    }).toList();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final int value;
  final double percentage;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$value (${percentage.toStringAsFixed(1)}%)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
