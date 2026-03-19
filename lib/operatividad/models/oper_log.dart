// lib/operatividad/models/oper_log.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de acciones que se registran en la bitácora
enum LogAction {
  created,
  statusChanged,
  progressChanged,
  workStarted,
  workEnded,
  assigneesChanged,
  priorityChanged,
  evidenceUploaded,
  evidenceDeleted,
  commentAdded,
  slaBreached,
  edited,
}

extension LogActionX on LogAction {
  String get value => name;

  String get label => switch (this) {
    LogAction.created => 'Actividad creada',
    LogAction.statusChanged => 'Estado actualizado',
    LogAction.progressChanged => 'Progreso actualizado',
    LogAction.workStarted => 'Trabajo iniciado',
    LogAction.workEnded => 'Trabajo finalizado',
    LogAction.assigneesChanged => 'Responsables modificados',
    LogAction.priorityChanged => 'Prioridad cambiada',
    LogAction.evidenceUploaded => 'Evidencia subida',
    LogAction.evidenceDeleted => 'Evidencia eliminada',
    LogAction.commentAdded => 'Comentario agregado',
    LogAction.slaBreached => 'SLA incumplido',
    LogAction.edited => 'Actividad editada',
  };

  String get icon => switch (this) {
    LogAction.created => '🆕',
    LogAction.statusChanged => '🔄',
    LogAction.progressChanged => '📊',
    LogAction.workStarted => '▶️',
    LogAction.workEnded => '⏹️',
    LogAction.assigneesChanged => '👥',
    LogAction.priorityChanged => '🔺',
    LogAction.evidenceUploaded => '📎',
    LogAction.evidenceDeleted => '🗑️',
    LogAction.commentAdded => '💬',
    LogAction.slaBreached => '⚠️',
    LogAction.edited => '✏️',
  };

  static LogAction from(String? v) {
    return LogAction.values.firstWhere(
      (e) => e.value == v,
      orElse: () => LogAction.edited,
    );
  }
}

class OperLog {
  final String id;
  final LogAction action;
  final String description;
  final String performedByUid;
  final String performedByEmail;
  final Map<String, dynamic>? previousValue;
  final Map<String, dynamic>? newValue;
  final DateTime createdAt;

  const OperLog({
    required this.id,
    required this.action,
    required this.description,
    required this.performedByUid,
    required this.performedByEmail,
    this.previousValue,
    this.newValue,
    required this.createdAt,
  });

  static OperLog fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return OperLog(
      id: doc.id,
      action: LogActionX.from(d['action'] as String?),
      description: (d['description'] ?? '').toString(),
      performedByUid: (d['performedByUid'] ?? '').toString(),
      performedByEmail: (d['performedByEmail'] ?? '').toString(),
      previousValue: d['previousValue'] as Map<String, dynamic>?,
      newValue: d['newValue'] as Map<String, dynamic>?,
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> createMap({
    required LogAction action,
    required String description,
    required String performedByUid,
    required String performedByEmail,
    Map<String, dynamic>? previousValue,
    Map<String, dynamic>? newValue,
  }) {
    return {
      'action': action.value,
      'description': description,
      'performedByUid': performedByUid,
      'performedByEmail': performedByEmail,
      'previousValue': previousValue,
      'newValue': newValue,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String get performedByName => performedByEmail.split('@').first;

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';

    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }
}
