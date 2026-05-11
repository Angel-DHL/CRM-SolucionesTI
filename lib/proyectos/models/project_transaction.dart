// lib/proyectos/models/project_transaction.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_enums.dart';

/// Transacción financiera de un proyecto.
/// Subcolección: `projects/{projectId}/project_transactions/{transactionId}`
class ProjectTransaction {
  final String id;
  final String projectId;
  final String folio;
  final TransactionType type;
  final TransactionStatus status;
  final double monto;
  final String moneda;
  final PaymentMethodProject? metodoPago;
  final String concepto;
  final String? descripcion;
  final String? referencia;
  final String? categoria;
  final DateTime fechaTransaccion;
  final DateTime? fechaVencimiento;
  final DateTime? fechaAprobacion;
  final String? comprobanteUrl;
  final List<String> documentosAdjuntos;
  final String? aprobadoPor;
  final String? aprobadoPorNombre;
  final String? motivoRechazo;
  final String? ordenVentaId;
  final String? inventoryItemId;
  final String? inventoryItemName;
  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? createdByName;
  final String? lastModifiedBy;

  ProjectTransaction({
    required this.id,
    required this.projectId,
    required this.folio,
    required this.type,
    required this.status,
    required this.monto,
    this.moneda = 'MXN',
    this.metodoPago,
    required this.concepto,
    this.descripcion,
    this.referencia,
    this.categoria,
    required this.fechaTransaccion,
    this.fechaVencimiento,
    this.fechaAprobacion,
    this.comprobanteUrl,
    this.documentosAdjuntos = const [],
    this.aprobadoPor,
    this.aprobadoPorNombre,
    this.motivoRechazo,
    this.ordenVentaId,
    this.inventoryItemId,
    this.inventoryItemName,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.createdByName,
    this.lastModifiedBy,
  });

  bool get esIngreso => type.isIncome;
  bool get esEgreso => type.isExpense;
  bool get estaVencida =>
      fechaVencimiento != null &&
      fechaVencimiento!.isBefore(DateTime.now()) &&
      status == TransactionStatus.pendiente;
  bool get estaConfirmada =>
      status == TransactionStatus.aprobada ||
      status == TransactionStatus.completada;

  static ProjectTransaction fromDoc(DocumentSnapshot doc, String projectId) {
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

    return ProjectTransaction(
      id: doc.id,
      projectId: projectId,
      folio: d['folio'] ?? '',
      type: TransactionTypeX.from(d['type']),
      status: TransactionStatusX.from(d['status']),
      monto: (d['monto'] ?? 0).toDouble(),
      moneda: d['moneda'] ?? 'MXN',
      metodoPago: d['metodoPago'] != null ? PaymentMethodProjectX.from(d['metodoPago']) : null,
      concepto: d['concepto'] ?? '',
      descripcion: d['descripcion'],
      referencia: d['referencia'],
      categoria: d['categoria'],
      fechaTransaccion: parseTs(d['fechaTransaccion']),
      fechaVencimiento: parseTsNull(d['fechaVencimiento']),
      fechaAprobacion: parseTsNull(d['fechaAprobacion']),
      comprobanteUrl: d['comprobanteUrl'],
      documentosAdjuntos: List<String>.from(d['documentosAdjuntos'] ?? []),
      aprobadoPor: d['aprobadoPor'],
      aprobadoPorNombre: d['aprobadoPorNombre'],
      motivoRechazo: d['motivoRechazo'],
      ordenVentaId: d['ordenVentaId'],
      inventoryItemId: d['inventoryItemId'],
      inventoryItemName: d['inventoryItemName'],
      notas: d['notas'],
      createdAt: parseTs(d['createdAt']),
      updatedAt: parseTs(d['updatedAt']),
      createdBy: d['createdBy'] ?? '',
      createdByName: d['createdByName'],
      lastModifiedBy: d['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toMap() => {
    'folio': folio, 'type': type.value, 'status': status.value,
    'monto': monto, 'moneda': moneda, 'metodoPago': metodoPago?.value,
    'concepto': concepto, 'descripcion': descripcion,
    'referencia': referencia, 'categoria': categoria,
    'fechaTransaccion': Timestamp.fromDate(fechaTransaccion),
    'fechaVencimiento': fechaVencimiento != null ? Timestamp.fromDate(fechaVencimiento!) : null,
    'fechaAprobacion': fechaAprobacion != null ? Timestamp.fromDate(fechaAprobacion!) : null,
    'comprobanteUrl': comprobanteUrl, 'documentosAdjuntos': documentosAdjuntos,
    'aprobadoPor': aprobadoPor, 'aprobadoPorNombre': aprobadoPorNombre,
    'motivoRechazo': motivoRechazo, 'ordenVentaId': ordenVentaId,
    'inventoryItemId': inventoryItemId, 'inventoryItemName': inventoryItemName,
    'notas': notas,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy, 'createdByName': createdByName,
    'lastModifiedBy': lastModifiedBy,
  };

  Map<String, dynamic> toUpdateMap() {
    final map = toMap();
    map.remove('createdAt');
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  ProjectTransaction copyWith({
    String? id, String? projectId, String? folio,
    TransactionType? type, TransactionStatus? status,
    double? monto, String? moneda, PaymentMethodProject? metodoPago,
    String? concepto, String? descripcion, String? referencia, String? categoria,
    DateTime? fechaTransaccion, DateTime? fechaVencimiento, DateTime? fechaAprobacion,
    String? comprobanteUrl, List<String>? documentosAdjuntos,
    String? aprobadoPor, String? aprobadoPorNombre, String? motivoRechazo,
    String? ordenVentaId, String? inventoryItemId, String? inventoryItemName,
    String? notas, DateTime? createdAt, DateTime? updatedAt,
    String? createdBy, String? createdByName, String? lastModifiedBy,
  }) {
    return ProjectTransaction(
      id: id ?? this.id, projectId: projectId ?? this.projectId,
      folio: folio ?? this.folio, type: type ?? this.type,
      status: status ?? this.status, monto: monto ?? this.monto,
      moneda: moneda ?? this.moneda, metodoPago: metodoPago ?? this.metodoPago,
      concepto: concepto ?? this.concepto, descripcion: descripcion ?? this.descripcion,
      referencia: referencia ?? this.referencia, categoria: categoria ?? this.categoria,
      fechaTransaccion: fechaTransaccion ?? this.fechaTransaccion,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      comprobanteUrl: comprobanteUrl ?? this.comprobanteUrl,
      documentosAdjuntos: documentosAdjuntos ?? this.documentosAdjuntos,
      aprobadoPor: aprobadoPor ?? this.aprobadoPor,
      aprobadoPorNombre: aprobadoPorNombre ?? this.aprobadoPorNombre,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      ordenVentaId: ordenVentaId ?? this.ordenVentaId,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      inventoryItemName: inventoryItemName ?? this.inventoryItemName,
      notas: notas ?? this.notas,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy, createdByName: createdByName ?? this.createdByName,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}
