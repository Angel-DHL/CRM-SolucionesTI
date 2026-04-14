// lib/crm/widgets/crm_activity_tile.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/crm_activity_log.dart';
import '../models/crm_enums.dart';

class CrmActivityTile extends StatelessWidget {
  final CrmActivityLog log;

  const CrmActivityTile({super.key, required this.log});

  IconData get _icon => switch (log.type) {
    CrmActivityType.nota => Icons.note_rounded,
    CrmActivityType.llamada => Icons.phone_rounded,
    CrmActivityType.email => Icons.email_rounded,
    CrmActivityType.reunion => Icons.groups_rounded,
    CrmActivityType.cambioEstatus => Icons.swap_horiz_rounded,
    CrmActivityType.conversion => Icons.transform_rounded,
  };

  Color get _iconColor => switch (log.type) {
    CrmActivityType.nota => AppColors.info,
    CrmActivityType.llamada => AppColors.success,
    CrmActivityType.email => AppColors.primary,
    CrmActivityType.reunion => const Color(0xFF9B59B6),
    CrmActivityType.cambioEstatus => AppColors.warning,
    CrmActivityType.conversion => AppColors.primaryLight,
  };

  Color get _bgColor => _iconColor.withOpacity(0.1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(_icon, size: 18, color: _iconColor),
              ),
            ],
          ),

          const SizedBox(width: AppDimensions.md),

          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.md),
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
                      Expanded(
                        child: Text(
                          log.titulo,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(log.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  if (log.descripcion != null && log.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      log.descripcion!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (log.createdByEmail != null) ...[
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      'por ${log.createdByEmail}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${date.day}/${date.month}/${date.year}';
  }
}
