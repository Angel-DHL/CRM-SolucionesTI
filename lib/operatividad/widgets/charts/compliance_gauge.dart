// lib/operatividad/widgets/charts/compliance_gauge.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/oper_activity.dart';

class ComplianceGauge extends StatefulWidget {
  final List<OperActivity> activities;

  const ComplianceGauge({super.key, required this.activities});

  @override
  State<ComplianceGauge> createState() => _ComplianceGaugeState();
}

class _ComplianceGaugeState extends State<ComplianceGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double get _complianceRate {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final thisMonthActivities = widget.activities.where((a) {
      return a.plannedEndAt.isAfter(monthStart) &&
          a.plannedEndAt.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    if (thisMonthActivities.isEmpty) return 0;

    final completed = thisMonthActivities.where((a) {
      return a.status == OperStatus.done || a.status == OperStatus.verified;
    }).length;

    return completed / thisMonthActivities.length;
  }

  double get _onTimeRate {
    final completedActivities = widget.activities.where((a) {
      return a.status == OperStatus.done || a.status == OperStatus.verified;
    }).toList();

    if (completedActivities.isEmpty) return 0;

    final onTime = completedActivities.where((a) {
      final completedDate = a.workEndAt ?? a.actualEndAt ?? a.updatedAt;
      return completedDate.isBefore(a.plannedEndAt) ||
          completedDate.isAtSameMomentAs(a.plannedEndAt);
    }).length;

    return onTime / completedActivities.length;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compliance = _complianceRate;
    final onTime = _onTimeRate;

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
                Icon(Icons.speed_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Cumplimiento mensual',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Gauges
            Row(
              children: [
                Expanded(
                  child: _GaugeIndicator(
                    value: compliance,
                    animation: _animation,
                    label: 'Cumplimiento',
                    sublabel: 'del mes actual',
                  ),
                ),
                const SizedBox(width: AppDimensions.xl),
                Expanded(
                  child: _GaugeIndicator(
                    value: onTime,
                    animation: _animation,
                    label: 'A tiempo',
                    sublabel: 'entregas puntuales',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugeIndicator extends StatelessWidget {
  final double value;
  final Animation<double> animation;
  final String label;
  final String sublabel;

  const _GaugeIndicator({
    required this.value,
    required this.animation,
    required this.label,
    required this.sublabel,
  });

  Color get _color {
    if (value >= 0.8) return AppColors.success;
    if (value >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedValue = value * animation.value;
        final percentage = (animatedValue * 100).toInt();

        return Column(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: animatedValue,
                      strokeWidth: 10,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(_color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentage%',
                        style: AppTextStyles.h2.copyWith(
                          color: _color,
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              sublabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
