// lib/crm/models/crm_activity_log.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'crm_enums.dart';

/// Registro de actividad en el historial de un contacto CRM.
class CrmActivityLog {
  final String id;
  final String contactId;
  final CrmActivityType type;
  final String titulo;
  final String? descripcion;

  /// Para cambios de estatus: el estatus anterior y nuevo
  final String? previousStatus;
  final String? newStatus;

  final DateTime createdAt;
  final String createdBy;
  final String? createdByEmail;

  CrmActivityLog({
    required this.id,
    required this.contactId,
    required this.type,
    required this.titulo,
    this.descripcion,
    this.previousStatus,
    this.newStatus,
    required this.createdAt,
    required this.createdBy,
    this.createdByEmail,
  });

  static CrmActivityLog fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    DateTime parseTs(dynamic t) {
      if (t == null) return DateTime.now();
      if (t is Timestamp) return t.toDate().toLocal();
      return DateTime.now();
    }

    return CrmActivityLog(
      id: doc.id,
      contactId: (d['contactId'] ?? '').toString(),
      type: CrmActivityTypeX.from(d['type'] as String?),
      titulo: (d['titulo'] ?? '').toString(),
      descripcion: d['descripcion'] as String?,
      previousStatus: d['previousStatus'] as String?,
      newStatus: d['newStatus'] as String?,
      createdAt: parseTs(d['createdAt']),
      createdBy: (d['createdBy'] ?? '').toString(),
      createdByEmail: d['createdByEmail'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contactId': contactId,
      'type': type.value,
      'titulo': titulo,
      'descripcion': descripcion,
      'previousStatus': previousStatus,
      'newStatus': newStatus,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'createdByEmail': createdByEmail,
    };
  }
}
