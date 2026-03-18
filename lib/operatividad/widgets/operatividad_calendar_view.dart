// lib/operatividad/widgets/operatividad_calendar_view.dart

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/oper_activity.dart';

class OperatividadCalendarView extends StatefulWidget {
  final List<OperActivity> activities;
  final ValueChanged<OperActivity> onActivityTap;
  final ValueChanged<DateTime> onDateSelected;

  const OperatividadCalendarView({
    super.key,
    required this.activities,
    required this.onActivityTap,
    required this.onDateSelected,
  });

  @override
  State<OperatividadCalendarView> createState() =>
      _OperatividadCalendarViewState();
}

class _OperatividadCalendarViewState extends State<OperatividadCalendarView> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedDate = DateTime.now();
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<OperActivity> _getActivitiesForDate(DateTime date) {
    return widget.activities.where((a) {
      final start = DateTime(
        a.plannedStartAt.year,
        a.plannedStartAt.month,
        a.plannedStartAt.day,
      );
      final end = DateTime(
        a.plannedEndAt.year,
        a.plannedEndAt.month,
        a.plannedEndAt.day,
      );
      final checkDate = DateTime(date.year, date.month, date.day);
      return !checkDate.isBefore(start) && !checkDate.isAfter(end);
    }).toList();
  }

  List<OperActivity> get _selectedDateActivities {
    if (_selectedDate == null) return [];
    return _getActivitiesForDate(_selectedDate!);
  }

  void _goToMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          Expanded(flex: 2, child: _buildCalendar()),
          const Divider(height: 1),
          Expanded(flex: 1, child: _buildSelectedDateActivities()),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: _buildCalendar()),
        Container(width: 1, color: AppColors.divider),
        Expanded(flex: 2, child: _buildSelectedDateActivities()),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: AppDimensions.lg),
          _buildWeekDaysHeader(),
          const SizedBox(height: AppDimensions.sm),
          Expanded(child: _buildCalendarGrid()),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthNames = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _goToMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Mes anterior',
            ),
            const SizedBox(width: AppDimensions.sm),
            Text(
              '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            IconButton(
              onPressed: () => _goToMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Mes siguiente',
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _goToToday,
          icon: const Icon(Icons.today_rounded, size: 18),
          label: const Text('Hoy'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildWeekDaysHeader() {
    final weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return Row(
      children: weekDays.map((day) {
        final isWeekend = day == 'Sáb' || day == 'Dom';
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: AppTextStyles.labelMedium.copyWith(
                color: isWeekend ? AppColors.textHint : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );

    // Ajustar para que la semana empiece en lunes
    int startingWeekday = firstDayOfMonth.weekday - 1;
    if (startingWeekday < 0) startingWeekday = 6;

    final daysInMonth = lastDayOfMonth.day;
    final totalCells = startingWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Expanded(
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - startingWeekday + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return Expanded(child: Container());
              }

              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                dayNumber,
              );
              final activities = _getActivitiesForDate(date);

              return Expanded(
                child: _CalendarDayCell(
                  date: date,
                  activities: activities,
                  isSelected:
                      _selectedDate != null &&
                      _selectedDate!.year == date.year &&
                      _selectedDate!.month == date.month &&
                      _selectedDate!.day == date.day,
                  isToday:
                      DateTime.now().year == date.year &&
                      DateTime.now().month == date.month &&
                      DateTime.now().day == date.day,
                  onTap: () {
                    setState(() => _selectedDate = date);
                    widget.onDateSelected(date);
                  },
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildSelectedDateActivities() {
    Responsive.isMobile(context);

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(
                    Icons.event_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDate != null
                            ? _formatSelectedDate(_selectedDate!)
                            : 'Selecciona una fecha',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_selectedDateActivities.length} actividades',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedDateActivities.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    itemCount: _selectedDateActivities.length,
                    itemBuilder: (context, index) {
                      final activity = _selectedDateActivities[index];
                      return _CalendarActivityItem(
                        activity: activity,
                        onTap: () => widget.onActivityTap(activity),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            'Sin actividades',
            style: AppTextStyles.h3.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'No hay actividades para esta fecha',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDate(DateTime date) {
    final weekDays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${weekDays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }
}

class _CalendarDayCell extends StatefulWidget {
  final DateTime date;
  final List<OperActivity> activities;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.activities,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  State<_CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends State<_CalendarDayCell> {
  bool _isHovered = false;

  bool get _hasOverdue {
    final now = DateTime.now();
    return widget.activities.any(
      (a) =>
          a.plannedEndAt.isBefore(now) &&
          a.status != OperStatus.done &&
          a.status != OperStatus.verified,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeekend = widget.date.weekday == 6 || widget.date.weekday == 7;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDimensions.animFast,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary
                : widget.isToday
                ? AppColors.primarySurface
                : _isHovered
                ? AppColors.divider.withOpacity(0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: widget.isToday && !widget.isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              // Número del día
              Center(
                child: Text(
                  widget.date.day.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: widget.isSelected
                        ? Colors.white
                        : isWeekend
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                    fontWeight: widget.isToday || widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),

              // Indicadores de actividades
              if (widget.activities.isNotEmpty)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_hasOverdue)
                        _ActivityDot(color: AppColors.error)
                      else
                        ...widget.activities.take(3).map((a) {
                          return _ActivityDot(
                            color: widget.isSelected
                                ? Colors.white.withOpacity(0.8)
                                : _getStatusColor(a.status),
                          );
                        }),
                      if (widget.activities.length > 3)
                        Text(
                          '+${widget.activities.length - 3}',
                          style: TextStyle(
                            fontSize: 8,
                            color: widget.isSelected
                                ? Colors.white.withOpacity(0.8)
                                : AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
}

class _ActivityDot extends StatelessWidget {
  final Color color;

  const _ActivityDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CalendarActivityItem extends StatelessWidget {
  final OperActivity activity;
  final VoidCallback onTap;

  const _CalendarActivityItem({required this.activity, required this.onTap});

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
    final color = _getStatusColor(activity.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatTime(activity.plannedStartAt)} - ${_formatTime(activity.plannedEndAt)}',
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

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
