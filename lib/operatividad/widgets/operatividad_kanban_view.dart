// lib/operatividad/widgets/operatividad_kanban_view.dart

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/oper_activity.dart';

class OperatividadKanbanView extends StatefulWidget {
  final List<OperActivity> activities;
  final ValueChanged<OperActivity> onActivityTap;
  final void Function(OperActivity activity, OperStatus newStatus)
  onStatusChange;

  const OperatividadKanbanView({
    super.key,
    required this.activities,
    required this.onActivityTap,
    required this.onStatusChange,
  });

  @override
  State<OperatividadKanbanView> createState() => _OperatividadKanbanViewState();
}

class _OperatividadKanbanViewState extends State<OperatividadKanbanView> {
  final ScrollController _horizontalScrollController = ScrollController();

  final List<OperStatus> _columns = [
    OperStatus.planned,
    OperStatus.inProgress,
    OperStatus.done,
    OperStatus.verified,
    OperStatus.blocked,
  ];

  List<OperActivity> _getActivitiesForStatus(OperStatus status) {
    return widget.activities.where((a) => a.status == status).toList()
      ..sort((a, b) => a.plannedStartAt.compareTo(b.plannedStartAt));
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final columnWidth = isMobile ? 280.0 : 320.0;

    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _columns.map((status) {
            final activities = _getActivitiesForStatus(status);
            return _KanbanColumn(
              status: status,
              activities: activities,
              width: columnWidth,
              onActivityTap: widget.onActivityTap,
              onDrop: (activity) {
                widget.onStatusChange(activity, status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final OperStatus status;
  final List<OperActivity> activities;
  final double width;
  final ValueChanged<OperActivity> onActivityTap;
  final ValueChanged<OperActivity> onDrop;

  const _KanbanColumn({
    required this.status,
    required this.activities,
    required this.width,
    required this.onActivityTap,
    required this.onDrop,
  });

  Color _getStatusColor() {
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

  IconData _getStatusIcon() {
    switch (status) {
      case OperStatus.planned:
        return Icons.schedule_rounded;
      case OperStatus.inProgress:
        return Icons.pending_actions_rounded;
      case OperStatus.done:
        return Icons.check_circle_rounded;
      case OperStatus.verified:
        return Icons.verified_rounded;
      case OperStatus.blocked:
        return Icons.block_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return DragTarget<OperActivity>(
      onAcceptWithDetails: (details) {
        onDrop(details.data);
      },
      onWillAcceptWithDetails: (details) {
        return details.data.status != status;
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: AppDimensions.animFast,
          width: width,
          margin: const EdgeInsets.only(right: AppDimensions.md),
          decoration: BoxDecoration(
            color: isHovering ? color.withOpacity(0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isHovering ? color : AppColors.divider,
              width: isHovering ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusLg - 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(), color: color, size: 20),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        status.label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.xs / 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                      child: Text(
                        activities.length.toString(),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Activities list
              Expanded(
                child: activities.isEmpty
                    ? _EmptyColumn(color: color)
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDimensions.sm),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return _KanbanCard(
                            activity: activity,
                            onTap: () => onActivityTap(activity),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanCard extends StatefulWidget {
  final OperActivity activity;
  final VoidCallback onTap;

  const _KanbanCard({required this.activity, required this.onTap});

  @override
  State<_KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends State<_KanbanCard> {
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

    return Draggable<OperActivity>(
      data: widget.activity,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            widget.activity.title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: _buildCard(color)),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppDimensions.animFast,
            transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
            child: _buildCard(color),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: _isHovered ? AppColors.primarySurface : AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: _isOverdue
              ? AppColors.error.withOpacity(0.5)
              : _isHovered
              ? color.withOpacity(0.5)
              : AppColors.divider,
          width: _isOverdue || _isHovered ? 2 : 1,
        ),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            widget.activity.title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (widget.activity.description.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(
              widget.activity.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppDimensions.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: widget.activity.progress / 100,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),

          const SizedBox(height: AppDimensions.md),

          // Footer
          Row(
            children: [
              // Progreso
              Text(
                '${widget.activity.progress}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              // Fecha
              if (_isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Vencida',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.error,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  _formatDate(widget.activity.plannedEndAt),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),

              const SizedBox(width: AppDimensions.sm),

              // Avatares de asignados
              _AssigneeAvatars(
                emails: widget.activity.assigneesEmails,
                maxVisible: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _AssigneeAvatars extends StatelessWidget {
  final List<String> emails;
  final int maxVisible;

  const _AssigneeAvatars({required this.emails, this.maxVisible = 3});

  @override
  Widget build(BuildContext context) {
    final visibleEmails = emails.take(maxVisible).toList();
    final remaining = emails.length - maxVisible;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleEmails.asMap().entries.map((entry) {
          return Transform.translate(
            offset: Offset(-entry.key * 8.0, 0),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getAvatarColor(entry.key),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Center(
                child: Text(
                  entry.value.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
        if (remaining > 0)
          Transform.translate(
            offset: Offset(-visibleEmails.length * 8.0, 0),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Center(
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.warning,
      AppColors.success,
    ];
    return colors[index % colors.length];
  }
}

class _EmptyColumn extends StatelessWidget {
  final Color color;

  const _EmptyColumn({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: color.withOpacity(0.3)),
            const SizedBox(height: AppDimensions.md),
            Text(
              'Sin actividades',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Arrastra aquí para mover',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
