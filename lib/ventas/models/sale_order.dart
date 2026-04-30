// lib/ventas/models/sale_order.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'ventas_enums.dart';

/// Línea individual de una orden de venta
class SaleOrderItem {
  final String inventoryItemId;
  final String sku;
  final String nombre;
  final String? descripcion;
  final double cantidad;
  final double cantidadEntregada;
  final String unidad;
  final double precioUnitario;
  final double descuento;
  final double subtotal;

  SaleOrderItem({
    required this.inventoryItemId,
    required this.sku,
    required this.nombre,
    this.descripcion,
    required this.cantidad,
    this.cantidadEntregada = 0,
    this.unidad = 'pieza',
    required this.precioUnitario,
    this.descuento = 0,
    required this.subtotal,
  });

  bool get isFullyDelivered => cantidadEntregada >= cantidad;
  double get pendiente => cantidad - cantidadEntregada;

  factory SaleOrderItem.fromMap(Map<String, dynamic> m) => SaleOrderItem(
    inventoryItemId: m['inventoryItemId'] ?? '',
    sku: m['sku'] ?? '',
    nombre: m['nombre'] ?? '',
    descripcion: m['descripcion'],
    cantidad: (m['cantidad'] ?? 0).toDouble(),
    cantidadEntregada: (m['cantidadEntregada'] ?? 0).toDouble(),
    unidad: m['unidad'] ?? 'pieza',
    precioUnitario: (m['precioUnitario'] ?? 0).toDouble(),
    descuento: (m['descuento'] ?? 0).toDouble(),
    subtotal: (m['subtotal'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'inventoryItemId': inventoryItemId,
    'sku': sku, 'nombre': nombre, 'descripcion': descripcion,
    'cantidad': cantidad, 'cantidadEntregada': cantidadEntregada,
    'unidad': unidad, 'precioUnitario': precioUnitario,
    'descuento': descuento, 'subtotal': subtotal,
  };
}

/// Registro de pago parcial o total
class PaymentRecord {
  final double monto;
  final PaymentMethod metodo;
  final String? referencia;
  final String? notas;
  final DateTime fecha;
  final String registradoPor;

  PaymentRecord({
    required this.monto,
    required this.metodo,
    this.referencia,
    this.notas,
    required this.fecha,
    required this.registradoPor,
  });

  factory PaymentRecord.fromMap(Map<String, dynamic> m) => PaymentRecord(
    monto: (m['monto'] ?? 0).toDouble(),
    metodo: PaymentMethodX.from(m['metodo']),
    referencia: m['referencia'],
    notas: m['notas'],
    fecha: m['fecha'] is Timestamp ? (m['fecha'] as Timestamp).toDate() : DateTime.now(),
    registradoPor: m['registradoPor'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'monto': monto, 'metodo': metodo.value,
    'referencia': referencia, 'notas': notas,
    'fecha': Timestamp.fromDate(fecha),
    'registradoPor': registradoPor,
  };
}

/// Orden de venta (se crea al convertir una cotización)
class SaleOrder {
  final String id;
  final String folio;
  final OrderStatus status;
  final PaymentStatus paymentStatus;

  // Trazabilidad
  final String quoteId;
  final String quoteFolio;

  // Cliente (desnormalizado)
  final String clienteId;
  final String clienteNombre;
  final String? clienteEmail;
  final String? clienteRfc;
  final String? clienteRazonSocial;
  final String? clienteEmpresa;

  // Líneas
  final List<SaleOrderItem> items;

  // Financiero
  final double subtotal;
  final double descuentoGlobal;
  final double subtotalConDescuento;
  final double ivaPorcentaje;
  final double ivaTotal;
  final double total;
  final double totalPagado;
  final String moneda;

  // Pagos
  final List<PaymentRecord> pagos;
  final PaymentMethod? metodoPagoPrincipal;

  // Fechas
  final DateTime? fechaEntrega;
  final DateTime? fechaEntregaReal;
  final DateTime? fechaVencimientoPago;

  // Notas
  final String? notas;
  final String? notasInternas;

  // Auditoría
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? lastModifiedBy;

  SaleOrder({
    required this.id,
    required this.folio,
    required this.status,
    required this.paymentStatus,
    required this.quoteId,
    required this.quoteFolio,
    required this.clienteId,
    required this.clienteNombre,
    this.clienteEmail, this.clienteRfc,
    this.clienteRazonSocial, this.clienteEmpresa,
    required this.items,
    required this.subtotal,
    this.descuentoGlobal = 0,
    required this.subtotalConDescuento,
    this.ivaPorcentaje = 16,
    required this.ivaTotal,
    required this.total,
    this.totalPagado = 0,
    this.moneda = 'MXN',
    this.pagos = const [],
    this.metodoPagoPrincipal,
    this.fechaEntrega, this.fechaEntregaReal, this.fechaVencimientoPago,
    this.notas, this.notasInternas,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastModifiedBy,
  });

  // Propiedades útiles
  double get saldoPendiente => total - totalPagado;
  bool get isPaidInFull => totalPagado >= total;
  bool get isOverdue =>
      fechaVencimientoPago != null &&
      fechaVencimientoPago!.isBefore(DateTime.now()) &&
      !isPaidInFull;
  bool get allItemsDelivered => items.every((i) => i.isFullyDelivered);
  int get totalItems => items.length;

  static SaleOrder fromDoc(DocumentSnapshot doc) {
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

    return SaleOrder(
      id: doc.id,
      folio: d['folio'] ?? '',
      status: OrderStatusX.from(d['status']),
      paymentStatus: PaymentStatusX.from(d['paymentStatus']),
      quoteId: d['quoteId'] ?? '',
      quoteFolio: d['quoteFolio'] ?? '',
      clienteId: d['clienteId'] ?? '',
      clienteNombre: d['clienteNombre'] ?? '',
      clienteEmail: d['clienteEmail'],
      clienteRfc: d['clienteRfc'],
      clienteRazonSocial: d['clienteRazonSocial'],
      clienteEmpresa: d['clienteEmpresa'],
      items: (d['items'] as List<dynamic>?)
          ?.map((i) => SaleOrderItem.fromMap(i as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (d['subtotal'] ?? 0).toDouble(),
      descuentoGlobal: (d['descuentoGlobal'] ?? 0).toDouble(),
      subtotalConDescuento: (d['subtotalConDescuento'] ?? 0).toDouble(),
      ivaPorcentaje: (d['ivaPorcentaje'] ?? 16).toDouble(),
      ivaTotal: (d['ivaTotal'] ?? 0).toDouble(),
      total: (d['total'] ?? 0).toDouble(),
      totalPagado: (d['totalPagado'] ?? 0).toDouble(),
      moneda: d['moneda'] ?? 'MXN',
      pagos: (d['pagos'] as List<dynamic>?)
          ?.map((p) => PaymentRecord.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      metodoPagoPrincipal: d['metodoPagoPrincipal'] != null
          ? PaymentMethodX.from(d['metodoPagoPrincipal'])
          : null,
      fechaEntrega: parseTsNull(d['fechaEntrega']),
      fechaEntregaReal: parseTsNull(d['fechaEntregaReal']),
      fechaVencimientoPago: parseTsNull(d['fechaVencimientoPago']),
      notas: d['notas'],
      notasInternas: d['notasInternas'],
      createdAt: parseTs(d['createdAt']),
      updatedAt: parseTs(d['updatedAt']),
      createdBy: d['createdBy'] ?? '',
      lastModifiedBy: d['lastModifiedBy'],
    );
  }

  Map<String, dynamic> toMap() => {
    'folio': folio, 'status': status.value,
    'paymentStatus': paymentStatus.value,
    'quoteId': quoteId, 'quoteFolio': quoteFolio,
    'clienteId': clienteId, 'clienteNombre': clienteNombre,
    'clienteEmail': clienteEmail, 'clienteRfc': clienteRfc,
    'clienteRazonSocial': clienteRazonSocial, 'clienteEmpresa': clienteEmpresa,
    'items': items.map((i) => i.toMap()).toList(),
    'subtotal': subtotal, 'descuentoGlobal': descuentoGlobal,
    'subtotalConDescuento': subtotalConDescuento,
    'ivaPorcentaje': ivaPorcentaje, 'ivaTotal': ivaTotal,
    'total': total, 'totalPagado': totalPagado, 'moneda': moneda,
    'pagos': pagos.map((p) => p.toMap()).toList(),
    'metodoPagoPrincipal': metodoPagoPrincipal?.value,
    'fechaEntrega': fechaEntrega != null ? Timestamp.fromDate(fechaEntrega!) : null,
    'fechaEntregaReal': fechaEntregaReal != null ? Timestamp.fromDate(fechaEntregaReal!) : null,
    'fechaVencimientoPago': fechaVencimientoPago != null ? Timestamp.fromDate(fechaVencimientoPago!) : null,
    'notas': notas, 'notasInternas': notasInternas,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy, 'lastModifiedBy': lastModifiedBy,
  };
}
