// lib/inventory/services/inventory_movement_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase_helper.dart';
import '../models/inventory_enums.dart';
import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';

class InventoryMovementService {
  InventoryMovementService._();
  static final InventoryMovementService instance = InventoryMovementService._();

  CollectionReference<Map<String, dynamic>> get _movementsRef =>
      FirebaseHelper.inventoryMovements;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      FirebaseHelper.inventoryItems;

  // ═══════════════════════════════════════════════════════════
  // CREAR MOVIMIENTO
  // ═══════════════════════════════════════════════════════════

  /// Registrar entrada de stock
  Future<String> registerStockIn({
    required String itemId,
    required int quantity,
    required String reason,
    MovementType type = MovementType.purchase,
    String? supplierId,
    String? supplierName,
    String? referenceNumber,
    String? batchNumber,
    DateTime? expirationDate,
    double? unitCost,
    String? toLocationId,
    String? toLocationName,
    String? notes,
    List<String>? attachmentUrls,
  }) async {
    if (quantity <= 0) throw Exception('La cantidad debe ser mayor a 0');

    return _createMovement(
      itemId: itemId,
      quantity: quantity,
      type: type,
      reason: reason,
      supplierId: supplierId,
      supplierName: supplierName,
      referenceNumber: referenceNumber,
      batchNumber: batchNumber,
      expirationDate: expirationDate,
      unitCost: unitCost,
      toLocationId: toLocationId,
      toLocationName: toLocationName,
      notes: notes,
      attachmentUrls: attachmentUrls,
    );
  }

  /// Registrar salida de stock
  Future<String> registerStockOut({
    required String itemId,
    required int quantity,
    required String reason,
    MovementType type = MovementType.sale,
    String? customerId,
    String? customerName,
    String? referenceNumber,
    String? fromLocationId,
    String? fromLocationName,
    String? notes,
    List<String>? attachmentUrls,
  }) async {
    if (quantity <= 0) throw Exception('La cantidad debe ser mayor a 0');

    return _createMovement(
      itemId: itemId,
      quantity: quantity,
      type: type,
      reason: reason,
      customerId: customerId,
      customerName: customerName,
      referenceNumber: referenceNumber,
      fromLocationId: fromLocationId,
      fromLocationName: fromLocationName,
      notes: notes,
      attachmentUrls: attachmentUrls,
    );
  }

  /// Registrar transferencia entre ubicaciones
  Future<String> registerTransfer({
    required String itemId,
    required int quantity,
    required String fromLocationId,
    required String fromLocationName,
    required String toLocationId,
    required String toLocationName,
    required String reason,
    String? notes,
  }) async {
    if (quantity <= 0) throw Exception('La cantidad debe ser mayor a 0');

    return _createMovement(
      itemId: itemId,
      quantity: quantity,
      type: MovementType.transfer,
      reason: reason,
      fromLocationId: fromLocationId,
      fromLocationName: fromLocationName,
      toLocationId: toLocationId,
      toLocationName: toLocationName,
      notes: notes,
    );
  }

  /// Registrar ajuste de inventario
  Future<String> registerAdjustment({
    required String itemId,
    required int newStock,
    required String reason,
    String? notes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Obtener item actual
      final itemDoc = await _itemsRef.doc(itemId).get();
      if (!itemDoc.exists) throw Exception('Item no encontrado');

      final item = InventoryItem.fromDoc(itemDoc);
      final currentStock = item.stock;
      final difference = newStock - currentStock;

      if (difference == 0) {
        throw Exception('El nuevo stock es igual al actual');
      }

      // Generar número de movimiento
      final movementNumber = await _generateMovementNumber();

      // Crear movimiento
      final movement = InventoryMovement(
        id: '',
        movementNumber: movementNumber,
        type: MovementType.adjustment,
        status: MovementStatus.completed,
        itemId: itemId,
        itemName: item.name,
        itemSku: item.sku,
        quantity: difference.abs(),
        previousStock: currentStock,
        newStock: newStock,
        reason: reason,
        notes: notes,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        createdBy: user.uid,
        createdByEmail: user.email,
      );

      // Ejecutar en transacción
      final docRef = await FirebaseHelper.db.runTransaction((
        transaction,
      ) async {
        // Actualizar stock del item
        transaction.update(_itemsRef.doc(itemId), {
          'stock': newStock,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastModifiedBy': user.uid,
        });

        // Crear movimiento
        final movementRef = _movementsRef.doc();
        transaction.set(movementRef, movement.toMap());

        return movementRef;
      });

      debugPrint('✅ Ajuste registrado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error registrando ajuste: $e');
      rethrow;
    }
  }

