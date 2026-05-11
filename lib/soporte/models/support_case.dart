// lib/soporte/models/support_case.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'support_enums.dart';

class SupportCase {
  final String id;
  final String folio;
  final String titulo;
  final String descripcion;
  final CaseStatus status;
  final CasePriority priority;
  final CaseCategory category;
  final CaseOrigin origin;
  final String? originId; // ID de actividad/proyecto de origen
  final String? clienteId;
  final String? clienteNombre;
  final String? assignedToUid;
  final String? assignedToEmail;
  final String? solucion;
  final List<String> tags;
  final String createdByUid;
  final String createdByEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;

  const SupportCase({
    required this.id,
    required this.folio,
    required this.titulo,
    required this.descripcion,
    required this.status,
    required this.priority,
    required this.category,
    required this.origin,
    this.originId,
    this.clienteId,
    this.clienteNombre,
    this.assignedToUid,
    this.assignedToEmail,
    this.solucion,
    this.tags = const [],
    required this.createdByUid,
    required this.createdByEmail,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.closedAt,
  });

  // ══════════════════════════════════════════════════════════
  // PARSEO DESDE FIRESTORE
  // ══════════════════════════════════════════════════════════

  static SupportCase fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;

    DateTime parseTs(dynamic t) {
      if (t is Timestamp) return t.toDate().toLocal();
      return DateTime.now();
    }

    DateTime? parseTsNull(dynamic t) {
      if (t is Timestamp) return t.toDate().toLocal();
      return null;
    }

    return SupportCase(
      id: doc.id,
      folio: (d['folio'] ?? '').toString(),
      titulo: (d['titulo'] ?? '').toString(),
      descripcion: (d['descripcion'] ?? '').toString(),
      status: CaseStatusX.from(d['status'] as String?),
      priority: CasePriorityX.from(d['priority'] as String?),
      category: CaseCategoryX.from(d['category'] as String?),
      origin: CaseOriginX.from(d['origin'] as String?),
      originId: d['originId'] as String?,
      clienteId: d['clienteId'] as String?,
      clienteNombre: d['clienteNombre'] as String?,
      assignedToUid: d['assignedToUid'] as String?,
      assignedToEmail: d['assignedToEmail'] as String?,
      solucion: d['solucion'] as String?,
      tags: List<String>.from(d['tags'] ?? const []),
      createdByUid: (d['createdByUid'] ?? '').toString(),
      createdByEmail: (d['createdByEmail'] ?? '').toString(),
      createdAt: parseTs(d['createdAt']),
      updatedAt: parseTs(d['updatedAt']),
      resolvedAt: parseTsNull(d['resolvedAt']),
      closedAt: parseTsNull(d['closedAt']),
    );
  }

  // ══════════════════════════════════════════════════════════
  // CREAR MAPA PARA FIRESTORE
  // ══════════════════════════════════════════════════════════

  Map<String, dynamic> toMap() => {
    'folio': folio,
    'titulo': titulo,
    'descripcion': descripcion,
    'status': status.value,
    'priority': priority.value,
    'category': category.value,
    'origin': origin.value,
    'originId': originId,
    'clienteId': clienteId,
    'clienteNombre': clienteNombre,
    'assignedToUid': assignedToUid,
    'assignedToEmail': assignedToEmail,
    'solucion': solucion,
    'tags': tags,
    'createdByUid': createdByUid,
    'createdByEmail': createdByEmail,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
  };

  Map<String, dynamic> toUpdateMap() => {
    'titulo': titulo,
    'descripcion': descripcion,
    'status': status.value,
    'priority': priority.value,
    'category': category.value,
    'assignedToUid': assignedToUid,
    'assignedToEmail': assignedToEmail,
    'solucion': solucion,
    'tags': tags,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // ══════════════════════════════════════════════════════════
  // PROPIEDADES CALCULADAS
  // ══════════════════════════════════════════════════════════

  bool get isOpen => status == CaseStatus.abierto || status == CaseStatus.enProgreso || status == CaseStatus.enEspera;
  bool get isResolved => status == CaseStatus.resuelto || status == CaseStatus.cerrado;

  Duration? get tiempoResolucion {
    if (resolvedAt == null) return null;
    return resolvedAt!.difference(createdAt);
  }

  String get tiempoResolucionText {
    final dur = tiempoResolucion;
    if (dur == null) return 'Pendiente';
    if (dur.inDays > 0) return '${dur.inDays}d ${dur.inHours % 24}h';
    if (dur.inHours > 0) return '${dur.inHours}h ${dur.inMinutes % 60}m';
    return '${dur.inMinutes}m';
  }

  String get assignedName => assignedToEmail?.split('@').first ?? 'Sin asignar';

  SupportCase copyWith({
    String? id,
    String? folio,
    String? titulo,
    String? descripcion,
    CaseStatus? status,
    CasePriority? priority,
    CaseCategory? category,
    CaseOrigin? origin,
    String? originId,
    String? clienteId,
    String? clienteNombre,
    String? assignedToUid,
    String? assignedToEmail,
    String? solucion,
    List<String>? tags,
    String? createdByUid,
    String? createdByEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
  }) {
    return SupportCase(
      id: id ?? this.id,
      folio: folio ?? this.folio,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      origin: origin ?? this.origin,
      originId: originId ?? this.originId,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      solucion: solucion ?? this.solucion,
      tags: tags ?? this.tags,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}
