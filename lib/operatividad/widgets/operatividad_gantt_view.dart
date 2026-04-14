// lib/operatividad/widgets/operatividad_gantt_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/oper_activity.dart';

class OperatividadGanttView extends StatefulWidget {
  final List<OperActivity> activities;
  final ValueChanged<OperActivity> onActivityTap;

  const OperatividadGanttView({
    super.key,
    required this.activities,
    required this.onActivityTap,
  });

  @override
  State<OperatividadGanttView> createState() => _OperatividadGanttViewState();
}

class _OperatividadGanttViewState extends State<OperatividadGanttView> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _namesScrollController = ScrollController();

  double _dayWidth = 40.0;

  late DateTime _startDate;
  late DateTime _endDate;
  late int _totalDays;

  // ✅ Getters responsivos - se calculan según el dispositivo
  double get _rowHeight {
    if (!mounted) return 48.0;
    return Responsive.isMobile(context) ? 44.0 : 56.0;
  }

  double get _headerHeight {
    if (!mounted) return 50.0;
    return Responsive.isMobile(context) ? 50.0 : 60.0;
  }

  double get _namesColumnWidth {
    if (!mounted) return 160.0;
    return Responsive.isMobile(context) ? 120.0 : 240.0;
  }

  double get _barHeight {
    if (!mounted) return 24.0;
    return Responsive.isMobile(context) ? 24.0 : 32.0;
  }

  @override
  void initState() {
    super.initState();
    _calculateDateRange();
    _setupScrollSync();
  }

  @override
  void didUpdateWidget(OperatividadGanttView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalcular si las actividades cambian
    if (widget.activities != oldWidget.activities) {
      _calculateDateRange();
    }
  }

  void _calculateDateRange() {
    if (widget.activities.isEmpty) {
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 30));
    } else {
      _startDate = widget.activities
          .map((a) => a.plannedStartAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      _endDate = widget.activities
          .map((a) => a.plannedEndAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    // Agregar margen de días
    _startDate = _startDate.subtract(const Duration(days: 3));
    _endDate = _endDate.add(const Duration(days: 7));
    _totalDays = _endDate.difference(_startDate).inDays + 1;
  }

  void _setupScrollSync() {
    _verticalScrollController.addListener(_syncVerticalScroll);
    _namesScrollController.addListener(_syncNamesScroll);
  }

  void _syncVerticalScroll() {
    if (_namesScrollController.hasClients &&
        _namesScrollController.offset != _verticalScrollController.offset) {
      _namesScrollController.jumpTo(_verticalScrollController.offset);
    }
  }

  void _syncNamesScroll() {
    if (_verticalScrollController.hasClients &&
        _verticalScrollController.offset != _namesScrollController.offset) {
      _verticalScrollController.jumpTo(_namesScrollController.offset);
    }
  }

  @override
  void dispose() {
    _verticalScrollController.removeListener(_syncVerticalScroll);
    _namesScrollController.removeListener(_syncNamesScroll);
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _namesScrollController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _dayWidth = (_dayWidth + 10).clamp(30.0, 100.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _dayWidth = (_dayWidth - 10).clamp(30.0, 100.0);
    });
  }

  void _scrollToToday() {
    final today = DateTime.now();
    final daysFromStart = today.difference(_startDate).inDays;
    final scrollPosition = daysFromStart * _dayWidth;

    _horizontalScrollController.animateTo(
      (scrollPosition - 100).clamp(0.0, double.infinity),
      duration: AppDimensions.animNormal,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activities.isEmpty) {
      return _buildEmptyState();
    }

    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        // Toolbar
        _buildToolbar(isMobile),

        // Gantt Chart
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna de nombres (fija)
              SizedBox(
                width: _namesColumnWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      right: BorderSide(color: AppColors.divider, width: 2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildNamesHeader(isMobile),
                      Expanded(child: _buildNamesList(isMobile)),
                    ],
                  ),
                ),
              ),

              // Timeline (scrollable)
              Expanded(child: _buildTimeline(isMobile)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppDimensions.sm : AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Leyenda - solo mostrar en desktop/tablet
          if (!isMobile)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _LegendItem(color: AppColors.info, label: 'Planeada'),
                    const SizedBox(width: AppDimensions.md),
                    _LegendItem(color: AppColors.warning, label: 'En progreso'),
                    const SizedBox(width: AppDimensions.md),
                    _LegendItem(color: AppColors.success, label: 'Completada'),
                    const SizedBox(width: AppDimensions.md),
                    _LegendItem(color: AppColors.error, label: 'Bloqueada'),
                  ],
                ),
              ),
            )
          else
            const Spacer(),

          // Controles de zoom
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _scrollToToday,
                icon: const Icon(Icons.today_rounded),
                tooltip: 'Ir a hoy',
                color: AppColors.primary,
                iconSize: isMobile ? 20 : 24,
                visualDensity: VisualDensity.compact,
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppDimensions.xs : AppDimensions.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _zoomOut,
                      icon: const Icon(Icons.remove_rounded),
                      tooltip: 'Alejar',
                      color: AppColors.textSecondary,
                      iconSize: isMobile ? 16 : 18,
                      visualDensity: VisualDensity.compact,
                      constraints: BoxConstraints(
                        minWidth: isMobile ? 32 : 40,
                        minHeight: isMobile ? 32 : 40,
                      ),
                    ),
                    if (!isMobile)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '${((_dayWidth - 30) / 70 * 100).round()}%',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: _zoomIn,
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Acercar',
                      color: AppColors.textSecondary,
                      iconSize: isMobile ? 16 : 18,
                      visualDensity: VisualDensity.compact,
                      constraints: BoxConstraints(
                        minWidth: isMobile ? 32 : 40,
                        minHeight: isMobile ? 32 : 40,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNamesHeader(bool isMobile) {
    return Container(
      height: _headerHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppDimensions.sm : AppDimensions.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        isMobile ? 'Tarea' : 'Actividad',
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: isMobile ? 12 : 14,
        ),
      ),
    );
  }

  Widget _buildNamesList(bool isMobile) {
    return ListView.builder(
      controller: _namesScrollController,
      physics: const ClampingScrollPhysics(),
      itemCount: widget.activities.length,
      itemBuilder: (context, index) {
        final activity = widget.activities[index];
        return _ActivityNameRow(
          activity: activity,
          height: _rowHeight,
          onTap: () => widget.onActivityTap(activity),
          isMobile: isMobile,
        );
      },
    );
  }

  Widget _buildTimeline(bool isMobile) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          if (event.scrollDelta.dy != 0) {
            _horizontalScrollController.jumpTo(
              (_horizontalScrollController.offset + event.scrollDelta.dy).clamp(
                0.0,
                _horizontalScrollController.position.maxScrollExtent,
              ),
            );
          }
        }
      },
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: SizedBox(
          width: _totalDays * _dayWidth,
          child: Column(
            children: [
              _TimelineHeader(
                startDate: _startDate,
                totalDays: _totalDays,
                dayWidth: _dayWidth,
                height: _headerHeight,
                isMobile: isMobile,
              ),
              Expanded(
                child: _TimelineBody(
                  activities: widget.activities,
                  startDate: _startDate,
                  totalDays: _totalDays,
                  dayWidth: _dayWidth,
                  rowHeight: _rowHeight,
                  barHeight: _barHeight,
                  scrollController: _verticalScrollController,
                  onActivityTap: widget.onActivityTap,
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isMobile = Responsive.isMobile(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_rounded,
              size: isMobile ? 48 : 64,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text(
              'Sin actividades',
              style: (isMobile ? AppTextStyles.bodyLarge : AppTextStyles.h3)
                  .copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Crea actividades para ver la línea de tiempo',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Legend Item
// ══════════════════════════════════════════════════════════════

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppDimensions.xs),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Activity Name Row
// ══════════════════════════════════════════════════════════════

class _ActivityNameRow extends StatefulWidget {
  final OperActivity activity;
  final double height;
  final VoidCallback onTap;
  final bool isMobile;

  const _ActivityNameRow({
    required this.activity,
    required this.height,
    required this.onTap,
    required this.isMobile,
  });

  @override
  State<_ActivityNameRow> createState() => _ActivityNameRowState();
}

class _ActivityNameRowState extends State<_ActivityNameRow> {
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

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(widget.activity.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDimensions.animFast,
          height: widget.height,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isMobile ? AppDimensions.xs : AppDimensions.md,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.primarySurface : AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              // Indicador de color
              Container(
                width: widget.isMobile ? 3 : 4,
                height: widget.isMobile ? 24 : 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(
                width: widget.isMobile ? AppDimensions.xs : AppDimensions.sm,
              ),

              // Título
              Expanded(
                child: Text(
                  widget.activity.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: widget.isMobile ? 11 : 14,
                  ),
                  maxLines: widget.isMobile ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Flecha (solo en desktop)
              if (!widget.isMobile)
                Icon(
                  Icons.chevron_right_rounded,
                  color: _isHovered ? AppColors.primary : AppColors.textHint,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Timeline Header
// ══════════════════════════════════════════════════════════════

class _TimelineHeader extends StatelessWidget {
  final DateTime startDate;
  final int totalDays;
  final double dayWidth;
  final double height;
  final bool isMobile;

  const _TimelineHeader({
    required this.startDate,
    required this.totalDays,
    required this.dayWidth,
    required this.height,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final months = <_MonthSpan>[];
    DateTime? currentMonthStart;
    int currentMonthDays = 0;

    for (int i = 0; i < totalDays; i++) {
      final date = startDate.add(Duration(days: i));

      if (currentMonthStart == null) {
        currentMonthStart = date;
        currentMonthDays = 1;
      } else if (date.month != currentMonthStart.month ||
          date.year != currentMonthStart.year) {
        months.add(_MonthSpan(date: currentMonthStart, days: currentMonthDays));
        currentMonthStart = date;
        currentMonthDays = 1;
      } else {
        currentMonthDays++;
      }
    }

    if (currentMonthStart != null) {
      months.add(_MonthSpan(date: currentMonthStart, days: currentMonthDays));
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          // Meses
          Expanded(
            child: Row(
              children: months.map((month) {
                return Container(
                  width: month.days * dayWidth,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.divider)),
                  ),
                  child: Text(
                    _getMonthName(month.date),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 10 : 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),

          // Días
          Expanded(
            child: Row(
              children: List.generate(totalDays, (index) {
                final date = startDate.add(Duration(days: index));
                final isToday = _isToday(date);
                final isWeekend = date.weekday == 6 || date.weekday == 7;

                return Container(
                  width: dayWidth,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primary.withOpacity(0.1) : null,
                    border: Border(
                      right: BorderSide(
                        color: AppColors.divider.withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: Text(
                    date.day.toString(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isToday
                          ? AppColors.primary
                          : isWeekend
                          ? AppColors.textHint
                          : AppColors.textSecondary,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      fontSize: isMobile ? 9 : 11,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getMonthName(DateTime date) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    if (isMobile) {
      return months[date.month - 1];
    }
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _MonthSpan {
  final DateTime date;
  final int days;

  _MonthSpan({required this.date, required this.days});
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Timeline Body
// ══════════════════════════════════════════════════════════════

class _TimelineBody extends StatelessWidget {
  final List<OperActivity> activities;
  final DateTime startDate;
  final int totalDays;
  final double dayWidth;
  final double rowHeight;
  final double barHeight;
  final ScrollController scrollController;
  final ValueChanged<OperActivity> onActivityTap;
  final bool isMobile;

  const _TimelineBody({
    required this.activities,
    required this.startDate,
    required this.totalDays,
    required this.dayWidth,
    required this.rowHeight,
    required this.barHeight,
    required this.scrollController,
    required this.onActivityTap,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _TimelineRow(
          activity: activity,
          startDate: startDate,
          totalDays: totalDays,
          dayWidth: dayWidth,
          rowHeight: rowHeight,
          barHeight: barHeight,
          onTap: () => onActivityTap(activity),
          isMobile: isMobile,
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WIDGET: Timeline Row
// ══════════════════════════════════════════════════════════════

class _TimelineRow extends StatefulWidget {
  final OperActivity activity;
  final DateTime startDate;
  final int totalDays;
  final double dayWidth;
  final double rowHeight;
  final double barHeight;
  final VoidCallback onTap;
  final bool isMobile;

  const _TimelineRow({
    required this.activity,
    required this.startDate,
    required this.totalDays,
    required this.dayWidth,
    required this.rowHeight,
    required this.barHeight,
    required this.onTap,
    required this.isMobile,
  });

  @override
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow> {
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

  @override
  Widget build(BuildContext context) {
    final startOffset = widget.activity.plannedStartAt
        .difference(widget.startDate)
        .inDays;
    final duration =
        widget.activity.plannedEndAt
            .difference(widget.activity.plannedStartAt)
            .inDays +
        1;

    final left = (startOffset * widget.dayWidth).clamp(0.0, double.infinity);
    final width = (duration * widget.dayWidth).clamp(20.0, double.infinity);
    final color = _getStatusColor(widget.activity.status);

    // Calcular posición vertical centrada
    final topPadding = (widget.rowHeight - widget.barHeight) / 2;

    return SizedBox(
      height: widget.rowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Líneas de fondo (días)
          Row(
            children: List.generate(widget.totalDays, (index) {
              final date = widget.startDate.add(Duration(days: index));
              final isToday = _isToday(date);
              final isWeekend = date.weekday == 6 || date.weekday == 7;

              return Container(
                width: widget.dayWidth,
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withOpacity(0.05)
                      : isWeekend
                      ? AppColors.divider.withOpacity(0.3)
                      : null,
                  border: Border(
                    right: BorderSide(
                      color: AppColors.divider.withOpacity(0.3),
                    ),
                    bottom: BorderSide(color: AppColors.divider),
                  ),
                ),
              );
            }),
          ),

          // Barra de actividad
          Positioned(
            left: left,
            top: topPadding,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: AppDimensions.animFast,
                  width: width,
                  height: widget.barHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(
                      widget.isMobile ? 4 : 6,
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Progress bar
                      FractionallySizedBox(
                        widthFactor: widget.activity.progress / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(
                              widget.isMobile ? 4 : 6,
                            ),
                          ),
                        ),
                      ),

                      // Progress text
                      Center(
                        child: Text(
                          '${widget.activity.progress}%',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: widget.isMobile ? 9 : 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
