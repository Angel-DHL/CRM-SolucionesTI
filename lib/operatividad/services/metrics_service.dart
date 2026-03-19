// lib/operatividad/services/metrics_service.dart

import 'package:intl/intl.dart';

import '../models/oper_activity.dart';

/// Datos de productividad de un colaborador
class CollaboratorMetrics {
  final String uid;
  final String email;
  final String name;

  // Actividades
  final int totalAssigned;
  final int completed;
  final int inProgress;
  final int overdue;
  final int blocked;

  // Tiempos
  final double totalEstimatedHours;
  final double totalActualHours;
  final double avgCompletionTimeHours;

  // Tasas
  final double completionRate;
  final double onTimeRate;
  final double efficiencyRate; // estimado/real

  // SLA
  final int slaCompliant;
  final int slaBreached;
  final double slaComplianceRate;

  // Tendencia (vs período anterior)
  final double completionRateTrend; // positivo = mejoró
  final double efficiencyTrend;

  const CollaboratorMetrics({
    required this.uid,
    required this.email,
    required this.name,
    required this.totalAssigned,
    required this.completed,
    required this.inProgress,
    required this.overdue,
    required this.blocked,
    required this.totalEstimatedHours,
    required this.totalActualHours,
    required this.avgCompletionTimeHours,
    required this.completionRate,
    required this.onTimeRate,
    required this.efficiencyRate,
    required this.slaCompliant,
    required this.slaBreached,
    required this.slaComplianceRate,
    required this.completionRateTrend,
    required this.efficiencyTrend,
  });

  String get completionRateText =>
      '${(completionRate * 100).toStringAsFixed(0)}%';
  String get onTimeRateText => '${(onTimeRate * 100).toStringAsFixed(0)}%';
  String get efficiencyRateText =>
      '${(efficiencyRate * 100).toStringAsFixed(0)}%';
  String get slaComplianceRateText =>
      '${(slaComplianceRate * 100).toStringAsFixed(0)}%';
}

/// Datos de un mes para comparativo
class MonthlyMetrics {
  final DateTime month;
  final int totalActivities;
  final int completedActivities;
  final int overdueActivities;
  final double completionRate;
  final double onTimeRate;
  final double avgProgress;
  final double totalHoursWorked;
  final int slaBreached;

  const MonthlyMetrics({
    required this.month,
    required this.totalActivities,
    required this.completedActivities,
    required this.overdueActivities,
    required this.completionRate,
    required this.onTimeRate,
    required this.avgProgress,
    required this.totalHoursWorked,
    required this.slaBreached,
  });

  String get monthLabel {
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
    return '${months[month.month - 1]} ${month.year}';
  }

  String get monthLabelShort {
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
    return months[month.month - 1];
  }
}

/// Predicción de carga de trabajo
class WorkloadPrediction {
  final String uid;
  final String name;
  final int currentActivities;
  final int upcomingActivities;
  final double estimatedHoursNextWeek;
  final double capacityPercentage; // > 100% = sobrecargado
  final WorkloadLevel level;

  const WorkloadPrediction({
    required this.uid,
    required this.name,
    required this.currentActivities,
    required this.upcomingActivities,
    required this.estimatedHoursNextWeek,
    required this.capacityPercentage,
    required this.level,
  });
}

enum WorkloadLevel { low, normal, high, overloaded }

/// Servicio centralizado de métricas
class MetricsService {
  MetricsService._();

  static const double _standardWeeklyHours = 40.0;

  // ══════════════════════════════════════════════════════════
  // MÉTRICAS POR COLABORADOR
  // ══════════════════════════════════════════════════════════

  static List<CollaboratorMetrics> calculateCollaboratorMetrics({
    required List<OperActivity> currentPeriod,
    required List<OperActivity> previousPeriod,
  }) {
    // Recopilar todos los UIDs únicos
    final allUids = <String, String>{};
    for (final a in currentPeriod) {
      for (int i = 0; i < a.assigneesUids.length; i++) {
        allUids[a.assigneesUids[i]] = i < a.assigneesEmails.length
            ? a.assigneesEmails[i]
            : a.assigneesUids[i];
      }
    }

    return allUids.entries.map((entry) {
      final uid = entry.key;
      final email = entry.value;

      return _calculateForUser(
        uid: uid,
        email: email,
        currentPeriod: currentPeriod,
        previousPeriod: previousPeriod,
      );
    }).toList()..sort((a, b) => b.completionRate.compareTo(a.completionRate));
  }

