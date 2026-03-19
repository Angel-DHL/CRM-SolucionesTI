// lib/operatividad/widgets/dependencies_section.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firebase_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/oper_activity.dart';

class DependenciesSection extends StatelessWidget {
  final OperActivity activity;
  final ValueChanged<OperActivity> onActivityTap;

  const DependenciesSection({
    super.key,
    required this.activity,
    required this.onActivityTap,
  });

  bool get _hasDependencies => activity.dependencies.isNotEmpty;

  /// Verifica si todas las dependencias están completadas
  Future<bool> canStart() async {
    if (!_hasDependencies) return true;

    for (final depId in activity.dependencies) {
      final doc = await FirebaseHelper.operActivities.doc(depId).get();
      if (!doc.exists) continue;

      final depActivity = OperActivity.fromDoc(doc);
      if (depActivity.status != OperStatus.done &&
          depActivity.status != OperStatus.verified) {
        return false;
      }
    }
    return true;
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
    if (!_hasDependencies) return const SizedBox.shrink();

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
                  Icons.account_tree_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Dependencias',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    '${activity.dependencies.length}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),

            // Bloqueo banner
            FutureBuilder<bool>(
              future: canStart(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }

                final canStartNow = snapshot.data ?? true;

                if (!canStartNow && activity.status == OperStatus.planned) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.md),
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Actividad bloqueada',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Completa las dependencias para poder iniciar',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (canStartNow && _hasDependencies) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.md),
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Text(
                          'Todas las dependencias completadas',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            // List of dependencies
            ...activity.dependencies.map((depId) {
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseHelper.operActivities.doc(depId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return _buildMissingDependency(depId);
                  }

                  final dep = OperActivity.fromDoc(snapshot.data!);
                  return _buildDependencyItem(context, dep);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDependencyItem(BuildContext context, OperActivity dep) {
    final color = _getStatusColor(dep.status);
    final isCompleted =
        dep.status == OperStatus.done || dep.status == OperStatus.verified;

    return InkWell(
      onTap: () => onActivityTap(dep),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.successLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withOpacity(0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isCompleted ? AppColors.success : AppColors.textHint,
              size: 20,
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dep.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          dep.status.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${dep.progress}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingDependency(String depId) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.broken_image_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              'Dependencia no encontrada (${depId.substring(0, 8)}...)',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
