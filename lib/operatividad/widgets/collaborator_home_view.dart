// lib/operatividad/widgets/collaborator_home_view.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../models/oper_activity.dart';
import 'sla_indicator.dart';

class CollaboratorHomeView extends StatefulWidget {
  final List<OperActivity> activities;
  final ValueChanged<OperActivity> onActivityTap;

  const CollaboratorHomeView({
    super.key,
    required this.activities,
    required this.onActivityTap,
  });

  @override
  State<CollaboratorHomeView> createState() => _CollaboratorHomeViewState();
}

class _CollaboratorHomeViewState extends State<CollaboratorHomeView> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _currentEmail => FirebaseAuth.instance.currentUser?.email ?? '';
  String get _currentName => _currentEmail.split('@').first;

  // Actividades del usuario actual
  List<OperActivity> get _myActivities {
    return widget.activities
        .where((a) => a.assigneesUids.contains(_currentUid))
        .toList();
  }

  // Actividad en progreso actualmente
  OperActivity? get _currentlyWorking {
    try {
      return _myActivities.firstWhere(
        (a) => a.workStartAt != null && a.workEndAt == null,
      );
    } catch (_) {
      return null;
    }
  }

  // Próxima actividad
  OperActivity? get _nextActivity {
    final planned =
        _myActivities
            .where(
              (a) =>
                  a.status == OperStatus.planned &&
                  a.plannedStartAt.isAfter(_now),
            )
            .toList()
          ..sort((a, b) => a.plannedStartAt.compareTo(b.plannedStartAt));

    return planned.isEmpty ? null : planned.first;
  }

  // Actividades urgentes (SLA crítico o vencidas)
  List<OperActivity> get _urgentActivities {
    return _myActivities.where((a) {
      if (a.status == OperStatus.done || a.status == OperStatus.verified) {
        return false;
      }
      return a.isOverdue ||
          a.slaLevel == SlaLevel.critical ||
          a.slaLevel == SlaLevel.breached ||
          a.priority == 'high';
    }).toList()..sort((a, b) {
      // Priorizar por SLA breach > overdue > high priority
      final aScore = _urgencyScore(a);
      final bScore = _urgencyScore(b);
      return bScore.compareTo(aScore);
    });
  }

  int _urgencyScore(OperActivity a) {
    int score = 0;
    if (a.slaLevel == SlaLevel.breached) score += 100;
    if (a.slaLevel == SlaLevel.critical) score += 80;
    if (a.isOverdue) score += 60;
    if (a.priority == 'high') score += 40;
    if (a.slaLevel == SlaLevel.warning) score += 20;
    return score;
  }

  // Estadísticas del día
  int get _todayCompleted {
    final todayStart = DateTime(_now.year, _now.month, _now.day);
    return _myActivities.where((a) {
      final completed = a.workEndAt ?? a.actualEndAt;
      if (completed == null) return false;
      return completed.isAfter(todayStart) &&
          (a.status == OperStatus.done || a.status == OperStatus.verified);
    }).length;
  }

  double get _weeklyCompletionRate {
    final weekStart = _now.subtract(Duration(days: _now.weekday - 1));
    final weekActivities = _myActivities.where((a) {
      return a.plannedEndAt.isAfter(weekStart) && a.plannedEndAt.isBefore(_now);
    }).toList();

    if (weekActivities.isEmpty) return 0;

    final completed = weekActivities.where(
      (a) => a.status == OperStatus.done || a.status == OperStatus.verified,
    );

    return completed.length / weekActivities.length;
  }

  Duration get _todayWorkDuration {
    final todayStart = DateTime(_now.year, _now.month, _now.day);
    Duration total = Duration.zero;

    for (final a in _myActivities) {
      if (a.workStartAt == null) continue;
      if (a.workStartAt!.isBefore(todayStart)) continue;

      final end = a.workEndAt ?? _now;
      total += end.difference(a.workStartAt!);
    }

    return total;
  }

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? AppDimensions.md : AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenida + Reloj
          _buildWelcomeCard(),
          const SizedBox(height: AppDimensions.lg),

          // Stats rápidas del día
          _buildDayStats(isMobile),
          const SizedBox(height: AppDimensions.lg),

          // Actividad actual (si hay)
          if (_currentlyWorking != null) ...[
            _buildCurrentWorkCard(_currentlyWorking!),
            const SizedBox(height: AppDimensions.lg),
          ],

          // Urgentes
          if (_urgentActivities.isNotEmpty) ...[
            _buildUrgentSection(),
            const SizedBox(height: AppDimensions.lg),
          ],

          // Próxima actividad
          if (_nextActivity != null) ...[
            _buildNextActivityCard(_nextActivity!),
            const SizedBox(height: AppDimensions.lg),
          ],

          // Mis actividades pendientes
          _buildPendingActivities(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final greeting = _now.hour < 12
        ? 'Buenos días'
        : _now.hour < 18
        ? 'Buenas tardes'
        : 'Buenas noches';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _currentName.substring(0, 1).toUpperCase(),
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  _currentName,
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _formatFullDate(_now),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayStats(bool isMobile) {
    final workHours = _todayWorkDuration.inHours;
    final workMinutes = _todayWorkDuration.inMinutes % 60;
    final weekRate = (_weeklyCompletionRate * 100).toStringAsFixed(0);
    final pending = _myActivities
        .where(
          (a) => a.status != OperStatus.done && a.status != OperStatus.verified,
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: _StatMiniCard(
            icon: Icons.check_circle_rounded,
            label: 'Completadas hoy',
            value: _todayCompleted.toString(),
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatMiniCard(
            icon: Icons.timer_rounded,
            label: 'Trabajado hoy',
            value: '${workHours}h ${workMinutes}m',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatMiniCard(
            icon: Icons.trending_up_rounded,
            label: 'Cumplimiento sem.',
            value: '$weekRate%',
            color: _weeklyCompletionRate >= 0.8
                ? AppColors.success
                : _weeklyCompletionRate >= 0.5
                ? AppColors.warning
                : AppColors.error,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatMiniCard(
            icon: Icons.pending_actions_rounded,
            label: 'Pendientes',
            value: pending.toString(),
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentWorkCard(OperActivity activity) {
    final elapsed = _now.difference(activity.workStartAt!);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;

    return Card(
      elevation: 0,
      color: AppColors.successLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(
                    Icons.play_circle_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trabajando ahora',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        activity.title,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md,
                    vertical: AppDimensions.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    '${hours}h ${minutes}m',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            // Progress + SLA
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: activity.progress / 100,
                      backgroundColor: AppColors.success.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(AppColors.success),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  '${activity.progress}%',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (activity.hasSla) ...[
                  const SizedBox(width: AppDimensions.md),
                  SlaIndicator(activity: activity, compact: true),
                ],
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => widget.onActivityTap(activity),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ver detalles'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.priority_high_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: AppDimensions.sm),
            Text(
              'Requiere tu atención',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                '${_urgentActivities.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        ..._urgentActivities
            .take(3)
            .map(
              (a) => _UrgentActivityCard(
                activity: a,
                onTap: () => widget.onActivityTap(a),
              ),
            ),
      ],
    );
  }

  Widget _buildNextActivityCard(OperActivity activity) {
    final timeUntil = activity.plannedStartAt.difference(_now);
    String timeText;

    if (timeUntil.inDays > 0) {
      timeText = 'En ${timeUntil.inDays} día(s)';
    } else if (timeUntil.inHours > 0) {
      timeText = 'En ${timeUntil.inHours}h ${timeUntil.inMinutes % 60}m';
    } else {
      timeText = 'En ${timeUntil.inMinutes}m';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.info.withOpacity(0.3)),
      ),
      color: AppColors.infoLight,
      child: InkWell(
        onTap: () => widget.onActivityTap(activity),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(Icons.upcoming_rounded, color: AppColors.info),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próxima actividad',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                    Text(
                      activity.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  timeText,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingActivities() {
    final pending =
        _myActivities
            .where(
              (a) =>
                  a.status != OperStatus.done &&
                  a.status != OperStatus.verified,
            )
            .toList()
          ..sort((a, b) => a.plannedEndAt.compareTo(b.plannedEndAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis actividades pendientes',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        if (pending.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Column(
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    size: 48,
                    color: AppColors.success.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    '¡Sin actividades pendientes!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...pending.map(
            (a) => _PendingActivityItem(
              activity: a,
              onTap: () => widget.onActivityTap(a),
            ),
          ),
      ],
    );
  }

  String _formatFullDate(DateTime date) {
    final weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${weekDays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }
}

// ══════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppDimensions.xs),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textHint,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _UrgentActivityCard extends StatelessWidget {
  final OperActivity activity;
  final VoidCallback onTap;

  const _UrgentActivityCard({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      color: AppColors.errorLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: AppColors.error.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error,
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (activity.isOverdue)
                          Text(
                            'Vencida',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (activity.hasSla) ...[
                          const SizedBox(width: AppDimensions.sm),
                          SlaIndicator(activity: activity, compact: true),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingActivityItem extends StatelessWidget {
  final OperActivity activity;
  final VoidCallback onTap;

  const _PendingActivityItem({required this.activity, required this.onTap});

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

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: activity.isOverdue
              ? AppColors.error.withOpacity(0.5)
              : AppColors.divider,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.sm,
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
                            style: AppTextStyles.labelSmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Text(
                          '${activity.progress}%',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                        if (activity.hasSla) ...[
                          const SizedBox(width: AppDimensions.sm),
                          SlaBadge(activity: activity),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (activity.isOverdue)
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 20,
                )
              else
                Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
