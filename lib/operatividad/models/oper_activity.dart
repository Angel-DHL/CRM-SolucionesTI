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

class OperActivity {
  final String id;
  final String title;
  final String description;
  final DateTime plannedStartAt;
  final DateTime plannedEndAt;

  final List<String> assigneesUids;
  final List<String> assigneesEmails;

  final OperStatus status;
  final int progress; // 0..100

  final DateTime? actualStartAt;
  final DateTime? actualEndAt;

  // Registro de trabajo (inicio/fin de ejecución por el usuario)
  final DateTime? workStartAt;
  final DateTime? workEndAt;

  // Nuevos campos
  final String? priority; // 'low', 'medium', 'high'
  final List<String> tags;
  final double estimatedHours;
  final double actualHours;
  final List<String> dependencies; // IDs de actividades dependientes

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
    required this.createdByUid,
    required this.createdByEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crea una instancia desde un documento de Firestore
  static OperActivity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;

    // ✅ Función mejorada para parsear timestamps
    DateTime parseTimestamp(dynamic t) {
      if (t == null) return DateTime.now();
      if (t is Timestamp) {
        // Convertir a DateTime local
        return t.toDate().toLocal();
      }
      return DateTime.now();
    }

    DateTime? parseTimestampNullable(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) {
        return t.toDate().toLocal();
      }
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
      createdByUid: (d['createdByUid'] ?? '').toString(),
      createdByEmail: (d['createdByEmail'] ?? '').toString(),
      createdAt: parseTimestamp(d['createdAt']),
      updatedAt: parseTimestamp(d['updatedAt']),
    );
  }

  /// Genera el mapa de datos para crear una nueva actividad
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
  }) {
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
      'createdByUid': createdByUid,
      'createdByEmail': createdByEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Crea una copia con campos modificados
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
      createdByUid: createdByUid,
      createdByEmail: createdByEmail,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Verifica si la actividad está vencida
  bool get isOverdue {
    // Solo está vencida si:
    // 1. La fecha de fin planificada ya pasó
    // 2. El estado NO es 'done' ni 'verified'
    final now = DateTime.now();
    final endDate = DateTime(
      plannedEndAt.year,
      plannedEndAt.month,
      plannedEndAt.day,
      plannedEndAt.hour,
      plannedEndAt.minute,
    );

    final isDatePassed = endDate.isBefore(now);
    final isNotCompleted =
        status != OperStatus.done && status != OperStatus.verified;

    // Debug (puedes quitar después)
    // debugPrint('📅 Actividad: $title');
    // debugPrint('   Fin planificado: $endDate');
    // debugPrint('   Ahora: $now');
    // debugPrint('   ¿Fecha pasó?: $isDatePassed');
    // debugPrint('   ¿No completada?: $isNotCompleted');
    // debugPrint('   ¿Vencida?: ${isDatePassed && isNotCompleted}');

    return isDatePassed && isNotCompleted;
  }

  /// Calcula la duración planificada en horas
  double get plannedDurationHours {
    return plannedEndAt.difference(plannedStartAt).inMinutes / 60;
  }

  /// Calcula la duración real del trabajo (si existe)
  double? get workDurationHours {
    if (workStartAt == null) return null;
    final end = workEndAt ?? DateTime.now();
    return end.difference(workStartAt!).inMinutes / 60;
  }
}
