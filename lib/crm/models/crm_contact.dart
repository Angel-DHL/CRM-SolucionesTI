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
  final String? industria;
  final CompanySize? tamanoEmpresa;

  // ═══════════════════════════════════════════════════════════
  // DATOS FISCALES (MÉXICO)
  // ═══════════════════════════════════════════════════════════
  final String? rfc;
  final String? razonSocial;
  final String? regimenFiscal;
  final String? usoCfdi;

  // ═══════════════════════════════════════════════════════════
  // DIRECCIÓN FISCAL
  // ═══════════════════════════════════════════════════════════
  final String? direccion;
  final String? colonia;
  final String? ciudad;
  final String? estado;
  final String? codigoPostal;
  final String? pais;

  // ═══════════════════════════════════════════════════════════
  // DATOS DEL LEAD ORIGINAL
  // ═══════════════════════════════════════════════════════════
  final String? leadId;        // Referencia al doc original en 'leads'
  final String? mensaje;       // Mensaje original del formulario web
  final String? fuente;        // fuente original del lead

  // ═══════════════════════════════════════════════════════════
  // GESTIÓN COMERCIAL
  // ═══════════════════════════════════════════════════════════
  final String? interes;       // Servicio o producto de interés
  final List<String> tags;
  final String? notas;         // Notas generales rápidas
  final ContactPriority? prioridad;
  final double? valorEstimado; // Valor estimado del deal
  final String? asignadoA;     // UID del usuario asignado
  final DateTime? fechaUltimoContacto;
  final DateTime? fechaProximoSeguimiento;

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
    this.industria,
    this.tamanoEmpresa,
    this.rfc,
    this.razonSocial,
    this.regimenFiscal,
    this.usoCfdi,
    this.direccion,
    this.colonia,
    this.ciudad,
    this.estado,
    this.codigoPostal,
    this.pais,
    this.leadId,
    this.mensaje,
    this.fuente,
    this.interes,
    this.tags = const [],
    this.notas,
    this.prioridad,
    this.valorEstimado,
    this.asignadoA,
    this.fechaUltimoContacto,
    this.fechaProximoSeguimiento,
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

    DateTime? parseTsNullable(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) return t.toDate().toLocal();
      return null;
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
      industria: d['industria'] as String?,
      tamanoEmpresa: d['tamanoEmpresa'] != null
          ? CompanySizeX.from(d['tamanoEmpresa'] as String?)
          : null,
      rfc: d['rfc'] as String?,
      razonSocial: d['razonSocial'] as String?,
      regimenFiscal: d['regimenFiscal'] as String?,
      usoCfdi: d['usoCfdi'] as String?,
      direccion: d['direccion'] as String?,
      colonia: d['colonia'] as String?,
      ciudad: d['ciudad'] as String?,
      estado: d['estado'] as String?,
      codigoPostal: d['codigoPostal'] as String?,
      pais: d['pais'] as String?,
      leadId: d['leadId'] as String?,
      mensaje: d['mensaje'] as String?,
      fuente: d['fuente'] as String?,
      interes: d['interes'] as String?,
      tags: List<String>.from(d['tags'] ?? const []),
      notas: d['notas'] as String?,
      prioridad: d['prioridad'] != null
          ? ContactPriorityX.from(d['prioridad'] as String?)
          : null,
      valorEstimado: (d['valorEstimado'] as num?)?.toDouble(),
      asignadoA: d['asignadoA'] as String?,
      fechaUltimoContacto: parseTsNullable(d['fechaUltimoContacto']),
      fechaProximoSeguimiento: parseTsNullable(d['fechaProximoSeguimiento']),
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
      'industria': industria,
      'tamanoEmpresa': tamanoEmpresa?.value,
      'rfc': rfc,
      'razonSocial': razonSocial,
      'regimenFiscal': regimenFiscal,
      'usoCfdi': usoCfdi,
      'direccion': direccion,
      'colonia': colonia,
      'ciudad': ciudad,
      'estado': estado,
      'codigoPostal': codigoPostal,
      'pais': pais,
      'leadId': leadId,
      'mensaje': mensaje,
      'fuente': fuente,
      'interes': interes,
      'tags': tags,
      'notas': notas,
      'prioridad': prioridad?.value,
      'valorEstimado': valorEstimado,
      'asignadoA': asignadoA,
      'fechaUltimoContacto': fechaUltimoContacto != null
          ? Timestamp.fromDate(fechaUltimoContacto!)
          : null,
      'fechaProximoSeguimiento': fechaProximoSeguimiento != null
          ? Timestamp.fromDate(fechaProximoSeguimiento!)
          : null,
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
      'industria': industria,
      'tamanoEmpresa': tamanoEmpresa?.value,
      'rfc': rfc,
      'razonSocial': razonSocial,
      'regimenFiscal': regimenFiscal,
      'usoCfdi': usoCfdi,
      'direccion': direccion,
      'colonia': colonia,
      'ciudad': ciudad,
      'estado': estado,
      'codigoPostal': codigoPostal,
      'pais': pais,
      'interes': interes,
      'tags': tags,
      'notas': notas,
      'prioridad': prioridad?.value,
      'valorEstimado': valorEstimado,
      'asignadoA': asignadoA,
      'fechaUltimoContacto': fechaUltimoContacto != null
          ? Timestamp.fromDate(fechaUltimoContacto!)
          : null,
      'fechaProximoSeguimiento': fechaProximoSeguimiento != null
          ? Timestamp.fromDate(fechaProximoSeguimiento!)
          : null,
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

  /// Dirección completa formateada
  String? get direccionCompleta {
    final parts = <String>[];
    if (direccion != null && direccion!.isNotEmpty) parts.add(direccion!);
    if (colonia != null && colonia!.isNotEmpty) parts.add('Col. ${colonia!}');
    if (ciudad != null && ciudad!.isNotEmpty) parts.add(ciudad!);
    if (estado != null && estado!.isNotEmpty) parts.add(estado!);
    if (codigoPostal != null && codigoPostal!.isNotEmpty) parts.add('C.P. ${codigoPostal!}');
    if (pais != null && pais!.isNotEmpty && pais != 'México') parts.add(pais!);
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  /// ¿Tiene datos fiscales?
  bool get hasDatosFiscales =>
      (rfc != null && rfc!.isNotEmpty) ||
      (razonSocial != null && razonSocial!.isNotEmpty);

  /// ¿Tiene dirección?
  bool get hasDireccion =>
      (direccion != null && direccion!.isNotEmpty) ||
      (ciudad != null && ciudad!.isNotEmpty);

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
    String? industria,
    CompanySize? tamanoEmpresa,
    String? rfc,
    String? razonSocial,
    String? regimenFiscal,
    String? usoCfdi,
    String? direccion,
    String? colonia,
    String? ciudad,
    String? estado,
    String? codigoPostal,
    String? pais,
    String? leadId,
    String? mensaje,
    String? fuente,
    String? interes,
    List<String>? tags,
    String? notas,
    ContactPriority? prioridad,
    double? valorEstimado,
    String? asignadoA,
    DateTime? fechaUltimoContacto,
    DateTime? fechaProximoSeguimiento,
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
      industria: industria ?? this.industria,
      tamanoEmpresa: tamanoEmpresa ?? this.tamanoEmpresa,
      rfc: rfc ?? this.rfc,
      razonSocial: razonSocial ?? this.razonSocial,
      regimenFiscal: regimenFiscal ?? this.regimenFiscal,
      usoCfdi: usoCfdi ?? this.usoCfdi,
      direccion: direccion ?? this.direccion,
      colonia: colonia ?? this.colonia,
      ciudad: ciudad ?? this.ciudad,
      estado: estado ?? this.estado,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      pais: pais ?? this.pais,
      leadId: leadId ?? this.leadId,
      mensaje: mensaje ?? this.mensaje,
      fuente: fuente ?? this.fuente,
      interes: interes ?? this.interes,
      tags: tags ?? this.tags,
      notas: notas ?? this.notas,
      prioridad: prioridad ?? this.prioridad,
      valorEstimado: valorEstimado ?? this.valorEstimado,
      asignadoA: asignadoA ?? this.asignadoA,
      fechaUltimoContacto: fechaUltimoContacto ?? this.fechaUltimoContacto,
      fechaProximoSeguimiento: fechaProximoSeguimiento ?? this.fechaProximoSeguimiento,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}
