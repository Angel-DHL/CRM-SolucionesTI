// lib/ventas/models/sale_quote.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'ventas_enums.dart';

/// Línea individual de una cotización
class SaleQuoteItem {
  final String inventoryItemId;
  final String sku;
  final String nombre;
  final String? descripcion;
  final double cantidad;
  final String unidad;
  final double precioUnitario;
  final double descuento; // porcentaje 0-100
  final double subtotal;

  SaleQuoteItem({
    required this.inventoryItemId,
    required this.sku,
    required this.nombre,
    this.descripcion,
    required this.cantidad,
    this.unidad = 'pieza',
    required this.precioUnitario,
    this.descuento = 0,
    required this.subtotal,
  });

  /// Calcula el subtotal considerando descuento
  static double calcSubtotal(double cantidad, double precioUnitario, double descuento) {
    final base = cantidad * precioUnitario;
    return base - (base * descuento / 100);
  }

  factory SaleQuoteItem.fromMap(Map<String, dynamic> m) {
    return SaleQuoteItem(
      inventoryItemId: m['inventoryItemId'] ?? '',
      sku: m['sku'] ?? '',
      nombre: m['nombre'] ?? '',
      descripcion: m['descripcion'],
      cantidad: (m['cantidad'] ?? 0).toDouble(),
      unidad: m['unidad'] ?? 'pieza',
      precioUnitario: (m['precioUnitario'] ?? 0).toDouble(),
      descuento: (m['descuento'] ?? 0).toDouble(),
      subtotal: (m['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'inventoryItemId': inventoryItemId,
    'sku': sku,
    'nombre': nombre,
    'descripcion': descripcion,
    'cantidad': cantidad,
    'unidad': unidad,
    'precioUnitario': precioUnitario,
    'descuento': descuento,
    'subtotal': subtotal,
  };

  SaleQuoteItem copyWith({
    String? inventoryItemId, String? sku, String? nombre, String? descripcion,
    double? cantidad, String? unidad, double? precioUnitario, double? descuento, double? subtotal,
  }) {
    return SaleQuoteItem(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      sku: sku ?? this.sku, nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      cantidad: cantidad ?? this.cantidad, unidad: unidad ?? this.unidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      descuento: descuento ?? this.descuento, subtotal: subtotal ?? this.subtotal,
    );
  }
}

/// Cotización de venta
class SaleQuote {
  final String id;
  final String folio;
  final QuoteStatus status;

  // Cliente (desnormalizado de crm_contacts)
  final String clienteId;
  final String clienteNombre;
  final String? clienteEmail;
  final String? clienteTelefono;
  final String? clienteRfc;
  final String? clienteRazonSocial;
  final String? clienteEmpresa;
  final String? clienteDireccion;

  // Líneas de la cotización
  final List<SaleQuoteItem> items;

  // Financiero
  final double subtotal;
  final double descuentoGlobal; // porcentaje
  final double subtotalConDescuento;
  final double ivaPorcentaje;
  final double ivaTotal;
  final double total;
  final String moneda;

  // Condiciones
  final int vigenciaDias;
  final DateTime? fechaExpiracion;
  final String? condicionesPago;
  final String? notas;
  final String? notasInternas;

  // Trazabilidad
  final String? ordenId; // Si ya se convirtió a orden
  final String? opportunityId; // Vinculación con oportunidad
  final int version; // Versión de la cotización

  // Email
  final DateTime? emailEnviadoAt;
  final String? emailEnviadoA;

  // Auditoría
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? lastModifiedBy;

  SaleQuote({
    required this.id,
    required this.folio,
    required this.status,
    required this.clienteId,
    required this.clienteNombre,
    this.clienteEmail, this.clienteTelefono,
    this.clienteRfc, this.clienteRazonSocial, this.clienteEmpresa,
    this.clienteDireccion,
    required this.items,
    required this.subtotal,
    this.descuentoGlobal = 0,
    required this.subtotalConDescuento,
    this.ivaPorcentaje = 16,
    required this.ivaTotal,
    required this.total,
    this.moneda = 'MXN',
    this.vigenciaDias = 15,
    this.fechaExpiracion,
    this.condicionesPago, this.notas, this.notasInternas,
    this.ordenId,
    this.opportunityId,
    this.version = 1,
    this.emailEnviadoAt,
    this.emailEnviadoA,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastModifiedBy,
  });

  // Propiedades útiles
  int get totalItems => items.length;
  double get totalCantidad => items.fold(0, (s, i) => s + i.cantidad);
  bool get isExpired => fechaExpiracion != null && fechaExpiracion!.isBefore(DateTime.now());
  bool get canEdit => status.canEdit;
  bool get canConvert => status.canConvert && !isExpired;
  bool get hasBeenEmailed => emailEnviadoAt != null;

  /// Días restantes de vigencia
  int get diasRestantes {
    if (fechaExpiracion == null) return vigenciaDias;
    return fechaExpiracion!.difference(DateTime.now()).inDays;
  }

  bool get porVencer => diasRestantes <= 3 && diasRestantes > 0 && status == QuoteStatus.enviada;

  /// Recalcula totales desde los items
  static Map<String, double> calcTotals(List<SaleQuoteItem> items, double descuentoGlobal, double ivaPorcentaje) {
    final subtotal = items.fold<double>(0, (s, i) => s + i.subtotal);
    final descuentoMonto = subtotal * descuentoGlobal / 100;
    final subtotalConDescuento = subtotal - descuentoMonto;
    final ivaTotal = subtotalConDescuento * ivaPorcentaje / 100;
    final total = subtotalConDescuento + ivaTotal;
    return {
      'subtotal': subtotal,
      'subtotalConDescuento': subtotalConDescuento,
      'ivaTotal': ivaTotal,
      'total': total,
    };
  }

  static SaleQuote fromDoc(DocumentSnapshot doc) {
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

    final itemsList = (d['items'] as List<dynamic>?)
        ?.map((i) => SaleQuoteItem.fromMap(i as Map<String, dynamic>))
        .toList() ?? [];

    return SaleQuote(
      id: doc.id,
      folio: d['folio'] ?? '',
      status: QuoteStatusX.from(d['status']),
      clienteId: d['clienteId'] ?? '',
      clienteNombre: d['clienteNombre'] ?? '',
      clienteEmail: d['clienteEmail'],
      clienteTelefono: d['clienteTelefono'],
      clienteRfc: d['clienteRfc'],
      clienteRazonSocial: d['clienteRazonSocial'],
      clienteEmpresa: d['clienteEmpresa'],
      clienteDireccion: d['clienteDireccion'],
      items: itemsList,
      subtotal: (d['subtotal'] ?? 0).toDouble(),
      descuentoGlobal: (d['descuentoGlobal'] ?? 0).toDouble(),
      subtotalConDescuento: (d['subtotalConDescuento'] ?? 0).toDouble(),
      ivaPorcentaje: (d['ivaPorcentaje'] ?? 16).toDouble(),
      ivaTotal: (d['ivaTotal'] ?? 0).toDouble(),
      total: (d['total'] ?? 0).toDouble(),
      moneda: d['moneda'] ?? 'MXN',
      vigenciaDias: d['vigenciaDias'] ?? 15,
      fechaExpiracion: parseTsNull(d['fechaExpiracion']),
      condicionesPago: d['condicionesPago'],
      notas: d['notas'],
      notasInternas: d['notasInternas'],
      ordenId: d['ordenId'],
      opportunityId: d['opportunityId'],
      version: d['version'] ?? 1,
      emailEnviadoAt: parseTsNull(d['emailEnviadoAt']),
      emailEnviadoA: d['emailEnviadoA'],
      createdAt: parseTs(d['createdAt']),
      updatedAt: parseTs(d['updatedAt']),
      createdBy: d['createdBy'] ?? '',
      lastModifiedBy: d['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toMap() => {
    'folio': folio,
    'status': status.value,
    'clienteId': clienteId,
    'clienteNombre': clienteNombre,
    'clienteEmail': clienteEmail,
    'clienteTelefono': clienteTelefono,
    'clienteRfc': clienteRfc,
    'clienteRazonSocial': clienteRazonSocial,
    'clienteEmpresa': clienteEmpresa,
    'clienteDireccion': clienteDireccion,
    'items': items.map((i) => i.toMap()).toList(),
    'subtotal': subtotal,
    'descuentoGlobal': descuentoGlobal,
    'subtotalConDescuento': subtotalConDescuento,
    'ivaPorcentaje': ivaPorcentaje,
    'ivaTotal': ivaTotal,
    'total': total,
    'moneda': moneda,
    'vigenciaDias': vigenciaDias,
    'fechaExpiracion': fechaExpiracion != null ? Timestamp.fromDate(fechaExpiracion!) : null,
    'condicionesPago': condicionesPago,
    'notas': notas,
    'notasInternas': notasInternas,
    'ordenId': ordenId,
    'opportunityId': opportunityId,
    'version': version,
    'emailEnviadoAt': emailEnviadoAt != null ? Timestamp.fromDate(emailEnviadoAt!) : null,
    'emailEnviadoA': emailEnviadoA,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy,
    'lastModifiedBy': lastModifiedBy,
  };

  Map<String, dynamic> toUpdateMap() => {
    'status': status.value,
    'clienteId': clienteId,
    'clienteNombre': clienteNombre,
    'clienteEmail': clienteEmail,
    'clienteTelefono': clienteTelefono,
    'clienteRfc': clienteRfc,
    'clienteRazonSocial': clienteRazonSocial,
    'clienteEmpresa': clienteEmpresa,
    'clienteDireccion': clienteDireccion,
    'items': items.map((i) => i.toMap()).toList(),
    'subtotal': subtotal,
    'descuentoGlobal': descuentoGlobal,
    'subtotalConDescuento': subtotalConDescuento,
    'ivaPorcentaje': ivaPorcentaje,
    'ivaTotal': ivaTotal,
    'total': total,
    'moneda': moneda,
    'vigenciaDias': vigenciaDias,
    'fechaExpiracion': fechaExpiracion != null ? Timestamp.fromDate(fechaExpiracion!) : null,
    'condicionesPago': condicionesPago,
    'notas': notas,
    'notasInternas': notasInternas,
    'ordenId': ordenId,
    'opportunityId': opportunityId,
    'version': version,
    'emailEnviadoAt': emailEnviadoAt != null ? Timestamp.fromDate(emailEnviadoAt!) : null,
    'emailEnviadoA': emailEnviadoA,
    'updatedAt': FieldValue.serverTimestamp(),
    'lastModifiedBy': lastModifiedBy,
  };

  SaleQuote copyWith({
    String? id, String? folio, QuoteStatus? status,
    String? clienteId, String? clienteNombre, String? clienteEmail,
    String? clienteTelefono, String? clienteRfc, String? clienteRazonSocial,
    String? clienteEmpresa, String? clienteDireccion,
    List<SaleQuoteItem>? items,
    double? subtotal, double? descuentoGlobal, double? subtotalConDescuento,
    double? ivaPorcentaje, double? ivaTotal, double? total, String? moneda,
    int? vigenciaDias, DateTime? fechaExpiracion,
    String? condicionesPago, String? notas, String? notasInternas,
    String? ordenId, String? opportunityId, int? version,
    DateTime? emailEnviadoAt, String? emailEnviadoA,
    DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? lastModifiedBy,
  }) {
    return SaleQuote(
      id: id ?? this.id, folio: folio ?? this.folio,
      status: status ?? this.status,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      clienteRfc: clienteRfc ?? this.clienteRfc,
      clienteRazonSocial: clienteRazonSocial ?? this.clienteRazonSocial,
      clienteEmpresa: clienteEmpresa ?? this.clienteEmpresa,
      clienteDireccion: clienteDireccion ?? this.clienteDireccion,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      descuentoGlobal: descuentoGlobal ?? this.descuentoGlobal,
      subtotalConDescuento: subtotalConDescuento ?? this.subtotalConDescuento,
      ivaPorcentaje: ivaPorcentaje ?? this.ivaPorcentaje,
      ivaTotal: ivaTotal ?? this.ivaTotal,
      total: total ?? this.total,
      moneda: moneda ?? this.moneda,
      vigenciaDias: vigenciaDias ?? this.vigenciaDias,
      fechaExpiracion: fechaExpiracion ?? this.fechaExpiracion,
      condicionesPago: condicionesPago ?? this.condicionesPago,
      notas: notas ?? this.notas,
      notasInternas: notasInternas ?? this.notasInternas,
      ordenId: ordenId ?? this.ordenId,
      opportunityId: opportunityId ?? this.opportunityId,
      version: version ?? this.version,
      emailEnviadoAt: emailEnviadoAt ?? this.emailEnviadoAt,
      emailEnviadoA: emailEnviadoA ?? this.emailEnviadoA,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}
