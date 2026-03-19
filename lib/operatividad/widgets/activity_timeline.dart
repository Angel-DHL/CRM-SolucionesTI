// lib/operatividad/widgets/activity_timeline.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crm_solucionesti/operatividad/models/oper_activity.dart';
import 'package:flutter/material.dart';

import '../../core/firebase_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/oper_log.dart';

class ActivityTimeline extends StatelessWidget {
  final String activityId;
  final bool fullPage;

  const ActivityTimeline({
    super.key,
    required this.activityId,
    this.fullPage = false,
  });

  Color _getActionColor(LogAction action) {
    switch (action) {
      case LogAction.created:
        return AppColors.primary;
      case LogAction.statusChanged:
        return AppColors.info;
      case LogAction.progressChanged:
        return AppColors.primaryLight;
      case LogAction.workStarted:
        return AppColors.success;
      case LogAction.workEnded:
        return AppColors.success;
      case LogAction.assigneesChanged:
        return AppColors.info;
      case LogAction.priorityChanged:
        return AppColors.warning;
      case LogAction.evidenceUploaded:
        return AppColors.primary;
      case LogAction.evidenceDeleted:
        return AppColors.error;
      case LogAction.commentAdded:
        return AppColors.info;
      case LogAction.slaBreached:
        return AppColors.error;
      case LogAction.edited:
        return AppColors.textSecondary;
    }
  }

  IconData _getActionIcon(LogAction action) {
    switch (action) {
      case LogAction.created:
        return Icons.add_circle_rounded;
      case LogAction.statusChanged:
        return Icons.sync_rounded;
      case LogAction.progressChanged:
        return Icons.trending_up_rounded;
      case LogAction.workStarted:
        return Icons.play_circle_rounded;
      case LogAction.workEnded:
        return Icons.stop_circle_rounded;
      case LogAction.assigneesChanged:
        return Icons.people_rounded;
      case LogAction.priorityChanged:
        return Icons.flag_rounded;
      case LogAction.evidenceUploaded:
        return Icons.cloud_upload_rounded;
      case LogAction.evidenceDeleted:
        return Icons.delete_rounded;
      case LogAction.commentAdded:
        return Icons.chat_bubble_rounded;
      case LogAction.slaBreached:
        return Icons.warning_rounded;
      case LogAction.edited:
        return Icons.edit_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseHelper.operActivities
          .doc(activityId)
          .collection('logs')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.xl),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar bitácora',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmpty();
        }

        final logs = docs.map(OperLog.fromDoc).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: logs.asMap().entries.map((entry) {
            final index = entry.key;
            final log = entry.value;
            final isLast = index == logs.length - 1;

            return _TimelineItem(
              log: log,
              isLast: isLast,
              color: _getActionColor(log.action),
              icon: _getActionIcon(log.action),
            );
          }).toList(),
        );
      },
    );

    if (fullPage) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: content,
      );
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
            Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Bitácora de cambios',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              'Sin registros aún',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final OperLog log;
  final bool isLast;
  final Color color;
  final IconData icon;

  const _TimelineItem({
    required this.log,
    required this.isLast,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.divider),
                  ),
              ],
            ),
          ),

          const SizedBox(width: AppDimensions.md),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppDimensions.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action label
                  Text(
                    log.action.label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Description
                  Text(
                    log.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // Previous → New value
                  if (log.previousValue != null && log.newValue != null) ...[
                    const SizedBox(height: AppDimensions.xs),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.sm),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_formatValue(log.previousValue!)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                          ),
                          Text(
                            '${_formatValue(log.newValue!)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppDimensions.xs),

                  // Author + time
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          log.performedByName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Text(
                        log.performedByName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Text(
                        '· ${log.timeAgo}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(Map<String, dynamic> value) {
    if (value.containsKey('status')) {
      return OperStatusX.from(value['status']).label;
    }
    if (value.containsKey('progress')) {
      return '${value['progress']}%';
    }
    if (value.containsKey('priority')) {
      return value['priority'].toString();
    }
    return value.values.first.toString();
  }
}