  static CollaboratorMetrics _calculateForUser({
    required String uid,
    required String email,
    required List<OperActivity> currentPeriod,
    required List<OperActivity> previousPeriod,
  }) {
    final name = email.split('@').first;

    // Actividades del período actual
    final myActivities = currentPeriod
        .where((a) => a.assigneesUids.contains(uid))
        .toList();

    final total = myActivities.length;
    final completed = myActivities
        .where(
          (a) => a.status == OperStatus.done || a.status == OperStatus.verified,
        )
        .toList();
    final inProgress = myActivities
        .where((a) => a.status == OperStatus.inProgress)
        .length;
    final overdue = myActivities.where((a) => a.isOverdue).length;
    final blocked = myActivities
        .where((a) => a.status == OperStatus.blocked)
        .length;

    // Tiempos
    double totalEstimated = 0;
    double totalActual = 0;
    double totalCompletionTime = 0;
    int completedWithTime = 0;

    for (final a in myActivities) {
      totalEstimated += a.estimatedHours;
      if (a.workDurationHours != null) {
        totalActual += a.workDurationHours!;
      }
    }

    for (final a in completed) {
      if (a.workStartAt != null) {
        final end = a.workEndAt ?? a.actualEndAt ?? a.updatedAt;
        final hours = end.difference(a.workStartAt!).inMinutes / 60;
        totalCompletionTime += hours;
        completedWithTime++;
      }
    }

    final avgCompletionTime = completedWithTime > 0
        ? totalCompletionTime / completedWithTime
        : 0.0;

    // Tasas
    final completionRate = total > 0 ? completed.length / total : 0.0;

    int onTimeCount = 0;
    for (final a in completed) {
      final completedDate = a.workEndAt ?? a.actualEndAt ?? a.updatedAt;
      if (!completedDate.isAfter(a.plannedEndAt)) {
        onTimeCount++;
      }
    }
    final onTimeRate = completed.isNotEmpty
        ? onTimeCount / completed.length
        : 0.0;

    final efficiencyRate = totalActual > 0
        ? (totalEstimated / totalActual).clamp(0.0, 2.0)
        : 0.0;

    // SLA
    int slaCompliant = 0;
    int slaBreached = 0;
    for (final a in myActivities) {
      if (!a.hasSla) continue;
      if (a.slaBreached) {
        slaBreached++;
      } else {
        slaCompliant++;
      }
    }
    final totalWithSla = slaCompliant + slaBreached;
    final slaComplianceRate = totalWithSla > 0
        ? slaCompliant / totalWithSla
        : 1.0;

    // Tendencia vs período anterior
    final prevActivities = previousPeriod
        .where((a) => a.assigneesUids.contains(uid))
        .toList();

    final prevCompleted = prevActivities
        .where(
          (a) => a.status == OperStatus.done || a.status == OperStatus.verified,
        )
        .length;

    final prevCompletionRate = prevActivities.isNotEmpty
        ? prevCompleted / prevActivities.length
        : 0.0;

    final completionRateTrend = completionRate - prevCompletionRate;

    double prevEfficiency = 0;
    double prevEstimated = 0;
    double prevActual = 0;
    for (final a in prevActivities) {
      prevEstimated += a.estimatedHours;
      if (a.workDurationHours != null) {
        prevActual += a.workDurationHours!;
      }
    }
    if (prevActual > 0) {
      prevEfficiency = prevEstimated / prevActual;
    }
    final efficiencyTrend = efficiencyRate - prevEfficiency;

    return CollaboratorMetrics(
      uid: uid,
      email: email,
      name: name,
      totalAssigned: total,
      completed: completed.length,
      inProgress: inProgress,
      overdue: overdue,
      blocked: blocked,
      totalEstimatedHours: totalEstimated,
      totalActualHours: totalActual,
      avgCompletionTimeHours: avgCompletionTime,
      completionRate: completionRate,
      onTimeRate: onTimeRate,
      efficiencyRate: efficiencyRate,
      slaCompliant: slaCompliant,
      slaBreached: slaBreached,
      slaComplianceRate: slaComplianceRate,
      completionRateTrend: completionRateTrend,
      efficiencyTrend: efficiencyTrend,
    );
  }

  // ══════════════════════════════════════════════════════════
  // COMPARATIVO MENSUAL
  // ══════════════════════════════════════════════════════════

