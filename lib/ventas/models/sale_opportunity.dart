// lib/ventas/models/sale_opportunity.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'ventas_enums.dart';

/// Oportunidad de venta en el pipeline comercial
class SaleOpportunity {
  final String id;
  final String folio;
  final OpportunityStatus status;

  // Información de la oportunidad
  final String titulo;
  final String? descripcion;
  final double valorEstimado;
  final double probabilidad; // 0-100
  final OpportunitySource origen;
  final DateTime? fechaCierreEstimada;
  final String? motivoPerdida;

  // Contacto vinculado (desnormalizado de CRM)
  final String contactoId;
  final String contactoNombre;
  final String? contactoEmail;
  final String? contactoTelefono;
  final String? contactoEmpresa;

  // Cotizaciones vinculadas
  final List<String> cotizacionIds;

  // Notas
  final String? notas;
  final String? notasInternas;

  // Asignación
  final String? asignadoA;

  // Auditoría
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? lastModifiedBy;

  SaleOpportunity({
    required this.id,
    required this.folio,
    required this.status,
    required this.titulo,
    this.descripcion,
    required this.valorEstimado,
    this.probabilidad = 50,
    this.origen = OpportunitySource.otro,
    this.fechaCierreEstimada,
    this.motivoPerdida,
    required this.contactoId,
    required this.contactoNombre,
    this.contactoEmail,
    this.contactoTelefono,
    this.contactoEmpresa,
    this.cotizacionIds = const [],
    this.notas,
    this.notasInternas,
    this.asignadoA,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastModifiedBy,
  });

  // Propiedades calculadas
  double get valorPonderado => valorEstimado * probabilidad / 100;
  bool get isActive => status.isActive;
  bool get canAdvance => status.canAdvance;
  int get totalCotizaciones => cotizacionIds.length;

  static SaleOpportunity fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    DateTime parseTs(dynamic t) {
      if (t == null) return DateTime.now();
      if (t is Timestamp) return t.toDate().toLocal();
      return DateTime.now();
    }
    DateTime? parseTsNull(dynamic t) {
      if (t == null) return null;
      if (t is Timestamp) return t.toDate().toLocal();
      return null;
    }

    return SaleOpportunity(
      id: doc.id,
      folio: d['folio'] ?? '',
      status: OpportunityStatusX.from(d['status']),
      titulo: d['titulo'] ?? '',
      descripcion: d['descripcion'],
      valorEstimado: (d['valorEstimado'] ?? 0).toDouble(),
      probabilidad: (d['probabilidad'] ?? 50).toDouble(),
      origen: OpportunitySourceX.from(d['origen']),
      fechaCierreEstimada: parseTsNull(d['fechaCierreEstimada']),
      motivoPerdida: d['motivoPerdida'],
      contactoId: d['contactoId'] ?? '',
      contactoNombre: d['contactoNombre'] ?? '',
      contactoEmail: d['contactoEmail'],
      contactoTelefono: d['contactoTelefono'],
      contactoEmpresa: d['contactoEmpresa'],
      cotizacionIds: List<String>.from(d['cotizacionIds'] ?? []),
      notas: d['notas'],
      notasInternas: d['notasInternas'],
      asignadoA: d['asignadoA'],
      createdAt: parseTs(d['createdAt']),
      updatedAt: parseTs(d['updatedAt']),
      createdBy: d['createdBy'] ?? '',
      lastModifiedBy: d['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toMap() => {
    'folio': folio,
    'status': status.value,
    'titulo': titulo,
    'descripcion': descripcion,
    'valorEstimado': valorEstimado,
    'probabilidad': probabilidad,
    'origen': origen.value,
    'fechaCierreEstimada': fechaCierreEstimada != null
        ? Timestamp.fromDate(fechaCierreEstimada!)
        : null,
    'motivoPerdida': motivoPerdida,
    'contactoId': contactoId,
    'contactoNombre': contactoNombre,
    'contactoEmail': contactoEmail,
    'contactoTelefono': contactoTelefono,
    'contactoEmpresa': contactoEmpresa,
    'cotizacionIds': cotizacionIds,
    'notas': notas,
    'notasInternas': notasInternas,
    'asignadoA': asignadoA,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy,
    'lastModifiedBy': lastModifiedBy,
  };

  Map<String, dynamic> toUpdateMap() => {
    'status': status.value,
    'titulo': titulo,
    'descripcion': descripcion,
    'valorEstimado': valorEstimado,
    'probabilidad': probabilidad,
    'origen': origen.value,
    'fechaCierreEstimada': fechaCierreEstimada != null
        ? Timestamp.fromDate(fechaCierreEstimada!)
        : null,
    'motivoPerdida': motivoPerdida,
    'contactoId': contactoId,
    'contactoNombre': contactoNombre,
    'contactoEmail': contactoEmail,
    'contactoTelefono': contactoTelefono,
    'contactoEmpresa': contactoEmpresa,
    'cotizacionIds': cotizacionIds,
    'notas': notas,
    'notasInternas': notasInternas,
    'asignadoA': asignadoA,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastModifiedBy': lastModifiedBy,
  };

  SaleOpportunity copyWith({
    String? id, String? folio, OpportunityStatus? status,
    String? titulo, String? descripcion,
    double? valorEstimado, double? probabilidad,
    OpportunitySource? origen, DateTime? fechaCierreEstimada,
    String? motivoPerdida,
    String? contactoId, String? contactoNombre, String? contactoEmail,
    String? contactoTelefono, String? contactoEmpresa,
    List<String>? cotizacionIds,
    String? notas, String? notasInternas, String? asignadoA,
    DateTime? createdAt, DateTime? updatedAt,
    String? createdBy, String? lastModifiedBy,
  }) {
    return SaleOpportunity(
      id: id ?? this.id, folio: folio ?? this.folio,
      status: status ?? this.status,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      valorEstimado: valorEstimado ?? this.valorEstimado,
      probabilidad: probabilidad ?? this.probabilidad,
      origen: origen ?? this.origen,
      fechaCierreEstimada: fechaCierreEstimada ?? this.fechaCierreEstimada,
      motivoPerdida: motivoPerdida ?? this.motivoPerdida,
      contactoId: contactoId ?? this.contactoId,
      contactoNombre: contactoNombre ?? this.contactoNombre,
      contactoEmail: contactoEmail ?? this.contactoEmail,
      contactoTelefono: contactoTelefono ?? this.contactoTelefono,
      contactoEmpresa: contactoEmpresa ?? this.contactoEmpresa,
      cotizacionIds: cotizacionIds ?? this.cotizacionIds,
      notas: notas ?? this.notas,
      notasInternas: notasInternas ?? this.notasInternas,
      asignadoA: asignadoA ?? this.asignadoA,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}
