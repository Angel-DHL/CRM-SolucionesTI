// lib/operatividad/models/oper_activity.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum OperStatus { planned, inProgress, done, verified, blocked }

extension OperStatusX on OperStatus {
  String get value => switch (this) {
    OperStatus.planned => 'planned',
    OperStatus.inProgress => 'in_progress',
    OperStatus.done => 'done',
    OperStatus.verified => 'verified',
    OperStatus.blocked => 'blocked',
  };

  String get label => switch (this) {
    OperStatus.planned => 'Planeada',
    OperStatus.inProgress => 'En progreso',
    OperStatus.done => 'Realizada',
    OperStatus.verified => 'Verificada',
    OperStatus.blocked => 'Bloqueada',
  };

  static OperStatus from(String? v) => switch (v) {
    'planned' => OperStatus.planned,
    'in_progress' => OperStatus.inProgress,
    'done' => OperStatus.done,
    'verified' => OperStatus.verified,
    'blocked' => OperStatus.blocked,
    _ => OperStatus.planned,
  };
}

/// Niveles de SLA
enum SlaLevel { ok, warning, critical, breached }

class OperActivity {
  final String id;
  final String title;
  final String description;
  final DateTime plannedStartAt;
  final DateTime plannedEndAt;

  final List<String> assigneesUids;
  final List<String> assigneesEmails;

  final OperStatus status;
  final int progress;

  final DateTime? actualStartAt;
  final DateTime? actualEndAt;

  final DateTime? workStartAt;
  final DateTime? workEndAt;

  final String? priority;
  final List<String> tags;
  final double estimatedHours;
  final double actualHours;
  final List<String> dependencies;

  // ✅ NUEVOS CAMPOS SLA
  final double slaHours; // Horas límite de SLA (0 = sin SLA)
  final DateTime? slaDeadline; // Fecha/hora límite del SLA
  final bool slaBreached; // Si ya se rompió el SLA
  final DateTime? slaBreachedAt; // Cuándo se rompió

  final String createdByUid;
  final String createdByEmail;

  final DateTime createdAt;
  final DateTime updatedAt;

  const OperActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.plannedStartAt,
    required this.plannedEndAt,
    required this.assigneesUids,
    required this.assigneesEmails,
    required this.status,
    required this.progress,
    required this.actualStartAt,
    required this.actualEndAt,
    required this.workStartAt,
    required this.workEndAt,
    this.priority,
    this.tags = const [],
    this.estimatedHours = 0,
    this.actualHours = 0,
    this.dependencies = const [],
    this.slaHours = 0,
    this.slaDeadline,
    this.slaBreached = false,
    this.slaBreachedAt,
    required this.createdByUid,
    required this.createdByEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  // ══════════════════════════════════════════════════════════
  // PARSEO DESDE FIRESTORE
  // ══════════════════════════════════════════════════════════

  static OperActivity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;

    DateTime parseTimestamp(dynamic t) {
      if (t == null) return DateTime.now();
      if (t is Timestamp) return t.toDate().toLocal();
      return DateTime.now();
    }

