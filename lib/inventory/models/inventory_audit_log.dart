// lib/inventory/models/inventory_audit_log.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modelo para registros de auditoría del inventario
class InventoryAuditLog {
  // ═══════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ═══════════════════════════════════════════════════════════
  final String id;
  final String module; // 'items', 'categories', 'suppliers', 'locations', etc.

  // ═══════════════════════════════════════════════════════════
  // ACCIÓN
  // ═══════════════════════════════════════════════════════════
  final String action; // 'create', 'update', 'delete', 'move', etc.
  final String? entityId; // ID de la entidad afectada
  final String? entityName; // Nombre de la entidad (desnormalizado)

  // ═══════════════════════════════════════════════════════════
  // DETALLES
  // ═══════════════════════════════════════════════════════════
  final String? details; // Descripción de la acción
  final Map<String, dynamic>? previousData; // Datos antes del cambio
  final Map<String, dynamic>? newData; // Datos después del cambio

  // ═══════════════════════════════════════════════════════════
  // USUARIO
  // ═══════════════════════════════════════════════════════════
  final String? userId; // UID del usuario
  final String? userEmail; // Email del usuario
  final String? userName; // Nombre del usuario

  // ═══════════════════════════════════════════════════════════
  // METADATOS
  // ═══════════════════════════════════════════════════════════
  final DateTime timestamp; // Cuándo ocurrió
  final String? ipAddress; // Dirección IP
  final String? userAgent; // Navegador/dispositivo
  final Map<String, dynamic>? metadata; // Datos adicionales

  InventoryAuditLog({
    required this.id,
    required this.module,
    required this.action,
    this.entityId,
    this.entityName,
    this.details,
    this.previousData,
    this.newData,
    this.userId,
    this.userEmail,
    this.userName,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.metadata,
  });

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN DESDE FIRESTORE
  // ═══════════════════════════════════════════════════════════
  static InventoryAuditLog fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InventoryAuditLog(
      id: doc.id,
      module: data['module'] ?? '',
      action: data['action'] ?? '',
      entityId: data['entityId'],
      entityName: data['entityName'],
      details: data['details'],
      previousData: data['previousData'] != null
          ? Map<String, dynamic>.from(data['previousData'])
          : null,
      newData: data['newData'] != null
          ? Map<String, dynamic>.from(data['newData'])
          : null,
      userId: data['userId'],
      userEmail: data['userEmail'],
      userName: data['userName'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN A MAP PARA FIRESTORE
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic> toMap() {
    return {
      'module': module,
      'action': action,
      'entityId': entityId,
      'entityName': entityName,
      'details': details,
      'previousData': previousData,
      'newData': newData,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'timestamp': FieldValue.serverTimestamp(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'metadata': metadata,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTODOS ÚTILES
  // ═══════════════════════════════════════════════════════════

  /// Obtiene el nombre del usuario o "Sistema"
  String get userDisplayName {
    if (userName != null && userName!.isNotEmpty) return userName!;
    if (userEmail != null && userEmail!.isNotEmpty) return userEmail!;
    if (userId != null && userId!.isNotEmpty) return 'Usuario $userId';
    return 'Sistema';
  }

  /// Descripción legible de la acción
  String get actionDescription {
    final entity = entityName ?? 'elemento';
    return switch (action) {
      'create' => 'Creó $entity',
      'update' => 'Actualizó $entity',
      'delete' => 'Eliminó $entity',
      'soft_delete' => 'Desactivó $entity',
      'move' => 'Movió $entity',
      'reorder' => 'Reordenó $entity',
      'approve' => 'Aprobó $entity',
      'reject' => 'Rechazó $entity',
      _ => details ?? 'Acción en $entity',
    };
  }

  /// Ícono según el tipo de acción
  IconData get actionIcon {
    return switch (action) {
      'create' => Icons.add_circle_rounded,
      'update' => Icons.edit_rounded,
      'delete' => Icons.delete_rounded,
      'soft_delete' => Icons.archive_rounded,
      'move' => Icons.drive_file_move_rounded,
      'reorder' => Icons.reorder_rounded,
      'approve' => Icons.check_circle_rounded,
      'reject' => Icons.cancel_rounded,
      _ => Icons.history_rounded,
    };
  }

  /// Color según el tipo de acción
  Color get actionColor {
    return switch (action) {
      'create' => const Color(0xFF4CAF50), // Verde
      'update' => const Color(0xFF2196F3), // Azul
      'delete' || 'soft_delete' => const Color(0xFFF44336), // Rojo
      'move' || 'reorder' => const Color(0xFFFF9800), // Naranja
      'approve' => const Color(0xFF4CAF50), // Verde
      'reject' => const Color(0xFFF44336), // Rojo
      _ => const Color(0xFF9E9E9E), // Gris
    };
  }

  /// Tiene cambios de datos
  bool get hasDataChanges => previousData != null || newData != null;

  /// Obtener cambios específicos
  Map<String, dynamic> get changes {
    if (previousData == null || newData == null) return {};

    final changes = <String, dynamic>{};
    newData!.forEach((key, newValue) {
      final oldValue = previousData![key];
      if (oldValue != newValue) {
        changes[key] = {'old': oldValue, 'new': newValue};
      }
    });
    return changes;
  }
}