  /// Crear movimiento genérico (interno)
  Future<String> _createMovement({
    required String itemId,
    required int quantity,
    required MovementType type,
    required String reason,
    String? supplierId,
    String? supplierName,
    String? customerId,
    String? customerName,
    String? referenceNumber,
    String? batchNumber,
    DateTime? expirationDate,
    double? unitCost,
    String? fromLocationId,
    String? fromLocationName,
    String? toLocationId,
    String? toLocationName,
    String? notes,
    List<String>? attachmentUrls,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Obtener item actual
      final itemDoc = await _itemsRef.doc(itemId).get();
      if (!itemDoc.exists) throw Exception('Item no encontrado');

      final item = InventoryItem.fromDoc(itemDoc);
      final currentStock = item.stock;

      // Calcular nuevo stock
      int newStock;
      if (type.isIncoming) {
        newStock = currentStock + quantity;
      } else {
        newStock = currentStock - quantity;
        if (newStock < 0 && !item.allowBackorder) {
          throw Exception('Stock insuficiente. Disponible: $currentStock');
        }
      }

      // Generar número de movimiento
      final movementNumber = await _generateMovementNumber();

      // Crear movimiento
      final movement = InventoryMovement(
        id: '',
        movementNumber: movementNumber,
        type: type,
        status: MovementStatus.completed,
        itemId: itemId,
        itemName: item.name,
        itemSku: item.sku,
        quantity: quantity,
        previousStock: currentStock,
        newStock: newStock,
        fromLocationId: fromLocationId,
        fromLocationName: fromLocationName,
        toLocationId: toLocationId,
        toLocationName: toLocationName,
        unitCost: unitCost ?? item.purchasePrice,
        totalCost: (unitCost ?? item.purchasePrice) * quantity,
        currency: item.currency,
        referenceNumber: referenceNumber,
        supplierId: supplierId,
        supplierName: supplierName,
        customerId: customerId,
        customerName: customerName,
        batchNumber: batchNumber,
        expirationDate: expirationDate,
        reason: reason,
        notes: notes,
        attachmentUrls: attachmentUrls,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        createdBy: user.uid,
        createdByEmail: user.email,
      );

      // Ejecutar en transacción
      final docRef = await FirebaseHelper.db.runTransaction((
        transaction,
      ) async {
        // Actualizar stock del item
        final updateData = <String, dynamic>{
          'stock': newStock,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastModifiedBy': user.uid,
        };

        // Actualizar stock por ubicación si aplica
        if (type == MovementType.transfer) {
          // Para transferencias, actualizar stockByLocation
          final stockByLocation = Map<String, int>.from(
            item.stockByLocation ?? {},
          );

          if (fromLocationId != null) {
            stockByLocation[fromLocationId] =
                (stockByLocation[fromLocationId] ?? 0) - quantity;
          }
          if (toLocationId != null) {
            stockByLocation[toLocationId] =
                (stockByLocation[toLocationId] ?? 0) + quantity;
          }

          updateData['stockByLocation'] = stockByLocation;
        }

        transaction.update(_itemsRef.doc(itemId), updateData);

        // Crear movimiento
        final movementRef = _movementsRef.doc();
        transaction.set(movementRef, movement.toMap());

        return movementRef;
      });

      debugPrint('✅ Movimiento registrado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error registrando movimiento: $e');
      rethrow;
    }
  }