    DateTime? parseTimestampNullable(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) return t.toDate().toLocal();
      return null;
    }

    return OperActivity(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      plannedStartAt: parseTimestamp(d['plannedStartAt']),
      plannedEndAt: parseTimestamp(d['plannedEndAt']),
      assigneesUids: List<String>.from(d['assigneesUids'] ?? const []),
      assigneesEmails: List<String>.from(d['assigneesEmails'] ?? const []),
      status: OperStatusX.from(d['status'] as String?),
      progress: (d['progress'] ?? 0) as int,
      actualStartAt: parseTimestampNullable(d['actualStartAt']),
      actualEndAt: parseTimestampNullable(d['actualEndAt']),
      workStartAt: parseTimestampNullable(d['workStartAt']),
      workEndAt: parseTimestampNullable(d['workEndAt']),
      priority: d['priority'] as String?,
      tags: List<String>.from(d['tags'] ?? const []),
      estimatedHours: (d['estimatedHours'] ?? 0).toDouble(),
      actualHours: (d['actualHours'] ?? 0).toDouble(),
      dependencies: List<String>.from(d['dependencies'] ?? const []),
      slaHours: (d['slaHours'] ?? 0).toDouble(),
      slaDeadline: parseTimestampNullable(d['slaDeadline']),
      slaBreached: d['slaBreached'] == true,
      slaBreachedAt: parseTimestampNullable(d['slaBreachedAt']),
      createdByUid: (d['createdByUid'] ?? '').toString(),
      createdByEmail: (d['createdByEmail'] ?? '').toString(),
      createdAt: parseTimestamp(d['createdAt']),
      updatedAt: parseTimestamp(d['updatedAt']),
    );
  }

  // ══════════════════════════════════════════════════════════
  // CREAR NUEVA ACTIVIDAD
  // ══════════════════════════════════════════════════════════

  static Map<String, dynamic> createMap({
    required String title,
    required String description,
    required DateTime plannedStartAt,
    required DateTime plannedEndAt,
    required List<String> assigneesUids,
    required List<String> assigneesEmails,
    required String createdByUid,
    required String createdByEmail,
    String? priority,
    List<String> tags = const [],
    double estimatedHours = 0,
    List<String> dependencies = const [],
    double slaHours = 0,
  }) {
    // Calcular deadline del SLA
    DateTime? slaDeadline;
    if (slaHours > 0) {
      slaDeadline = plannedStartAt.add(
        Duration(minutes: (slaHours * 60).round()),
      );
    }

    return {
      'title': title,
      'description': description,
      'plannedStartAt': Timestamp.fromDate(plannedStartAt),
      'plannedEndAt': Timestamp.fromDate(plannedEndAt),
      'assigneesUids': assigneesUids,
      'assigneesEmails': assigneesEmails,
      'status': OperStatus.planned.value,
      'progress': 0,
      'actualStartAt': null,
      'actualEndAt': null,
      'workStartAt': null,
      'workEndAt': null,
      'priority': priority ?? 'medium',
      'tags': tags,
      'estimatedHours': estimatedHours,
      'actualHours': 0,
      'dependencies': dependencies,
      'slaHours': slaHours,
      'slaDeadline': slaDeadline != null
          ? Timestamp.fromDate(slaDeadline)
          : null,
      'slaBreached': false,
      'slaBreachedAt': null,
      'createdByUid': createdByUid,
      'createdByEmail': createdByEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ══════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS
  // ══════════════════════════════════════════════════════════

  /// Verifica si la actividad está vencida
  bool get isOverdue {
    final now = DateTime.now();
    final isDatePassed = plannedEndAt.isBefore(now);
    final isNotCompleted =
        status != OperStatus.done && status != OperStatus.verified;
    return isDatePassed && isNotCompleted;
  }

  /// Si tiene SLA configurado
  bool get hasSla => slaHours > 0 && slaDeadline != null;

  /// Nivel actual de SLA
  SlaLevel get slaLevel {
    if (!hasSla) return SlaLevel.ok;

    final isCompleted =
        status == OperStatus.done || status == OperStatus.verified;

    // Si ya se completó
    if (isCompleted) {
      if (slaBreached) return SlaLevel.breached;
      return SlaLevel.ok;
    }

    // Si está activa, verificar tiempo restante
    final now = DateTime.now();
    final deadline = slaDeadline!;

    if (now.isAfter(deadline)) return SlaLevel.breached;

    final remaining = deadline.difference(now);
    final totalDuration = Duration(minutes: (slaHours * 60).round());
    final percentRemaining = remaining.inMinutes / totalDuration.inMinutes;

    if (percentRemaining <= 0.1) return SlaLevel.critical; // < 10%
    if (percentRemaining <= 0.25) return SlaLevel.warning; // < 25%

    return SlaLevel.ok;
  }

  /// Tiempo restante del SLA
  Duration? get slaTimeRemaining {
    if (!hasSla) return null;

    final isCompleted =
        status == OperStatus.done || status == OperStatus.verified;
    if (isCompleted) return Duration.zero;

    final now = DateTime.now();
    final remaining = slaDeadline!.difference(now);
    return remaining;
  }

  /// Texto formateado del tiempo restante del SLA
  String get slaTimeRemainingText {
    final remaining = slaTimeRemaining;
    if (remaining == null) return '';

    if (remaining.isNegative) {
      final overdue = remaining.abs();
      if (overdue.inDays > 0)
        return 'Excedido ${overdue.inDays}d ${overdue.inHours % 24}h';
      if (overdue.inHours > 0)
        return 'Excedido ${overdue.inHours}h ${overdue.inMinutes % 60}m';
      return 'Excedido ${overdue.inMinutes}m';
    }

    if (remaining.inDays > 0)
      return '${remaining.inDays}d ${remaining.inHours % 24}h restantes';
    if (remaining.inHours > 0)
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m restantes';
    return '${remaining.inMinutes}m restantes';
  }

  /// Porcentaje de SLA consumido (0.0 a 1.0+)
  double get slaConsumedPercentage {
    if (!hasSla) return 0;

    final isCompleted =
        status == OperStatus.done || status == OperStatus.verified;

    if (isCompleted && !slaBreached) return 0;

    final totalMinutes = slaHours * 60;
    final now = DateTime.now();
    final elapsed = now.difference(plannedStartAt).inMinutes;

    return (elapsed / totalMinutes).clamp(0.0, 2.0);
  }

  /// Duración planificada en horas
  double get plannedDurationHours {
    return plannedEndAt.difference(plannedStartAt).inMinutes / 60;
  }

  /// Duración real del trabajo (si existe)
  double? get workDurationHours {
    if (workStartAt == null) return null;
    final end = workEndAt ?? DateTime.now();
    return end.difference(workStartAt!).inMinutes / 60;
  }

  /// CopyWith
  OperActivity copyWith({
    String? title,
    String? description,
    DateTime? plannedStartAt,
    DateTime? plannedEndAt,
    List<String>? assigneesUids,
    List<String>? assigneesEmails,
    OperStatus? status,
    int? progress,
    DateTime? actualStartAt,
    DateTime? actualEndAt,
    DateTime? workStartAt,
    DateTime? workEndAt,
    String? priority,
    List<String>? tags,
    double? estimatedHours,
    double? actualHours,
    List<String>? dependencies,
    double? slaHours,
    DateTime? slaDeadline,
    bool? slaBreached,
    DateTime? slaBreachedAt,
  }) {
    return OperActivity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      plannedStartAt: plannedStartAt ?? this.plannedStartAt,
      plannedEndAt: plannedEndAt ?? this.plannedEndAt,
      assigneesUids: assigneesUids ?? this.assigneesUids,
      assigneesEmails: assigneesEmails ?? this.assigneesEmails,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      actualStartAt: actualStartAt ?? this.actualStartAt,
      actualEndAt: actualEndAt ?? this.actualEndAt,
      workStartAt: workStartAt ?? this.workStartAt,
      workEndAt: workEndAt ?? this.workEndAt,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      dependencies: dependencies ?? this.dependencies,
      slaHours: slaHours ?? this.slaHours,
      slaDeadline: slaDeadline ?? this.slaDeadline,
      slaBreached: slaBreached ?? this.slaBreached,
      slaBreachedAt: slaBreachedAt ?? this.slaBreachedAt,
      createdByUid: createdByUid,
      createdByEmail: createdByEmail,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
