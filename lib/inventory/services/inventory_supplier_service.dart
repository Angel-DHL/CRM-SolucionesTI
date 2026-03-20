// lib/inventory/services/inventory_supplier_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase_helper.dart';
import '../models/inventory_supplier.dart';

/// Filtros para búsqueda de proveedores
class SupplierFilters {
  final String? searchQuery;
  final SupplierType? type;
  final SupplierStatus? status;
  final bool? isPreferred;
  final String? country;
  final String? state;
  final String? city;
  final List<String>? categoryIds;
  final double? minRating;
  final PaymentTerms? paymentTerms;
  final String? sortBy;
  final bool sortDescending;

  const SupplierFilters({
    this.searchQuery,
    this.type,
    this.status,
    this.isPreferred,
    this.country,
    this.state,
    this.city,
    this.categoryIds,
    this.minRating,
    this.paymentTerms,
    this.sortBy,
    this.sortDescending = false,
  });

  static const SupplierFilters none = SupplierFilters();

  bool get hasFilters =>
      searchQuery != null ||
      type != null ||
      status != null ||
      isPreferred != null ||
      country != null ||
      state != null ||
      city != null ||
      (categoryIds != null && categoryIds!.isNotEmpty) ||
      minRating != null ||
      paymentTerms != null;

  SupplierFilters copyWith({
    String? searchQuery,
    SupplierType? type,
    SupplierStatus? status,
    bool? isPreferred,
    String? country,
    String? state,
    String? city,
    List<String>? categoryIds,
    double? minRating,
    PaymentTerms? paymentTerms,
    String? sortBy,
    bool? sortDescending,
  }) {
    return SupplierFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      type: type ?? this.type,
      status: status ?? this.status,
      isPreferred: isPreferred ?? this.isPreferred,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      categoryIds: categoryIds ?? this.categoryIds,
      minRating: minRating ?? this.minRating,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }
}

class InventorySupplierService {
  InventorySupplierService._();
  static final InventorySupplierService instance = InventorySupplierService._();

  CollectionReference<Map<String, dynamic>> get _suppliersRef =>
      FirebaseHelper.inventorySuppliers;

  // ═══════════════════════════════════════════════════════════
  // CREAR PROVEEDOR
  // ═══════════════════════════════════════════════════════════

  /// Crear nuevo proveedor
  Future<String> createSupplier(InventorySupplier supplier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Generar código único si no existe
      String code = supplier.code;
      if (code.isEmpty) {
        code = await _generateSupplierCode();
      }

      // Verificar que el código no exista
      final existing = await _suppliersRef
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('El código "$code" ya existe');
      }

      // Verificar email único
      final existingEmail = await _suppliersRef
          .where('email', isEqualTo: supplier.email)
          .limit(1)
          .get();
      if (existingEmail.docs.isNotEmpty) {
        throw Exception('Ya existe un proveedor con este email');
      }

      // Preparar datos
      final data = supplier
          .copyWith(code: code, createdBy: user.uid, lastModifiedBy: user.uid)
          .toMap();

      final docRef = await _suppliersRef.add(data);

      await _logAudit(
        action: 'create',
        supplierId: docRef.id,
        supplierName: supplier.name,
        details: 'Proveedor creado: ${supplier.name} ($code)',
      );

