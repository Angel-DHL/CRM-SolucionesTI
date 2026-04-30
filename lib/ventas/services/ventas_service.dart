// lib/ventas/services/ventas_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/firebase_helper.dart';
import '../../crm/models/crm_enums.dart';
import '../../crm/services/crm_service.dart';
import '../models/sale_quote.dart';
import '../models/sale_order.dart';
import '../models/ventas_enums.dart';

class VentasService {
  VentasService._();
  static final VentasService instance = VentasService._();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ═══════════════════════════════════════════════════════════
  // FOLIOS AUTOMÁTICOS
  // ═══════════════════════════════════════════════════════════

  Future<String> _nextFolio(String prefix) async {
    final ref = FirebaseHelper.salesCounters.doc(prefix);
    final result = await FirebaseHelper.db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      int current = 0;
      if (snap.exists) {
        current = (snap.data()?['current'] ?? 0) as int;
      }
      final next = current + 1;
      tx.set(ref, {'current': next}, SetOptions(merge: true));
      return next;
    });
    return '$prefix-${result.toString().padLeft(4, '0')}';
  }

  // ═══════════════════════════════════════════════════════════
  // COTIZACIONES — CRUD
  // ═══════════════════════════════════════════════════════════

  Stream<List<SaleQuote>> streamQuotes() {
    return FirebaseHelper.salesQuotes
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SaleQuote.fromDoc).toList());
  }

  Stream<SaleQuote?> streamQuote(String id) {
    return FirebaseHelper.salesQuotes.doc(id).snapshots().map(
      (s) => s.exists ? SaleQuote.fromDoc(s) : null,
    );
  }

  Future<String> createQuote(SaleQuote quote) async {
    final folio = await _nextFolio('COT');
    final data = quote.copyWith(
      folio: folio,
      createdBy: _uid,
      lastModifiedBy: _uid,
    ).toMap();

    final doc = await FirebaseHelper.salesQuotes.add(data);

    // Trazabilidad: Registrar actividad en CRM
    await _logCrmActivity(
      quote.clienteId,
      'Cotización creada: $folio por \$${quote.total.toStringAsFixed(2)} ${quote.moneda}',
    );

    return doc.id;
  }

  Future<void> updateQuote(SaleQuote quote) async {
    final data = quote.copyWith(lastModifiedBy: _uid).toUpdateMap();
    await FirebaseHelper.salesQuotes.doc(quote.id).update(data);
  }

  Future<void> sendQuote(String quoteId) async {
    await FirebaseHelper.salesQuotes.doc(quoteId).update({
      'status': QuoteStatus.enviada.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _uid,
    });
  }

  Future<void> acceptQuote(String quoteId) async {
    await FirebaseHelper.salesQuotes.doc(quoteId).update({
      'status': QuoteStatus.aceptada.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _uid,
    });
  }

  Future<void> rejectQuote(String quoteId) async {
    await FirebaseHelper.salesQuotes.doc(quoteId).update({
      'status': QuoteStatus.rechazada.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _uid,
    });
  }

  // ═══════════════════════════════════════════════════════════
  // CONVERTIR COTIZACIÓN → ORDEN (PUNTO CLAVE DE TRAZABILIDAD)
  // ═══════════════════════════════════════════════════════════

  Future<String> convertQuoteToOrder(SaleQuote quote) async {
    final orderFolio = await _nextFolio('OV');

    // 1. Crear items de orden desde items de cotización
    final orderItems = quote.items.map((qi) => SaleOrderItem(
      inventoryItemId: qi.inventoryItemId,
      sku: qi.sku,
      nombre: qi.nombre,
      descripcion: qi.descripcion,
      cantidad: qi.cantidad,
      unidad: qi.unidad,
      precioUnitario: qi.precioUnitario,
      descuento: qi.descuento,
      subtotal: qi.subtotal,
    )).toList();

    // 2. Crear la orden de venta
    final order = SaleOrder(
      id: '',
      folio: orderFolio,
      status: OrderStatus.pendiente,
      paymentStatus: PaymentStatus.pendiente,
      quoteId: quote.id,
      quoteFolio: quote.folio,
      clienteId: quote.clienteId,
      clienteNombre: quote.clienteNombre,
      clienteEmail: quote.clienteEmail,
      clienteRfc: quote.clienteRfc,
      clienteRazonSocial: quote.clienteRazonSocial,
      clienteEmpresa: quote.clienteEmpresa,
      items: orderItems,
      subtotal: quote.subtotal,
      descuentoGlobal: quote.descuentoGlobal,
      subtotalConDescuento: quote.subtotalConDescuento,
      ivaPorcentaje: quote.ivaPorcentaje,
      ivaTotal: quote.ivaTotal,
      total: quote.total,
      moneda: quote.moneda,
      notas: quote.notas,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: _uid,
    );

    final orderDoc = await FirebaseHelper.salesOrders.add(order.toMap());

    // 3. Marcar cotización como convertida y enlazar con la orden
    await FirebaseHelper.salesQuotes.doc(quote.id).update({
      'status': QuoteStatus.convertida.value,
      'ordenId': orderDoc.id,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _uid,
    });

    // 4. Descontar stock del inventario
    for (final item in quote.items) {
      await _decrementStock(item.inventoryItemId, item.cantidad.toInt());
    }

    // 5. Registrar actividad en CRM
    await _logCrmActivity(
      quote.clienteId,
      'Orden de venta generada: $orderFolio desde cotización ${quote.folio}. Total: \$${quote.total.toStringAsFixed(2)}',
    );

    return orderDoc.id;
  }

  // ═══════════════════════════════════════════════════════════
  // ÓRDENES DE VENTA
  // ═══════════════════════════════════════════════════════════

  Stream<List<SaleOrder>> streamOrders() {
    return FirebaseHelper.salesOrders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SaleOrder.fromDoc).toList());
  }

  Stream<SaleOrder?> streamOrder(String id) {
    return FirebaseHelper.salesOrders.doc(id).snapshots().map(
      (s) => s.exists ? SaleOrder.fromDoc(s) : null,
    );
  }

  Future<void> completeOrder(String orderId) async {
    await FirebaseHelper.salesOrders.doc(orderId).update({
      'status': OrderStatus.completada.value,
      'fechaEntregaReal': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _uid,
    });
  }

  Future<void> registerPayment({
    required String orderId,
    required double monto,
    required PaymentMethod metodo,
    String? referencia,
    String? notas,
  }) async {
    final orderRef = FirebaseHelper.salesOrders.doc(orderId);
    final snap = await orderRef.get();
    if (!snap.exists) return;

    final order = SaleOrder.fromDoc(snap);
    final nuevoTotal = order.totalPagado + monto;
    final newPaymentStatus = nuevoTotal >= order.total
        ? PaymentStatus.pagada
        : PaymentStatus.parcial;

    final payment = PaymentRecord(
      monto: monto,
      metodo: metodo,
      referencia: referencia,
      notas: notas,
      fecha: DateTime.now(),
      registradoPor: _uid,
    );

    await orderRef.update({
      'totalPagado': nuevoTotal,
      'paymentStatus': newPaymentStatus.value,
      'metodoPagoPrincipal': metodo.value,
      'pagos': FieldValue.arrayUnion([payment.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': _uid,
    });

    // Trazabilidad: Si se pagó completo, avanzar contacto a "cliente" en CRM
    if (newPaymentStatus == PaymentStatus.pagada) {
      await _advanceContactToClient(order.clienteId);
      await _logCrmActivity(
        order.clienteId,
        'Pago completo registrado en orden ${order.folio}: \$${order.total.toStringAsFixed(2)}',
      );
    } else {
      await _logCrmActivity(
        order.clienteId,
        'Pago parcial de \$${monto.toStringAsFixed(2)} en orden ${order.folio}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Cotizaciones del mes
    final quotesSnap = await FirebaseHelper.salesQuotes
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();
    final quotes = quotesSnap.docs.map(SaleQuote.fromDoc).toList();

    // Órdenes del mes
    final ordersSnap = await FirebaseHelper.salesOrders
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();
    final orders = ordersSnap.docs.map(SaleOrder.fromDoc).toList();

    // Todas las órdenes para top productos
    final allOrdersSnap = await FirebaseHelper.salesOrders.get();
    final allOrders = allOrdersSnap.docs.map(SaleOrder.fromDoc).toList();

    // Top productos
    final productCount = <String, double>{};
    final productNames = <String, String>{};
    for (final order in allOrders) {
      for (final item in order.items) {
        productCount[item.sku] = (productCount[item.sku] ?? 0) + item.cantidad;
        productNames[item.sku] = item.nombre;
      }
    }
    final topProducts = productCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final ventasMes = orders
        .where((o) => o.paymentStatus == PaymentStatus.pagada)
        .fold<double>(0, (s, o) => s + o.total);
    final cotizacionesPendientes = quotes
        .where((q) => q.status == QuoteStatus.enviada || q.status == QuoteStatus.borrador)
        .length;
    final ordenesPorCobrar = orders
        .where((o) => o.paymentStatus != PaymentStatus.pagada)
        .fold<double>(0, (s, o) => s + o.saldoPendiente);
    final totalQuotes = quotes.length;
    final converted = quotes.where((q) => q.status == QuoteStatus.convertida).length;
    final tasaConversion = totalQuotes > 0 ? (converted / totalQuotes * 100) : 0.0;

    return {
      'ventasMes': ventasMes,
      'cotizacionesPendientes': cotizacionesPendientes,
      'ordenesPorCobrar': ordenesPorCobrar,
      'tasaConversion': tasaConversion,
      'totalCotizaciones': totalQuotes,
      'totalOrdenes': orders.length,
      'topProducts': topProducts.take(5).map((e) => {
        'sku': e.key,
        'nombre': productNames[e.key] ?? e.key,
        'cantidad': e.value,
      }).toList(),
    };
  }

  // ═══════════════════════════════════════════════════════════
  // INTEGRACIONES CON OTROS MÓDULOS
  // ═══════════════════════════════════════════════════════════

  /// Registra actividad en el historial del contacto en CRM
  Future<void> _logCrmActivity(String contactId, String mensaje) async {
    try {
      await CrmService.instance.addActivityLog(
        contactId: contactId,
        type: CrmActivityType.nota,
        titulo: 'Actividad de Ventas',
        descripcion: mensaje,
      );
    } catch (_) {
      // No bloquear operación de ventas si falla el log de CRM
    }
  }

  /// Descuenta stock del inventario
  Future<void> _decrementStock(String itemId, int cantidad) async {
    try {
      final ref = FirebaseHelper.inventoryItems.doc(itemId);
      await ref.update({
        'stock': FieldValue.increment(-cantidad),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // No bloquear si falla el decremento
    }
  }

  /// Avanza un contacto a "Cliente" si aún no lo es
  Future<void> _advanceContactToClient(String contactId) async {
    try {
      final ref = FirebaseHelper.crmContacts.doc(contactId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final data = snap.data()!;
      final currentStatus = data['status'] as String?;
      if (currentStatus != 'cliente') {
        await CrmService.instance.updateStatus(contactId, ContactStatus.cliente);
      }
    } catch (_) {}
  }
}