  static List<MonthlyMetrics> calculateMonthlyMetrics({
    required List<OperActivity> activities,
    int months = 6,
  }) {
    final now = DateTime.now();
    final result = <MonthlyMetrics>[];

    for (int i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(
        monthDate.year,
        monthDate.month + 1,
        0,
        23,
        59,
        59,
      );

      final monthActivities = activities.where((a) {
        return a.plannedEndAt.isAfter(monthDate) &&
            a.plannedStartAt.isBefore(monthEnd);
      }).toList();

      final total = monthActivities.length;

      final completed = monthActivities
          .where(
            (a) =>
                a.status == OperStatus.done || a.status == OperStatus.verified,
          )
          .toList();

      final overdue = monthActivities.where((a) => a.isOverdue).length;

      final completionRate = total > 0 ? completed.length / total : 0.0;

      int onTimeCount = 0;
      for (final a in completed) {
        final completedDate = a.workEndAt ?? a.actualEndAt ?? a.updatedAt;
        if (!completedDate.isAfter(a.plannedEndAt)) onTimeCount++;
      }
      final onTimeRate = completed.isNotEmpty
          ? onTimeCount / completed.length
          : 0.0;

      final avgProgress = total > 0
          ? monthActivities.fold<int>(0, (sum, a) => sum + a.progress) / total
          : 0.0;

      double totalHours = 0;
      for (final a in monthActivities) {
        if (a.workDurationHours != null) totalHours += a.workDurationHours!;
      }

      final slaBreached = monthActivities.where((a) => a.slaBreached).length;

      result.add(
        MonthlyMetrics(
          month: monthDate,
          totalActivities: total,
          completedActivities: completed.length,
          overdueActivities: overdue,
          completionRate: completionRate,
          onTimeRate: onTimeRate,
          avgProgress: avgProgress,
          totalHoursWorked: totalHours,
          slaBreached: slaBreached,
        ),
      );
    }

    return result;
  }

  // ══════════════════════════════════════════════════════════
  // PREDICCIÓN DE CARGA
  // ══════════════════════════════════════════════════════════

  static List<WorkloadPrediction> predictWorkload({
    required List<OperActivity> activities,
  }) {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    final allUids = <String, String>{};
    for (final a in activities) {
      for (int i = 0; i < a.assigneesUids.length; i++) {
        allUids[a.assigneesUids[i]] = i < a.assigneesEmails.length
            ? a.assigneesEmails[i]
            : a.assigneesUids[i];
      }
    }

    return allUids.entries.map((entry) {
      final uid = entry.key;
      final email = entry.value;
      final name = email.split('@').first;

      final userActivities = activities
          .where((a) => a.assigneesUids.contains(uid))
          .toList();

      // Actividades activas actualmente
      final current = userActivities
          .where(
            (a) =>
                a.status == OperStatus.inProgress ||
                (a.status == OperStatus.planned &&
                    a.plannedStartAt.isBefore(now)),
          )
          .length;

      // Actividades que empiezan la próxima semana
      final upcoming = userActivities
          .where(
            (a) =>
                a.status == OperStatus.planned &&
                a.plannedStartAt.isAfter(now) &&
                a.plannedStartAt.isBefore(nextWeek),
          )
          .length;

      // Horas estimadas para la próxima semana
      double estimatedHours = 0;
      for (final a in userActivities) {
        if (a.status == OperStatus.done || a.status == OperStatus.verified) {
          continue;
        }
        if (a.plannedEndAt.isAfter(now) &&
            a.plannedStartAt.isBefore(nextWeek)) {
          // Proporción de la actividad que cae en la próxima semana
          final activityDays = a.plannedEndAt
              .difference(a.plannedStartAt)
              .inDays;
          if (activityDays > 0) {
            final overlapStart = a.plannedStartAt.isBefore(now)
                ? now
                : a.plannedStartAt;
            final overlapEnd = a.plannedEndAt.isAfter(nextWeek)
                ? nextWeek
                : a.plannedEndAt;
            final overlapDays = overlapEnd.difference(overlapStart).inDays;
            final proportion = overlapDays / activityDays;
            estimatedHours += a.estimatedHours * proportion;
          } else {
            estimatedHours += a.estimatedHours;
          }
        }
      }

      final capacityPercentage = (estimatedHours / _standardWeeklyHours) * 100;

      WorkloadLevel level;
      if (capacityPercentage > 120) {
        level = WorkloadLevel.overloaded;
      } else if (capacityPercentage > 80) {
        level = WorkloadLevel.high;
      } else if (capacityPercentage > 40) {
        level = WorkloadLevel.normal;
      } else {
        level = WorkloadLevel.low;
      }

      return WorkloadPrediction(
        uid: uid,
        name: name,
        currentActivities: current,
        upcomingActivities: upcoming,
        estimatedHoursNextWeek: estimatedHours,
        capacityPercentage: capacityPercentage,
        level: level,
      );
    }).toList()..sort(
      (a, b) => b.capacityPercentage.compareTo(a.capacityPercentage),
    );
  }
}