      debugPrint('✅ Proveedor creado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creando proveedor: $e');
      rethrow;
    }
  }

  /// Generar código de proveedor secuencial
  Future<String> _generateSupplierCode() async {
    final counterRef = FirebaseHelper.inventoryCounters.doc('supplier_code');

    return FirebaseHelper.db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      int nextNumber = 1;

      if (snapshot.exists) {
        nextNumber = (snapshot.data()?['current'] ?? 0) + 1;
      }

      transaction.set(counterRef, {
        'current': nextNumber,
      }, SetOptions(merge: true));

      return 'PRV-${nextNumber.toString().padLeft(5, '0')}';
    });
  }

  // ═══════════════════════════════════════════════════════════
  // LEER PROVEEDORES
  // ═══════════════════════════════════════════════════════════

  /// Obtener proveedor por ID
  Future<InventorySupplier?> getSupplierById(String id) async {
    try {
      final doc = await _suppliersRef.doc(id).get();
      if (!doc.exists) return null;
      return InventorySupplier.fromDoc(doc);
    } catch (e) {
      debugPrint('❌ Error obteniendo proveedor: $e');
      rethrow;
    }
  }

  /// Obtener proveedor por código
  Future<InventorySupplier?> getSupplierByCode(String code) async {
    try {
      final snapshot = await _suppliersRef
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return InventorySupplier.fromDoc(snapshot.docs.first);
    } catch (e) {
      debugPrint('❌ Error obteniendo proveedor por código: $e');
      rethrow;
    }
  }

  /// Stream de un proveedor específico
  Stream<InventorySupplier?> streamSupplier(String id) {
    return _suppliersRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InventorySupplier.fromDoc(doc);
    });
  }

  /// Stream de todos los proveedores con filtros
  Stream<List<InventorySupplier>> streamSuppliers({
    SupplierFilters filters = SupplierFilters.none,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _suppliersRef;

    // Filtros de Firestore
    if (filters.status != null) {
      query = query.where('status', isEqualTo: filters.status!.name);
    }
    if (filters.type != null) {
      query = query.where('type', isEqualTo: filters.type!.name);
    }
    if (filters.isPreferred != null) {
      query = query.where('isPreferred', isEqualTo: filters.isPreferred);
    }

    // Ordenamiento
    final sortField = filters.sortBy ?? 'name';
    query = query.orderBy(sortField, descending: filters.sortDescending);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      var suppliers = snapshot.docs.map(InventorySupplier.fromDoc).toList();
      suppliers = _applyClientFilters(suppliers, filters);
      return suppliers;
    });
  }

  /// Stream de proveedores activos
  Stream<List<InventorySupplier>> streamActiveSuppliers() {
    return streamSuppliers(
      filters: const SupplierFilters(status: SupplierStatus.active),
    );
  }

  /// Stream de proveedores preferidos
  Stream<List<InventorySupplier>> streamPreferredSuppliers() {
    return streamSuppliers(
      filters: const SupplierFilters(
        status: SupplierStatus.active,
        isPreferred: true,
      ),
    );
  }

  /// Stream de proveedores por categoría
  Stream<List<InventorySupplier>> streamSuppliersByCategory(String categoryId) {
    return _suppliersRef
        .where('categoryIds', arrayContains: categoryId)
        .where('status', isEqualTo: SupplierStatus.active.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(InventorySupplier.fromDoc).toList(),
        );
  }

  /// Aplicar filtros en cliente
  List<InventorySupplier> _applyClientFilters(
    List<InventorySupplier> suppliers,
    SupplierFilters filters,
  ) {
    var filtered = suppliers;

    // Búsqueda por texto
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase();
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.code.toLowerCase().contains(query) ||
            s.email.toLowerCase().contains(query) ||
            (s.tradeName?.toLowerCase().contains(query) ?? false) ||
            (s.taxId?.toLowerCase().contains(query) ?? false) ||
            (s.contactName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filtros geográficos
    if (filters.country != null) {
      filtered = filtered
          .where(
            (s) => s.country?.toLowerCase() == filters.country!.toLowerCase(),
          )
          .toList();
    }
    if (filters.state != null) {
      filtered = filtered
          .where((s) => s.state?.toLowerCase() == filters.state!.toLowerCase())
          .toList();
    }
    if (filters.city != null) {
      filtered = filtered
          .where((s) => s.city?.toLowerCase() == filters.city!.toLowerCase())
          .toList();
    }

    // Filtro por categorías
    if (filters.categoryIds != null && filters.categoryIds!.isNotEmpty) {
      filtered = filtered.where((s) {
        if (s.categoryIds == null) return false;
        return filters.categoryIds!.any(
          (catId) => s.categoryIds!.contains(catId),
        );
      }).toList();
    }

    // Filtro por rating mínimo
    if (filters.minRating != null) {
      filtered = filtered
          .where((s) => (s.rating ?? 0) >= filters.minRating!)
          .toList();
    }

    // Filtro por términos de pago
    if (filters.paymentTerms != null) {
      filtered = filtered
          .where((s) => s.paymentTerms == filters.paymentTerms)
          .toList();
    }

    return filtered;
  }

  /// Obtener proveedores paginados
  Future<PaginatedSuppliers> getSuppliersPaginated({
    SupplierFilters filters = SupplierFilters.none,
    int pageSize = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _suppliersRef;

      if (filters.status != null) {
        query = query.where('status', isEqualTo: filters.status!.name);
      }
      if (filters.type != null) {
        query = query.where('type', isEqualTo: filters.type!.name);
      }

      final sortField = filters.sortBy ?? 'name';
      query = query.orderBy(sortField, descending: filters.sortDescending);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(pageSize + 1);

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final hasMore = docs.length > pageSize;
      final supplierDocs = hasMore ? docs.take(pageSize).toList() : docs;

      var suppliers = supplierDocs.map(InventorySupplier.fromDoc).toList();
      suppliers = _applyClientFilters(suppliers, filters);

      return PaginatedSuppliers(
        suppliers: suppliers,
        lastDocument: supplierDocs.isNotEmpty ? supplierDocs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      debugPrint('❌ Error en paginación de proveedores: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ACTUALIZAR PROVEEDOR
  // ═══════════════════════════════════════════════════════════

  /// Actualizar proveedor completo
  Future<void> updateSupplier(InventorySupplier supplier) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Obtener datos anteriores
      final previousDoc = await _suppliersRef.doc(supplier.id).get();
      final previousSupplier = previousDoc.exists
          ? InventorySupplier.fromDoc(previousDoc)
          : null;

      final data = {
        ...supplier.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': user.uid,
      };
      data.remove('createdAt');

      await _suppliersRef.doc(supplier.id).update(data);

      await _logAudit(
        action: 'update',
        supplierId: supplier.id,
        supplierName: supplier.name,
        details: 'Proveedor actualizado: ${supplier.name}',
        previousData: previousSupplier?.toMap(),
        newData: supplier.toMap(),
      );

      debugPrint('✅ Proveedor actualizado: ${supplier.id}');
    } catch (e) {
      debugPrint('❌ Error actualizando proveedor: $e');
      rethrow;
    }
  }

  /// Actualizar campos específicos
  Future<void> updateSupplierFields(
    String supplierId,
    Map<String, dynamic> fields,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      fields['updatedAt'] = FieldValue.serverTimestamp();
      fields['lastModifiedBy'] = user.uid;

      await _suppliersRef.doc(supplierId).update(fields);

      await _logAudit(
        action: 'update_fields',
        supplierId: supplierId,
        details: 'Campos actualizados: ${fields.keys.join(", ")}',
      );

      debugPrint('✅ Campos actualizados: $supplierId');
    } catch (e) {
      debugPrint('❌ Error actualizando campos: $e');
      rethrow;
    }
  }

  /// Cambiar estado del proveedor
  Future<void> updateStatus(String supplierId, SupplierStatus status) async {
    await updateSupplierFields(supplierId, {'status': status.name});
  }

  /// Marcar como preferido
  Future<void> togglePreferred(String supplierId, bool isPreferred) async {
    await updateSupplierFields(supplierId, {'isPreferred': isPreferred});
  }

  /// Actualizar calificación
  Future<void> updateRating(String supplierId, double rating) async {
    if (rating < 0 || rating > 5) {
      throw Exception('La calificación debe estar entre 0 y 5');
    }
    await updateSupplierFields(supplierId, {'rating': rating});
  }

  /// Registrar orden completada (actualiza estadísticas)
  Future<void> recordCompletedOrder(
    String supplierId, {
    required bool onTime,
    required bool qualityOk,
  }) async {
    final supplier = await getSupplierById(supplierId);
    if (supplier == null) throw Exception('Proveedor no encontrado');

    final newTotalOrders = (supplier.totalOrders ?? 0) + 1;
    final newCompletedOrders = (supplier.completedOrders ?? 0) + 1;

    // Calcular nuevas tasas
    double newOnTimeRate = supplier.onTimeDeliveryRate ?? 100;
    double newQualityRate = supplier.qualityRate ?? 100;

    if (onTime) {
      // Mantener o mejorar tasa
      newOnTimeRate =
          ((newOnTimeRate * (newTotalOrders - 1)) + 100) / newTotalOrders;
    } else {
      newOnTimeRate =
          ((newOnTimeRate * (newTotalOrders - 1)) + 0) / newTotalOrders;
    }

    if (qualityOk) {
      newQualityRate =
          ((newQualityRate * (newTotalOrders - 1)) + 100) / newTotalOrders;
    } else {
      newQualityRate =
          ((newQualityRate * (newTotalOrders - 1)) + 0) / newTotalOrders;
    }

    await updateSupplierFields(supplierId, {
      'totalOrders': newTotalOrders,
      'completedOrders': newCompletedOrders,
      'onTimeDeliveryRate': newOnTimeRate,
      'qualityRate': newQualityRate,
      'lastOrderDate': FieldValue.serverTimestamp(),
    });
  }

  /// Registrar orden cancelada
  Future<void> recordCancelledOrder(String supplierId) async {
    await updateSupplierFields(supplierId, {
      'totalOrders': FieldValue.increment(1),
      'cancelledOrders': FieldValue.increment(1),
    });
  }

  // ═══════════════════════════════════════════════════════════
  // ELIMINAR PROVEEDOR
  // ═══════════════════════════════════════════════════════════

  /// Verificar si se puede eliminar
  Future<bool> canDeleteSupplier(String supplierId) async {
    // Verificar si tiene productos asociados
    final products = await FirebaseHelper.inventoryItems
        .where('primarySupplierId', isEqualTo: supplierId)
        .limit(1)
        .get();

    return products.docs.isEmpty;
  }

  /// Suspender proveedor (soft delete)
  Future<void> suspendSupplier(String supplierId, {String? reason}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    await _suppliersRef.doc(supplierId).update({
      'status': SupplierStatus.suspended.name,
      'internalNotes': FieldValue.arrayUnion([
        '[${DateTime.now().toIso8601String()}] Suspendido: ${reason ?? "Sin razón especificada"}',
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': user.uid,
    });

    await _logAudit(
      action: 'suspend',
      supplierId: supplierId,
      details: 'Proveedor suspendido: $reason',
    );

    debugPrint('✅ Proveedor suspendido: $supplierId');
  }

  /// Reactivar proveedor
  Future<void> reactivateSupplier(String supplierId) async {
    await updateStatus(supplierId, SupplierStatus.active);

    await _logAudit(
      action: 'reactivate',
      supplierId: supplierId,
      details: 'Proveedor reactivado',
    );
  }

  /// Eliminar proveedor permanentemente
  Future<void> deleteSupplier(String supplierId) async {
    if (!await canDeleteSupplier(supplierId)) {
      throw Exception(
        'No se puede eliminar: el proveedor tiene productos asociados',
      );
    }

    try {
      final supplier = await getSupplierById(supplierId);

      await _suppliersRef.doc(supplierId).delete();

      await _logAudit(
        action: 'delete',
        supplierId: supplierId,
        supplierName: supplier?.name,
        details: 'Proveedor eliminado permanentemente',
        previousData: supplier?.toMap(),
      );

      debugPrint('✅ Proveedor eliminado: $supplierId');
    } catch (e) {
      debugPrint('❌ Error eliminando proveedor: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CONTACTOS
  // ═══════════════════════════════════════════════════════════

  /// Agregar contacto adicional
  Future<void> addContact(String supplierId, SupplierContact contact) async {
    await _suppliersRef.doc(supplierId).update({
      'additionalContacts': FieldValue.arrayUnion([contact.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Eliminar contacto adicional
  Future<void> removeContact(String supplierId, SupplierContact contact) async {
    await _suppliersRef.doc(supplierId).update({
      'additionalContacts': FieldValue.arrayRemove([contact.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════

  /// Obtener estadísticas de proveedores
  Future<SupplierStats> getStats() async {
    try {
      final snapshot = await _suppliersRef.get();
      final suppliers = snapshot.docs.map(InventorySupplier.fromDoc).toList();

      final active = suppliers
          .where((s) => s.status == SupplierStatus.active)
          .toList();
      final preferred = active.where((s) => s.isPreferred).toList();

      double avgRating = 0;
      int ratedCount = 0;
      for (final s in active) {
        if (s.rating != null && s.rating! > 0) {
          avgRating += s.rating!;
          ratedCount++;
        }
      }
      avgRating = ratedCount > 0 ? avgRating / ratedCount : 0;

      double avgOnTime = 0;
      int onTimeCount = 0;
      for (final s in active) {
        if (s.onTimeDeliveryRate != null) {
          avgOnTime += s.onTimeDeliveryRate!;
          onTimeCount++;
        }
      }
      avgOnTime = onTimeCount > 0 ? avgOnTime / onTimeCount : 0;

      // Agrupar por tipo
      final byType = <SupplierType, int>{};
      for (final s in active) {
        byType[s.type] = (byType[s.type] ?? 0) + 1;
      }

      return SupplierStats(
        totalSuppliers: suppliers.length,
        activeSuppliers: active.length,
        preferredSuppliers: preferred.length,
        suspendedSuppliers: suppliers
            .where((s) => s.status == SupplierStatus.suspended)
            .length,
        averageRating: avgRating,
        averageOnTimeDelivery: avgOnTime,
        suppliersByType: byType,
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  /// Obtener top proveedores por rating
  Future<List<InventorySupplier>> getTopRatedSuppliers({int limit = 10}) async {
    final snapshot = await _suppliersRef
        .where('status', isEqualTo: SupplierStatus.active.name)
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map(InventorySupplier.fromDoc).toList();
  }

  /// Obtener proveedores con mejor tiempo de entrega
  Future<List<InventorySupplier>> getTopPerformingSuppliers({
    int limit = 10,
  }) async {
    final snapshot = await _suppliersRef
        .where('status', isEqualTo: SupplierStatus.active.name)
        .orderBy('onTimeDeliveryRate', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map(InventorySupplier.fromDoc).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // VALIDACIONES
  // ═══════════════════════════════════════════════════════════

  /// Validar proveedor antes de guardar
  List<String> validateSupplier(InventorySupplier supplier) {
    final errors = <String>[];

    if (supplier.name.trim().isEmpty) {
      errors.add('El nombre es requerido');
    }
    if (supplier.name.length > 200) {
      errors.add('El nombre no puede exceder 200 caracteres');
    }
    if (supplier.email.trim().isEmpty) {
      errors.add('El email es requerido');
    }
    if (!_isValidEmail(supplier.email)) {
      errors.add('El email no es válido');
    }
    if (supplier.taxId != null && supplier.taxId!.length > 20) {
      errors.add('El RFC/NIT no puede exceder 20 caracteres');
    }
    if (supplier.creditLimit != null && supplier.creditLimit! < 0) {
      errors.add('El límite de crédito no puede ser negativo');
    }

    return errors;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA
  // ═══════════════════════════════════════════════════════════

  Future<void> _logAudit({
    required String action,
    String? supplierId,
    String? supplierName,
    String? details,
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? newData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseHelper.inventoryAuditLogs.add({
        'module': 'suppliers',
        'action': action,
        'entityId': supplierId,
        'entityName': supplierName,
        'details': details,
        'previousData': previousData,
        'newData': newData,
        'userId': user?.uid,
        'userEmail': user?.email,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Error registrando auditoría: $e');
    }
  }
}

/// Resultado paginado de proveedores
class PaginatedSuppliers {
  final List<InventorySupplier> suppliers;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedSuppliers({
    required this.suppliers,
    this.lastDocument,
    this.hasMore = false,
  });
}

/// Estadísticas de proveedores
class SupplierStats {
  final int totalSuppliers;
  final int activeSuppliers;
  final int preferredSuppliers;
  final int suspendedSuppliers;
  final double averageRating;
  final double averageOnTimeDelivery;
  final Map<SupplierType, int> suppliersByType;

  SupplierStats({
    required this.totalSuppliers,
    required this.activeSuppliers,
    required this.preferredSuppliers,
    required this.suspendedSuppliers,
    required this.averageRating,
    required this.averageOnTimeDelivery,
    required this.suppliersByType,
  });
}
