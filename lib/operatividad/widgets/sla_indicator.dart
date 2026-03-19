// lib/operatividad/widgets/sla_indicator.dart

import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/oper_activity.dart';

/// Indicador visual de SLA para una actividad
class SlaIndicator extends StatefulWidget {
  final OperActivity activity;
  final bool compact;
  final bool showTimer;

  const SlaIndicator({
    super.key,
    required this.activity,
    this.compact = false,
    this.showTimer = true,
  });

  @override
  State<SlaIndicator> createState() => _SlaIndicatorState();
}

class _SlaIndicatorState extends State<SlaIndicator> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Actualizar cada minuto si tiene SLA activo
    if (widget.activity.hasSla && widget.showTimer) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getLevelColor(SlaLevel level) {
    switch (level) {
      case SlaLevel.ok:
        return AppColors.success;
      case SlaLevel.warning:
        return AppColors.warning;
      case SlaLevel.critical:
        return AppColors.error;
      case SlaLevel.breached:
        return AppColors.error;
    }
  }

  IconData _getLevelIcon(SlaLevel level) {
    switch (level) {
      case SlaLevel.ok:
        return Icons.check_circle_rounded;
      case SlaLevel.warning:
        return Icons.warning_amber_rounded;
      case SlaLevel.critical:
        return Icons.error_rounded;
      case SlaLevel.breached:
        return Icons.cancel_rounded;
    }
  }

  String _getLevelLabel(SlaLevel level) {
    switch (level) {
      case SlaLevel.ok:
        return 'SLA OK';
      case SlaLevel.warning:
        return 'SLA en riesgo';
      case SlaLevel.critical:
        return 'SLA crítico';
      case SlaLevel.breached:
        return 'SLA incumplido';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.activity.hasSla) {
      return const SizedBox.shrink();
    }

    final level = widget.activity.slaLevel;
    final color = _getLevelColor(level);

    if (widget.compact) {
      return _buildCompact(level, color);
    }

    return _buildFull(level, color);
  }

  Widget _buildCompact(SlaLevel level, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs / 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getLevelIcon(level), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            widget.activity.slaTimeRemainingText,
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

  Widget _buildFull(SlaLevel level, Color color) {
    final consumed = widget.activity.slaConsumedPercentage;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(_getLevelIcon(level), color: color, size: 20),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  _getLevelLabel(level),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${widget.activity.slaHours}h SLA',
                style: AppTextStyles.labelMedium.copyWith(color: color),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final fillWidth = (width * consumed.clamp(0.0, 1.0));

                  return Stack(
                    children: [
                      // Background
                      Container(width: width, color: AppColors.divider),
                      // Fill
                      Container(width: fillWidth, color: color),
                      // Warning zone marker (75%)
                      Positioned(
                        left: width * 0.75,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: AppColors.warning.withOpacity(0.5),
                        ),
                      ),
                      // Critical zone marker (90%)
                      Positioned(
                        left: width * 0.9,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: AppColors.error.withOpacity(0.5),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.sm),

          // Timer text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.activity.slaTimeRemainingText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (level == SlaLevel.breached &&
                  widget.activity.slaBreachedAt != null)
                Text(
                  'Incumplido el ${_formatDate(widget.activity.slaBreachedAt!)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Badge pequeño de SLA para listas y tarjetas
class SlaBadge extends StatelessWidget {
  final OperActivity activity;

  const SlaBadge({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    if (!activity.hasSla) return const SizedBox.shrink();

    final level = activity.slaLevel;
    final color = _getLevelColor(level);

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: level != SlaLevel.ok
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  Color _getLevelColor(SlaLevel level) {
    switch (level) {
      case SlaLevel.ok:
        return AppColors.success;
      case SlaLevel.warning:
        return AppColors.warning;
      case SlaLevel.critical:
        return AppColors.error;
      case SlaLevel.breached:
        return AppColors.error;
    }
  }
}
