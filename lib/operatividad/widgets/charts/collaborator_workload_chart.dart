// lib/operatividad/widgets/charts/collaborator_workload_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../models/oper_activity.dart';

class CollaboratorWorkloadChart extends StatelessWidget {
  final List<OperActivity> activities;

  const CollaboratorWorkloadChart({super.key, required this.activities});

  List<_CollaboratorData> get _collaboratorData {
    final map = <String, _CollaboratorData>{};

    for (final activity in activities) {
      for (int i = 0; i < activity.assigneesEmails.length; i++) {
        final email = activity.assigneesEmails[i];
        final name = email.split('@').first;

        if (!map.containsKey(email)) {
          map[email] = _CollaboratorData(name: name, email: email);
        }

        map[email]!.totalActivities++;

        if (activity.status == OperStatus.done ||
            activity.status == OperStatus.verified) {
          map[email]!.completedActivities++;
        } else if (activity.status == OperStatus.inProgress) {
          map[email]!.inProgressActivities++;
        } else if (activity.isOverdue) {
          map[email]!.overdueActivities++;
        }
      }
    }

    final result = map.values.toList();
    result.sort((a, b) => b.totalActivities.compareTo(a.totalActivities));
    return result.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final data = _collaboratorData;

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = data.fold<int>(
      0,
      (prev, c) => c.totalActivities > prev ? c.totalActivities : prev,
    );

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
                Icon(Icons.people_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'Carga por colaborador',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Collaborator bars
            ...data.map((collab) {
              return _CollaboratorBar(data: collab, maxValue: maxValue);
            }),
          ],
        ),
      ),
    );
  }
}

class _CollaboratorData {
  final String name;
  final String email;
  int totalActivities;
  int completedActivities;
  int inProgressActivities;
  int overdueActivities;

  _CollaboratorData({
    required this.name,
    required this.email,
    this.totalActivities = 0,
    this.completedActivities = 0,
    this.inProgressActivities = 0,
    this.overdueActivities = 0,
  });

  double get completionRate =>
      totalActivities > 0 ? completedActivities / totalActivities : 0;
}

class _CollaboratorBar extends StatelessWidget {
  final _CollaboratorData data;
  final int maxValue;

  const _CollaboratorBar({required this.data, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final percentage = (data.completionRate * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + stats
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  data.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  data.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${data.completedActivities}/${data.totalActivities}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: data.completionRate >= 0.8
                      ? AppColors.success.withOpacity(0.1)
                      : data.completionRate >= 0.5
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '$percentage%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: data.completionRate >= 0.8
                        ? AppColors.success
                        : data.completionRate >= 0.5
                        ? AppColors.warning
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.sm),

          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final available = constraints.maxWidth;
                  final totalWidth = maxValue > 0
                      ? available * (data.totalActivities / maxValue)
                      : 0.0;

                  return Stack(
                    children: [
                      // Background
                      Container(width: available, color: AppColors.divider),
                      // Completed (green)
                      Container(
                        width: maxValue > 0
                            ? available * (data.completedActivities / maxValue)
                            : 0,
                        color: AppColors.success,
                      ),
                      // In progress (yellow) - stacked after completed
                      Positioned(
                        left: maxValue > 0
                            ? available * (data.completedActivities / maxValue)
                            : 0,
                        child: Container(
                          width: maxValue > 0
                              ? available *
                                    (data.inProgressActivities / maxValue)
                              : 0,
                          height: 8,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Overdue indicator
          if (data.overdueActivities > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 12,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${data.overdueActivities} vencida(s)',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.error,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
