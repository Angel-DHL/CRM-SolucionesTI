// lib/crm/widgets/crm_status_chip.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/crm_enums.dart';

class CrmStatusChip extends StatelessWidget {
  final ContactStatus status;
  final bool showEmoji;
  final bool compact;

  const CrmStatusChip({
    super.key,
    required this.status,
    this.showEmoji = true,
    this.compact = false,
  });

  Color get _backgroundColor => switch (status) {
    ContactStatus.lead => AppColors.infoLight,
    ContactStatus.prospecto => const Color(0xFFFFF4E0),
    ContactStatus.clientePotencial => const Color(0xFFFFF0E0),
    ContactStatus.cliente => AppColors.successLight,
    ContactStatus.inactivo => const Color(0xFFF5F5F5),
  };

  Color get _foregroundColor => switch (status) {
    ContactStatus.lead => AppColors.info,
    ContactStatus.prospecto => AppColors.warning,
    ContactStatus.clientePotencial => const Color(0xFFE67E22),
    ContactStatus.cliente => AppColors.success,
    ContactStatus.inactivo => AppColors.textHint,
  };

  Color get _borderColor => _foregroundColor.withOpacity(0.3);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDimensions.animFast,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppDimensions.sm : AppDimensions.md,
        vertical: compact ? 2 : AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showEmoji) ...[
            Text(status.emoji, style: TextStyle(fontSize: compact ? 10 : 12)),
            SizedBox(width: compact ? 2 : AppDimensions.xs),
          ],
          Text(
            status.label,
            style: (compact ? AppTextStyles.caption : AppTextStyles.labelMedium).copyWith(
              color: _foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip para la fuente del contacto
class CrmSourceChip extends StatelessWidget {
  final ContactSource source;

  const CrmSourceChip({super.key, required this.source});

  IconData get _icon => switch (source) {
    ContactSource.formularioWeb => Icons.language_rounded,
    ContactSource.llamada => Icons.phone_rounded,
    ContactSource.referido => Icons.people_rounded,
    ContactSource.redSocial => Icons.share_rounded,
    ContactSource.email => Icons.email_rounded,
    ContactSource.otro => Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            source.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
