// lib/proyectos/models/project_audit_log.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Registro de auditoría del módulo de proyectos.
/// Colección: `project_audit_logs`
class ProjectAuditLog {
  final String id;
  final String module; // 'projects', 'tasks', 'transactions'
  final String action; // 'create', 'update', 'delete', 'status_change', 'payment', etc.
  final String? projectId;
  final String? projectName;
  final String? entityId;
  final String? entityName;
  final String? details;
  final Map<String, dynamic>? previousData;
  final Map<String, dynamic>? newData;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ProjectAuditLog({
    required this.id,
    required this.module,
    required this.action,
    this.projectId,
    this.projectName,
    this.entityId,
    this.entityName,
    this.details,
    this.previousData,
    this.newData,
    this.userId,
    this.userEmail,
    this.userName,
    required this.timestamp,
    this.metadata,
  });

  static ProjectAuditLog fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProjectAuditLog(
      id: doc.id,
      module: d['module'] ?? '',
      action: d['action'] ?? '',
      projectId: d['projectId'],
      projectName: d['projectName'],
      entityId: d['entityId'],
      entityName: d['entityName'],
      details: d['details'],
      previousData: d['previousData'] != null ? Map<String, dynamic>.from(d['previousData']) : null,
      newData: d['newData'] != null ? Map<String, dynamic>.from(d['newData']) : null,
      userId: d['userId'],
      userEmail: d['userEmail'],
      userName: d['userName'],
      timestamp: d['timestamp'] is Timestamp
          ? (d['timestamp'] as Timestamp).toDate().toLocal()
          : DateTime.now(),
      metadata: d['metadata'] != null ? Map<String, dynamic>.from(d['metadata']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'module': module, 'action': action,
    'projectId': projectId, 'projectName': projectName,
    'entityId': entityId, 'entityName': entityName,
    'details': details, 'previousData': previousData, 'newData': newData,
    'userId': userId, 'userEmail': userEmail, 'userName': userName,
    'timestamp': FieldValue.serverTimestamp(), 'metadata': metadata,
  };

  String get userDisplayName {
    if (userName != null && userName!.isNotEmpty) return userName!;
    if (userEmail != null && userEmail!.isNotEmpty) return userEmail!;
    return 'Sistema';
  }

  String get actionDescription {
    final entity = entityName ?? projectName ?? 'elemento';
    return switch (action) {
      'create' => 'Creó $entity',
      'update' => 'Actualizó $entity',
      'delete' => 'Eliminó $entity',
      'status_change' => 'Cambió estado de $entity',
      'payment' => 'Registró pago en $entity',
      'expense' => 'Registró gasto en $entity',
      'advance' => 'Registró adelanto en $entity',
      'task_create' => 'Creó tarea en $entity',
      'task_complete' => 'Completó tarea en $entity',
      'team_add' => 'Agregó miembro a $entity',
      'team_remove' => 'Removió miembro de $entity',
      'material_add' => 'Agregó material a $entity',
      _ => details ?? 'Acción en $entity',
    };
  }

  IconData get actionIcon => switch (action) {
    'create' => Icons.add_circle_rounded,
    'update' => Icons.edit_rounded,
    'delete' => Icons.delete_rounded,
    'status_change' => Icons.swap_horiz_rounded,
    'payment' || 'advance' => Icons.payments_rounded,
    'expense' => Icons.receipt_long_rounded,
    'task_create' => Icons.add_task_rounded,
    'task_complete' => Icons.task_alt_rounded,
    'team_add' => Icons.person_add_rounded,
    'team_remove' => Icons.person_remove_rounded,
    'material_add' => Icons.inventory_2_rounded,
    _ => Icons.history_rounded,
  };

  Color get actionColor => switch (action) {
    'create' || 'task_create' || 'team_add' => const Color(0xFF4CAF50),
    'update' => const Color(0xFF2196F3),
    'delete' || 'team_remove' => const Color(0xFFF44336),
    'status_change' => const Color(0xFFFF9800),
    'payment' || 'advance' => const Color(0xFF66BB6A),
    'expense' => const Color(0xFFEF5350),
    'task_complete' => const Color(0xFF4CAF50),
    'material_add' => const Color(0xFF7E57C2),
    _ => const Color(0xFF9E9E9E),
  };

  bool get hasDataChanges => previousData != null || newData != null;
}
