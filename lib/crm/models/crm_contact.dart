// lib/crm/models/crm_contact.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'crm_enums.dart';

class CrmContact {
  // ═══════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ═══════════════════════════════════════════════════════════
  final String id;
  final ContactStatus status;
  final ContactSource source;

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN PERSONAL
  // ═══════════════════════════════════════════════════════════
  final String nombre;
  final String apellidos;
  final String email;
  final String telefono;

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN EMPRESARIAL
  // ═══════════════════════════════════════════════════════════
  final String? empresa;
  final String? cargo;
  final String? sitioWeb;

  // ═══════════════════════════════════════════════════════════
  // DATOS DEL LEAD ORIGINAL
  // ═══════════════════════════════════════════════════════════
  final String? leadId;        // Referencia al doc original en 'leads'
  final String? mensaje;       // Mensaje original del formulario web
  final String? fuente;        // fuente original del lead

  // ═══════════════════════════════════════════════════════════
  // GESTIÓN
  // ═══════════════════════════════════════════════════════════
  final String? interes;       // Servicio o producto de interés
  final List<String> tags;
  final String? notas;         // Notas generales rápidas

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA
  // ═══════════════════════════════════════════════════════════
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? lastModifiedBy;

  CrmContact({
    required this.id,
    required this.status,
    required this.source,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.telefono,
    this.empresa,
    this.cargo,
    this.sitioWeb,
    this.leadId,
    this.mensaje,
    this.fuente,
    this.interes,
    this.tags = const [],
    this.notas,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastModifiedBy,
  });

  // ═══════════════════════════════════════════════════════════
  // DESDE FIRESTORE - crm_contacts
  // ═══════════════════════════════════════════════════════════

  static CrmContact fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    DateTime parseTs(dynamic t) {
      if (t == null) return DateTime.now();
      if (t is Timestamp) return t.toDate().toLocal();
      return DateTime.now();
    }

    return CrmContact(
      id: doc.id,
      status: ContactStatusX.from(d['status'] as String?),
      source: ContactSourceX.from(d['source'] as String?),
      nombre: (d['nombre'] ?? '').toString(),
      apellidos: (d['apellidos'] ?? '').toString(),
      email: (d['email'] ?? '').toString(),
      telefono: (d['telefono'] ?? '').toString(),
      empresa: d['empresa'] as String?,
      cargo: d['cargo'] as String?,
      sitioWeb: d['sitioWeb'] as String?,
      leadId: d['leadId'] as String?,
      mensaje: d['mensaje'] as String?,
      fuente: d['fuente'] as String?,
      interes: d['interes'] as String?,
      tags: List<String>.from(d['tags'] ?? const []),
      notas: d['notas'] as String?,
      createdAt: parseTs(d['createdAt']),
      updatedAt: parseTs(d['updatedAt']),
      createdBy: (d['createdBy'] ?? '').toString(),
      lastModifiedBy: d['lastModifiedBy'] as String?,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DESDE LEAD DEL SITIO WEB - colección 'leads'
  // ═══════════════════════════════════════════════════════════

  static CrmContact fromLeadDoc(DocumentSnapshot doc, String createdByUid) {
    final d = doc.data() as Map<String, dynamic>;

    DateTime parseTs(dynamic t) {
      if (t == null) return DateTime.now();
      if (t is Timestamp) return t.toDate().toLocal();
      return DateTime.now();
    }

    return CrmContact(
      id: '',  // Se asignará al crear en crm_contacts
      status: ContactStatus.lead,
      source: ContactSourceX.from(d['fuente'] as String?),
      nombre: (d['nombre'] ?? '').toString(),
      apellidos: (d['apellidos'] ?? '').toString(),
      email: (d['email'] ?? '').toString(),
      telefono: (d['telefono'] ?? '').toString(),
      empresa: d['empresa'] as String?,
      cargo: d['cargo'] as String?,
      leadId: doc.id,
      mensaje: (d['mensaje'] ?? '').toString(),
      fuente: (d['fuente'] ?? '').toString(),
      createdAt: parseTs(d['createdAt']),
      updatedAt: DateTime.now(),
      createdBy: createdByUid,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // A MAP PARA FIRESTORE
  // ═══════════════════════════════════════════════════════════

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'source': source.value,
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
      'telefono': telefono,
      'empresa': empresa,
      'cargo': cargo,
      'sitioWeb': sitioWeb,
      'leadId': leadId,
      'mensaje': mensaje,
      'fuente': fuente,
      'interes': interes,
      'tags': tags,
      'notas': notas,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  /// Map para actualización (no sobreescribe createdAt)
  Map<String, dynamic> toUpdateMap() {
    return {
      'status': status.value,
      'source': source.value,
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
      'telefono': telefono,
      'empresa': empresa,
      'cargo': cargo,
      'sitioWeb': sitioWeb,
      'interes': interes,
      'tags': tags,
      'notas': notas,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': lastModifiedBy,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // PROPIEDADES ÚTILES
  // ═══════════════════════════════════════════════════════════

  String get nombreCompleto => '$nombre $apellidos'.trim();

  String get iniciales {
    final parts = nombreCompleto.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  bool get isFromWeb => leadId != null && leadId!.isNotEmpty;
  bool get isActive => status != ContactStatus.inactivo;
  bool get isClient => status == ContactStatus.cliente;

  // ═══════════════════════════════════════════════════════════
  // COPYWITH
  // ═══════════════════════════════════════════════════════════

  CrmContact copyWith({
    String? id,
    ContactStatus? status,
    ContactSource? source,
    String? nombre,
    String? apellidos,
    String? email,
    String? telefono,
    String? empresa,
    String? cargo,
    String? sitioWeb,
    String? leadId,
    String? mensaje,
    String? fuente,
    String? interes,
    List<String>? tags,
    String? notas,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
  }) {
    return CrmContact(
      id: id ?? this.id,
      status: status ?? this.status,
      source: source ?? this.source,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      empresa: empresa ?? this.empresa,
      cargo: cargo ?? this.cargo,
      sitioWeb: sitioWeb ?? this.sitioWeb,
      leadId: leadId ?? this.leadId,
      mensaje: mensaje ?? this.mensaje,
      fuente: fuente ?? this.fuente,
      interes: interes ?? this.interes,
      tags: tags ?? this.tags,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}
