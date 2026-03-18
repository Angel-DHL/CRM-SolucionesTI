// lib/operatividad/widgets/operatividad_list_view.dart

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/role.dart';
import '../models/oper_activity.dart';

class OperatividadListView extends StatefulWidget {
  final List<OperActivity> activities;
  final UserRole role;
  final ValueChanged<OperActivity> onActivityTap;

  const OperatividadListView({
    super.key,
    required this.activities,
    required this.role,
    required this.onActivityTap,
  });

  @override
  State<OperatividadListView> createState() => _OperatividadListViewState();
}

class _OperatividadListViewState extends State<OperatividadListView> {
  String _sortBy = 'plannedStartAt';
  bool _sortAscending = true;

  List<OperActivity> get _sortedActivities {
    final sorted = List<OperActivity>.from(widget.activities);

    sorted.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'title':
          result = a.title.compareTo(b.title);
          break;
        case 'status':
          result = a.status.index.compareTo(b.status.index);
          break;
        case 'progress':
          result = a.progress.compareTo(b.progress);
          break;
        case 'plannedEndAt':
          result = a.plannedEndAt.compareTo(b.plannedEndAt);
          break;
        case 'plannedStartAt':
        default:
          result = a.plannedStartAt.compareTo(b.plannedStartAt);
      }
      return _sortAscending ? result : -result;
    });

    return sorted;
  }

  void _toggleSort(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = column;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return _buildMobileList();
    }

    return _buildDesktopTable();
  }

  Widget _buildMobileList() {
    final activities = _sortedActivities;

    return Column(
      children: [
        // Sort selector
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Text(
                'Ordenar por:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'plannedStartAt',
                        child: Text('Fecha de inicio'),
                      ),
                      DropdownMenuItem(
                        value: 'plannedEndAt',
                        child: Text('Fecha de fin'),
                      ),
                      DropdownMenuItem(value: 'title', child: Text('Título')),
                      DropdownMenuItem(value: 'status', child: Text('Estado')),
                      DropdownMenuItem(
                        value: 'progress',
                        child: Text('Progreso'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) _toggleSort(value);
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _sortAscending = !_sortAscending),
                icon: Icon(
                  _sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 18,
                ),
                color: AppColors.primary,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.md),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _MobileActivityCard(
                activity: activities[index],
                onTap: () => widget.onActivityTap(activities[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable() {
    final activities = _sortedActivities;

    return Container(
      margin: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
          _TableHeader(
            sortBy: _sortBy,
            sortAscending: _sortAscending,
            onSort: _toggleSort,
          ),

          // Body
          Expanded(
            child: ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return _TableRow(
                  activity: activities[index],
                  isEven: index.isEven,
                  onTap: () => widget.onActivityTap(activities[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String sortBy;
  final bool sortAscending;
  final ValueChanged<String> onSort;

  const _TableHeader({
    required this.sortBy,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg - 1),
        ),
      ),
      child: Row(
        children: [
          _SortableHeaderCell(
            title: 'Actividad',
            column: 'title',
            flex: 3,
            sortBy: sortBy,
            sortAscending: sortAscending,
            onSort: onSort,
          ),
          _SortableHeaderCell(
            title: 'Estado',
            column: 'status',
            flex: 2,
            sortBy: sortBy,
            sortAscending: sortAscending,
            onSort: onSort,
          ),
          _SortableHeaderCell(
            title: 'Progreso',
            column: 'progress',
            flex: 2,
            sortBy: sortBy,
            sortAscending: sortAscending,
            onSort: onSort,
          ),
          _SortableHeaderCell(
            title: 'Inicio',
            column: 'plannedStartAt',
            flex: 2,
            sortBy: sortBy,
            sortAscending: sortAscending,
            onSort: onSort,
          ),
          _SortableHeaderCell(
            title: 'Fin',
            column: 'plannedEndAt',
            flex: 2,
            sortBy: sortBy,
            sortAscending: sortAscending,
            onSort: onSort,
          ),
          const SizedBox(width: 48), // For actions
        ],
      ),
    );
  }
}

class _SortableHeaderCell extends StatelessWidget {
  final String title;
  final String column;
  final int flex;
  final String sortBy;
  final bool sortAscending;
  final ValueChanged<String> onSort;

  const _SortableHeaderCell({
    required this.title,
    required this.column,
    required this.flex,
    required this.sortBy,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sortBy == column;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(column),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              if (isActive)
                Icon(
                  sortAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  final OperActivity activity;
  final bool isEven;
  final VoidCallback onTap;

  const _TableRow({
    required this.activity,
    required this.isEven,
    required this.onTap,
  });

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _isHovered = false;

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

  bool get _isOverdue {
    return widget.activity.plannedEndAt.isBefore(DateTime.now()) &&
        widget.activity.status != OperStatus.done &&
        widget.activity.status != OperStatus.verified;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(widget.activity.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDimensions.animFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primarySurface
                : widget.isEven
                ? AppColors.surface
                : AppColors.background,
            border: Border(
              bottom: BorderSide(color: AppColors.divider),
              left: _isOverdue
                  ? BorderSide(color: AppColors.error, width: 3)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              // Título
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.activity.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.activity.assigneesEmails.take(2).join(', '),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Estado
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.xs,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        widget.activity.status.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progreso
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.activity.progress / 100,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${widget.activity.progress}%',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Fecha inicio
              Expanded(
                flex: 2,
                child: Text(
                  _formatDate(widget.activity.plannedStartAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              // Fecha fin
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    if (_isOverdue)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: AppColors.error,
                        ),
                      ),
                    Text(
                      _formatDate(widget.activity.plannedEndAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _isOverdue
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight: _isOverdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: widget.onTap,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _MobileActivityCard extends StatelessWidget {
  final OperActivity activity;
  final VoidCallback onTap;

  const _MobileActivityCard({required this.activity, required this.onTap});

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

  bool get _isOverdue {
    return activity.plannedEndAt.isBefore(DateTime.now()) &&
        activity.status != OperStatus.done &&
        activity.status != OperStatus.verified;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(activity.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: _isOverdue
              ? AppColors.error.withOpacity(0.5)
              : AppColors.divider,
          width: _isOverdue ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.sm,
                      vertical: AppDimensions.xs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                    child: Text(
                      activity.status.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.md),

              // Progress
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: activity.progress / 100,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    '${activity.progress}%',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.md),

              // Footer row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(activity.plannedStartAt)} - ${_formatDate(activity.plannedEndAt)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _isOverdue ? AppColors.error : AppColors.textHint,
                    ),
                  ),
                  if (_isOverdue) ...[
                    const SizedBox(width: AppDimensions.xs),
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.error,
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
