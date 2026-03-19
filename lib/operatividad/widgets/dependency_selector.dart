// lib/operatividad/widgets/dependency_selector.dart

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/oper_activity.dart';

class DependencySelector extends StatefulWidget {
  final List<OperActivity> availableActivities;
  final List<String> selectedDependencies;
  final ValueChanged<List<String>> onChanged;

  const DependencySelector({
    super.key,
    required this.availableActivities,
    required this.selectedDependencies,
    required this.onChanged,
  });

  @override
  State<DependencySelector> createState() => _DependencySelectorState();
}

class _DependencySelectorState extends State<DependencySelector> {
  String _searchQuery = '';

  List<OperActivity> get _filteredActivities {
    var activities = widget.availableActivities;

    if (_searchQuery.isNotEmpty) {
      activities = activities
          .where(
            (a) => a.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return activities;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar actividad...',
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),

        const SizedBox(height: AppDimensions.md),

        // Selected dependencies
        if (widget.selectedDependencies.isNotEmpty) ...[
          Text(
            'Depende de:',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Wrap(
            spacing: AppDimensions.sm,
            runSpacing: AppDimensions.sm,
            children: widget.selectedDependencies.map((depId) {
              final activity = widget.availableActivities
                  .where((a) => a.id == depId)
                  .firstOrNull;

              return Chip(
                label: Text(activity?.title ?? depId),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
                backgroundColor: AppColors.primarySurface,
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                deleteIconColor: AppColors.primary,
                onDeleted: () {
                  final updated = List<String>.from(
                    widget.selectedDependencies,
                  );
                  updated.remove(depId);
                  widget.onChanged(updated);
                },
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.md),
        ],

        // Available activities
        if (_filteredActivities.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Text(
                'No hay actividades disponibles',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredActivities.length,
              itemBuilder: (context, index) {
                final activity = _filteredActivities[index];
                final isSelected = widget.selectedDependencies.contains(
                  activity.id,
                );
                final color = _getStatusColor(activity.status);

                return AnimatedContainer(
                  duration: AppDimensions.animFast,
                  margin: const EdgeInsets.only(bottom: AppDimensions.xs),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primarySurface
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 4,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    title: Text(
                      activity.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
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
                            activity.status.label,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${activity.progress}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (checked) {
                        final updated = List<String>.from(
                          widget.selectedDependencies,
                        );
                        if (checked == true) {
                          updated.add(activity.id);
                        } else {
                          updated.remove(activity.id);
                        }
                        widget.onChanged(updated);
                      },
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      final updated = List<String>.from(
                        widget.selectedDependencies,
                      );
                      if (isSelected) {
                        updated.remove(activity.id);
                      } else {
                        updated.add(activity.id);
                      }
                      widget.onChanged(updated);
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