  /// Generar número de movimiento secuencial
  Future<String> _generateMovementNumber() async {
    final now = DateTime.now();
    final prefix = 'MOV-${now.year}';

    final counterRef = FirebaseHelper.inventoryCounters.doc('movement_$prefix');

    return FirebaseHelper.db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      int nextNumber = 1;

      if (snapshot.exists) {
        nextNumber = (snapshot.data()?['current'] ?? 0) + 1;
      }

      transaction.set(counterRef, {
        'current': nextNumber,
      }, SetOptions(merge: true));

      return '$prefix-${nextNumber.toString().padLeft(6, '0')}';
    });
  }

  // ═══════════════════════════════════════════════════════════
  // LEER MOVIMIENTOS
  // ═══════════════════════════════════════════════════════════

  /// Obtener movimiento por ID
  Future<InventoryMovement?> getMovementById(String id) async {
    try {
      final doc = await _movementsRef.doc(id).get();
      if (!doc.exists) return null;
      return InventoryMovement.fromDoc(doc);
    } catch (e) {
      debugPrint('❌ Error obteniendo movimiento: $e');
      rethrow;
    }
  }

  /// Stream de movimientos de un item
  Stream<List<InventoryMovement>> streamItemMovements(
    String itemId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _movementsRef
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(InventoryMovement.fromDoc).toList(),
    );
  }

  /// Stream de todos los movimientos
  Stream<List<InventoryMovement>> streamMovements({
    MovementType? type,
    MovementStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _movementsRef.orderBy(
      'createdAt',
      descending: true,
    );

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      var movements = snapshot.docs.map(InventoryMovement.fromDoc).toList();

      // Filtrar por fechas en cliente
      if (startDate != null) {
        movements = movements
            .where((m) => m.createdAt.isAfter(startDate))
            .toList();
      }
      if (endDate != null) {
        movements = movements
            .where((m) => m.createdAt.isBefore(endDate))
            .toList();
      }

      return movements;
    });
  }

  /// Obtener movimientos paginados
  Future<PaginatedMovements> getMovementsPaginated({
    String? itemId,
    MovementType? type,
    int pageSize = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _movementsRef.orderBy(
        'createdAt',
        descending: true,
      );

      if (itemId != null) {
        query = query.where('itemId', isEqualTo: itemId);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(pageSize + 1);

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final hasMore = docs.length > pageSize;
      final movementDocs = hasMore ? docs.take(pageSize).toList() : docs;

      return PaginatedMovements(
        movements: movementDocs.map(InventoryMovement.fromDoc).toList(),
        lastDocument: movementDocs.isNotEmpty ? movementDocs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      debugPrint('❌ Error en paginación de movimientos: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════

  /// Obtener resumen de movimientos
  Future<MovementSummary> getMovementSummary({
    String? itemId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _movementsRef;

      if (itemId != null) {
        query = query.where('itemId', isEqualTo: itemId);
      }

      final snapshot = await query.get();
      var movements = snapshot.docs.map(InventoryMovement.fromDoc).toList();

      // Filtrar por fechas
      if (startDate != null) {
        movements = movements
            .where((m) => m.createdAt.isAfter(startDate))
            .toList();
      }
      if (endDate != null) {
        movements = movements
            .where((m) => m.createdAt.isBefore(endDate))
            .toList();
      }

      int totalIn = 0;
      int totalOut = 0;
      double totalValueIn = 0;
      double totalValueOut = 0;

      for (final m in movements) {
        if (m.type.isIncoming) {
          totalIn += m.quantity;
          totalValueIn += m.totalCost ?? 0;
        } else {
          totalOut += m.quantity;
          totalValueOut += m.totalCost ?? 0;
        }
      }

      return MovementSummary(
        totalMovements: movements.length,
        totalIn: totalIn,
        totalOut: totalOut,
        netChange: totalIn - totalOut,
        totalValueIn: totalValueIn,
        totalValueOut: totalValueOut,
        movementsByType: _groupByType(movements),
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo resumen: $e');
      rethrow;
    }
  }

  Map<MovementType, int> _groupByType(List<InventoryMovement> movements) {
    final result = <MovementType, int>{};
    for (final m in movements) {
      result[m.type] = (result[m.type] ?? 0) + 1;
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // ANULAR MOVIMIENTO
  // ═══════════════════════════════════════════════════════════

  /// Anular movimiento (reversa)
  Future<String> reverseMovement(String movementId, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final originalMovement = await getMovementById(movementId);
      if (originalMovement == null) {
        throw Exception('Movimiento no encontrado');
      }

      if (originalMovement.status == MovementStatus.cancelled) {
        throw Exception('El movimiento ya fue cancelado');
      }

      // Crear movimiento inverso
      final reverseType = originalMovement.type.isIncoming
          ? MovementType
                .adjustment // Salida para compensar entrada
          : MovementType.adjustment; // Entrada para compensar salida

      // Registrar el movimiento inverso
      final reverseId = await _createMovement(
        itemId: originalMovement.itemId,
        quantity: originalMovement.quantity,
        type: reverseType,
        reason:
            'REVERSA: $reason (Original: ${originalMovement.movementNumber})',
        notes: 'Movimiento de reversa para ${originalMovement.movementNumber}',
      );

      // Marcar movimiento original como cancelado
      await _movementsRef.doc(movementId).update({
        'status': MovementStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'notes': '${originalMovement.notes ?? ""}\n[ANULADO: $reason]',
      });

      debugPrint('✅ Movimiento revertido: $reverseId');
      return reverseId;
    } catch (e) {
      debugPrint('❌ Error revirtiendo movimiento: $e');
      rethrow;
    }
  }
}

/// Resultado paginado de movimientos
class PaginatedMovements {
  final List<InventoryMovement> movements;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedMovements({
    required this.movements,
    this.lastDocument,
    this.hasMore = false,
  });
}

/// Resumen de movimientos
class MovementSummary {
  final int totalMovements;
  final int totalIn;
  final int totalOut;
  final int netChange;
  final double totalValueIn;
  final double totalValueOut;
  final Map<MovementType, int> movementsByType;

  MovementSummary({
    required this.totalMovements,
    required this.totalIn,
    required this.totalOut,
    required this.netChange,
    required this.totalValueIn,
    required this.totalValueOut,
    required this.movementsByType,
  });

  double get netValue => totalValueIn - totalValueOut;
}
