// lib/inventory/services/inventory_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase_helper.dart';
import '../models/inventory_enums.dart';
import '../models/inventory_item.dart';

/// Filtros para búsqueda de inventario
class InventoryFilters {
  final String? searchQuery;
  final InventoryItemType? type;
  final InventoryItemStatus? status;
  final String? categoryId;
  final String? subcategoryId;
  final String? locationId;
  final String? supplierId;
  final bool? isStockLow;
  final bool? isActive;
  final bool? isFeatured;
  final double? minPrice;
  final double? maxPrice;
  final int? minStock;
  final int? maxStock;
  final List<String>? tags;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final String? sortBy;
  final bool sortDescending;

  const InventoryFilters({
    this.searchQuery,
    this.type,
    this.status,
    this.categoryId,
    this.subcategoryId,
    this.locationId,
    this.supplierId,
    this.isStockLow,
    this.isActive,
    this.isFeatured,
    this.minPrice,
    this.maxPrice,
    this.minStock,
    this.maxStock,
    this.tags,
    this.createdAfter,
    this.createdBefore,
    this.sortBy,
    this.sortDescending = false,
  });

  /// Sin filtros
  static const InventoryFilters none = InventoryFilters();

  /// Tiene filtros activos
  bool get hasFilters =>
      searchQuery != null ||
      type != null ||
      status != null ||
      categoryId != null ||
      subcategoryId != null ||
      locationId != null ||
      supplierId != null ||
      isStockLow != null ||
      isActive != null ||
      isFeatured != null ||
      minPrice != null ||
      maxPrice != null ||
      minStock != null ||
      maxStock != null ||
      (tags != null && tags!.isNotEmpty) ||
      createdAfter != null ||
      createdBefore != null;

  /// Copiar con modificaciones
  InventoryFilters copyWith({
    String? searchQuery,
    InventoryItemType? type,
    InventoryItemStatus? status,
    String? categoryId,
    String? subcategoryId,
    String? locationId,
    String? supplierId,
    bool? isStockLow,
    bool? isActive,
    bool? isFeatured,
    double? minPrice,
    double? maxPrice,
    int? minStock,
    int? maxStock,
    List<String>? tags,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? sortBy,
    bool? sortDescending,
  }) {
    return InventoryFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      type: type ?? this.type,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      locationId: locationId ?? this.locationId,
      supplierId: supplierId ?? this.supplierId,
      isStockLow: isStockLow ?? this.isStockLow,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      tags: tags ?? this.tags,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }
}

/// Resultado paginado
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int totalCount;

  PaginatedResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
    this.totalCount = 0,
  });
}

/// Servicio principal de inventario
class InventoryService {
  InventoryService._();
  static final InventoryService instance = InventoryService._();

  // Referencias
  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      FirebaseHelper.inventoryItems;

  // ═══════════════════════════════════════════════════════════
  // CREAR ITEM
  // ═══════════════════════════════════════════════════════════

  /// Crear nuevo item de inventario
  Future<String> createItem(InventoryItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Generar SKU único si no se proporciona
      String sku = item.sku;
      if (sku.isEmpty) {
        sku = await _generateSku(item.type);
      }

      // Verificar que el SKU no exista
      final existing = await _itemsRef
          .where('sku', isEqualTo: sku)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('El SKU "$sku" ya existe');
      }

      // Preparar datos
      final data = item
          .copyWith(sku: sku, createdBy: user.uid, lastModifiedBy: user.uid)
          .toMap();

      // Crear documento
      final docRef = await _itemsRef.add(data);

      // Actualizar contador de categoría
      await _updateCategoryItemCount(item.categoryId, 1);

      // Log de auditoría
      await _logAudit(
        action: 'create',
        itemId: docRef.id,
        itemName: item.name,
        details: 'Item creado: ${item.name} (SKU: $sku)',
      );

      debugPrint('✅ Item creado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creando item: $e');
      rethrow;
    }
  }

  /// Generar SKU automático
  Future<String> _generateSku(InventoryItemType type) async {
    final prefix = switch (type) {
      InventoryItemType.product => 'PRD',
      InventoryItemType.service => 'SRV',
      InventoryItemType.asset => 'AST',
    };

    // Obtener siguiente número
    final counterRef = FirebaseHelper.inventoryCounters.doc('sku_$prefix');

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
  // LEER ITEMS
  // ═══════════════════════════════════════════════════════════

  /// Obtener item por ID
  Future<InventoryItem?> getItemById(String id) async {
    try {
      final doc = await _itemsRef.doc(id).get();
      if (!doc.exists) return null;
      return InventoryItem.fromDoc(doc);
    } catch (e) {
      debugPrint('❌ Error obteniendo item: $e');
      rethrow;
    }
  }

  /// Stream de un item específico
  Stream<InventoryItem?> streamItem(String id) {
    return _itemsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InventoryItem.fromDoc(doc);
    });
  }

  /// Stream de todos los items con filtros
  Stream<List<InventoryItem>> streamItems({
    InventoryFilters filters = InventoryFilters.none,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _itemsRef;

    // Aplicar filtros de Firestore (solo los que soporta)
    if (filters.type != null) {
      query = query.where('type', isEqualTo: filters.type!.name);
    }
    if (filters.status != null) {
      query = query.where('status', isEqualTo: filters.status!.name);
    }
    if (filters.categoryId != null) {
      query = query.where('categoryId', isEqualTo: filters.categoryId);
    }
    if (filters.isActive != null) {
      query = query.where('isActive', isEqualTo: filters.isActive);
    }
    if (filters.isFeatured != null) {
      query = query.where('isFeatured', isEqualTo: filters.isFeatured);
    }

    // Ordenamiento
    final sortField = filters.sortBy ?? 'createdAt';
    query = query.orderBy(sortField, descending: filters.sortDescending);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      var items = snapshot.docs.map(InventoryItem.fromDoc).toList();

      // Aplicar filtros adicionales en cliente
      items = _applyClientFilters(items, filters);

      return items;
    });
  }

  /// Obtener items paginados
  Future<PaginatedResult<InventoryItem>> getItemsPaginated({
    InventoryFilters filters = InventoryFilters.none,
    int pageSize = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _itemsRef;

      // Aplicar filtros de Firestore
      if (filters.type != null) {
        query = query.where('type', isEqualTo: filters.type!.name);
      }
      if (filters.status != null) {
        query = query.where('status', isEqualTo: filters.status!.name);
      }
      if (filters.categoryId != null) {
        query = query.where('categoryId', isEqualTo: filters.categoryId);
      }
      if (filters.isActive != null) {
        query = query.where('isActive', isEqualTo: filters.isActive);
      }

      // Ordenamiento
      final sortField = filters.sortBy ?? 'createdAt';
      query = query.orderBy(sortField, descending: filters.sortDescending);

      // Paginación
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(pageSize + 1); // +1 para saber si hay más

      final snapshot = await query.get();
      final docs = snapshot.docs;

      final hasMore = docs.length > pageSize;
      final itemDocs = hasMore ? docs.take(pageSize).toList() : docs;

      var items = itemDocs.map(InventoryItem.fromDoc).toList();

      // Aplicar filtros adicionales en cliente
      items = _applyClientFilters(items, filters);

      return PaginatedResult(
        items: items,
        lastDocument: itemDocs.isNotEmpty ? itemDocs.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      debugPrint('❌ Error en paginación: $e');
      rethrow;
    }
  }

  /// Aplicar filtros en cliente (los que Firestore no soporta directamente)
  List<InventoryItem> _applyClientFilters(
    List<InventoryItem> items,
    InventoryFilters filters,
  ) {
    var filtered = items;

    // Búsqueda por texto
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase();
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.sku.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            (item.barcode?.toLowerCase().contains(query) ?? false) ||
            (item.brand?.toLowerCase().contains(query) ?? false) ||
            (item.model?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Subcategoría
    if (filters.subcategoryId != null) {
      filtered = filtered
          .where((item) => item.subcategoryId == filters.subcategoryId)
          .toList();
    }

    // Ubicación
    if (filters.locationId != null) {
      filtered = filtered
          .where((item) => item.defaultLocationId == filters.locationId)
          .toList();
    }

    // Proveedor
    if (filters.supplierId != null) {
      filtered = filtered
          .where((item) => item.primarySupplierId == filters.supplierId)
          .toList();
    }

    // Stock bajo
    if (filters.isStockLow == true) {
      filtered = filtered.where((item) => item.isStockLow).toList();
    }

    // Rango de precios
    if (filters.minPrice != null) {
      filtered = filtered
          .where((item) => item.sellingPrice >= filters.minPrice!)
          .toList();
    }
    if (filters.maxPrice != null) {
      filtered = filtered
          .where((item) => item.sellingPrice <= filters.maxPrice!)
          .toList();
    }

    // Rango de stock
    if (filters.minStock != null) {
      filtered = filtered
          .where((item) => item.stock >= filters.minStock!)
          .toList();
    }
    if (filters.maxStock != null) {
      filtered = filtered
          .where((item) => item.stock <= filters.maxStock!)
          .toList();
    }

    // Tags
    if (filters.tags != null && filters.tags!.isNotEmpty) {
      filtered = filtered.where((item) {
        return filters.tags!.any((tag) => item.tags.contains(tag));
      }).toList();
    }

    // Rango de fechas
    if (filters.createdAfter != null) {
      filtered = filtered
          .where((item) => item.createdAt.isAfter(filters.createdAfter!))
          .toList();
    }
    if (filters.createdBefore != null) {
      filtered = filtered
          .where((item) => item.createdAt.isBefore(filters.createdBefore!))
          .toList();
    }

    return filtered;
  }

  // ═══════════════════════════════════════════════════════════
  // ACTUALIZAR ITEM
  // ═══════════════════════════════════════════════════════════

  /// Actualizar item completo
  Future<void> updateItem(InventoryItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Obtener item anterior para comparar
      final previousDoc = await _itemsRef.doc(item.id).get();
      final previousItem = previousDoc.exists
          ? InventoryItem.fromDoc(previousDoc)
          : null;

      // Preparar datos de actualización
      final data = {
        ...item.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': user.uid,
      };

      // No sobrescribir createdAt
      data.remove('createdAt');

      await _itemsRef.doc(item.id).update(data);

      // Si cambió la categoría, actualizar contadores
      if (previousItem != null && previousItem.categoryId != item.categoryId) {
        await _updateCategoryItemCount(previousItem.categoryId, -1);
        await _updateCategoryItemCount(item.categoryId, 1);
      }

      // Log de auditoría
      await _logAudit(
        action: 'update',
        itemId: item.id,
        itemName: item.name,
        details: 'Item actualizado: ${item.name}',
        previousData: previousItem?.toMap(),
        newData: item.toMap(),
      );

      debugPrint('✅ Item actualizado: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error actualizando item: $e');
      rethrow;
    }
  }

  /// Actualizar campos específicos
  Future<void> updateItemFields(
    String itemId,
    Map<String, dynamic> fields,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      fields['updatedAt'] = FieldValue.serverTimestamp();
      fields['lastModifiedBy'] = user.uid;

      await _itemsRef.doc(itemId).update(fields);

      await _logAudit(
        action: 'update_fields',
        itemId: itemId,
        details: 'Campos actualizados: ${fields.keys.join(", ")}',
      );

      debugPrint('✅ Campos actualizados: $itemId');
    } catch (e) {
      debugPrint('❌ Error actualizando campos: $e');
      rethrow;
    }
  }

  /// Actualizar stock directamente (sin movimiento)
  Future<void> updateStock(String itemId, int newStock) async {
    await updateItemFields(itemId, {'stock': newStock});
  }

  /// Cambiar estado del item
  Future<void> updateStatus(String itemId, InventoryItemStatus status) async {
    await updateItemFields(itemId, {'status': status.name});
  }

  /// Marcar como activo/inactivo
  Future<void> toggleActive(String itemId, bool isActive) async {
    await updateItemFields(itemId, {'isActive': isActive});
  }

  /// Marcar como destacado
  Future<void> toggleFeatured(String itemId, bool isFeatured) async {
    await updateItemFields(itemId, {'isFeatured': isFeatured});
  }

  // ��══════════════════════════════════════════════════════════
  // ELIMINAR ITEM
  // ═══════════════════════════════════════════════════════════

  /// Eliminar item (soft delete - cambia status a inactive)
  Future<void> softDeleteItem(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final doc = await _itemsRef.doc(itemId).get();
      if (!doc.exists) throw Exception('Item no encontrado');

      final item = InventoryItem.fromDoc(doc);

      await _itemsRef.doc(itemId).update({
        'status': InventoryItemStatus.discontinued.name,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': user.uid,
      });

      await _logAudit(
        action: 'soft_delete',
        itemId: itemId,
        itemName: item.name,
        details: 'Item desactivado: ${item.name}',
      );

      debugPrint('✅ Item desactivado: $itemId');
    } catch (e) {
      debugPrint('❌ Error desactivando item: $e');
      rethrow;
    }
  }

  /// Eliminar item permanentemente
  Future<void> hardDeleteItem(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final doc = await _itemsRef.doc(itemId).get();
      if (!doc.exists) throw Exception('Item no encontrado');

      final item = InventoryItem.fromDoc(doc);

      // Eliminar imágenes asociadas
      // TODO: Implementar con InventoryStorageService

      // Eliminar documento
      await _itemsRef.doc(itemId).delete();

      // Actualizar contador de categoría
      await _updateCategoryItemCount(item.categoryId, -1);

      await _logAudit(
        action: 'hard_delete',
        itemId: itemId,
        itemName: item.name,
        details: 'Item eliminado permanentemente: ${item.name}',
        previousData: item.toMap(),
      );

      debugPrint('✅ Item eliminado permanentemente: $itemId');
    } catch (e) {
      debugPrint('❌ Error eliminando item: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // OPERACIONES EN LOTE
  // ═══════════════════════════════════════════════════════════

  /// Actualizar múltiples items
  Future<void> batchUpdate(
    List<String> itemIds,
    Map<String, dynamic> fields,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final batch = FirebaseHelper.db.batch();

      fields['updatedAt'] = FieldValue.serverTimestamp();
      fields['lastModifiedBy'] = user.uid;

      for (final id in itemIds) {
        batch.update(_itemsRef.doc(id), fields);
      }

      await batch.commit();

      await _logAudit(
        action: 'batch_update',
        details: 'Actualización masiva de ${itemIds.length} items',
      );

      debugPrint('✅ ${itemIds.length} items actualizados');
    } catch (e) {
      debugPrint('❌ Error en actualización masiva: $e');
      rethrow;
    }
  }

  /// Eliminar múltiples items (soft delete)
  Future<void> batchSoftDelete(List<String> itemIds) async {
    await batchUpdate(itemIds, {
      'status': InventoryItemStatus.discontinued.name,
      'isActive': false,
    });
  }

  /// Cambiar categoría de múltiples items
  Future<void> batchChangeCategory(
    List<String> itemIds,
    String newCategoryId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Obtener categorías anteriores para actualizar contadores
      final Map<String, int> categoryChanges = {};

      for (final id in itemIds) {
        final doc = await _itemsRef.doc(id).get();
        if (doc.exists) {
          final oldCategory = doc.data()?['categoryId'] as String?;
          if (oldCategory != null && oldCategory != newCategoryId) {
            categoryChanges[oldCategory] =
                (categoryChanges[oldCategory] ?? 0) - 1;
            categoryChanges[newCategoryId] =
                (categoryChanges[newCategoryId] ?? 0) + 1;
          }
        }
      }

      // Actualizar items
      await batchUpdate(itemIds, {'categoryId': newCategoryId});

      // Actualizar contadores de categorías
      for (final entry in categoryChanges.entries) {
        await _updateCategoryItemCount(entry.key, entry.value);
      }

      debugPrint('✅ Categoría actualizada para ${itemIds.length} items');
    } catch (e) {
      debugPrint('❌ Error cambiando categoría: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BÚSQUEDAS ESPECIALIZADAS
  // ═══════════════════════════════════════════════════════════

  /// Obtener items con stock bajo
  Stream<List<InventoryItem>> streamLowStockItems() {
    return _itemsRef
        .where('isActive', isEqualTo: true)
        .where('trackInventory', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(InventoryItem.fromDoc)
              .where((item) => item.isStockLow)
              .toList();
        });
  }

  /// Obtener items que necesitan reorden
  Stream<List<InventoryItem>> streamReorderNeededItems() {
    return _itemsRef
        .where('isActive', isEqualTo: true)
        .where('trackInventory', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(InventoryItem.fromDoc)
              .where((item) => item.needsReorder)
              .toList();
        });
  }

  /// Obtener items próximos a vencer
  Future<List<InventoryItem>> getExpiringItems({int daysAhead = 30}) async {
    final futureDate = DateTime.now().add(Duration(days: daysAhead));

    final snapshot = await _itemsRef
        .where('isActive', isEqualTo: true)
        .where(
          'expirationDate',
          isLessThanOrEqualTo: Timestamp.fromDate(futureDate),
        )
        .where(
          'expirationDate',
          isGreaterThan: Timestamp.fromDate(DateTime.now()),
        )
        .get();

    return snapshot.docs.map(InventoryItem.fromDoc).toList();
  }

  /// Obtener items vencidos
  Future<List<InventoryItem>> getExpiredItems() async {
    final snapshot = await _itemsRef
        .where('isActive', isEqualTo: true)
        .where('expirationDate', isLessThan: Timestamp.fromDate(DateTime.now()))
        .get();

    return snapshot.docs.map(InventoryItem.fromDoc).toList();
  }

  /// Obtener activos que necesitan mantenimiento
  Stream<List<InventoryItem>> streamMaintenanceNeededAssets() {
    return _itemsRef
        .where('type', isEqualTo: InventoryItemType.asset.name)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(InventoryItem.fromDoc)
              .where((item) => item.needsMaintenance)
              .toList();
        });
  }

  /// Obtener items por proveedor
  Stream<List<InventoryItem>> streamItemsBySupplier(String supplierId) {
    return _itemsRef
        .where('primarySupplierId', isEqualTo: supplierId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(InventoryItem.fromDoc).toList());
  }

  /// Buscar por código de barras
  Future<InventoryItem?> findByBarcode(String barcode) async {
    final snapshot = await _itemsRef
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return InventoryItem.fromDoc(snapshot.docs.first);
  }

  /// Buscar por SKU
  Future<InventoryItem?> findBySku(String sku) async {
    final snapshot = await _itemsRef
        .where('sku', isEqualTo: sku)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return InventoryItem.fromDoc(snapshot.docs.first);
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════

  /// Obtener estadísticas generales
  Future<InventoryStats> getStats() async {
    try {
      final snapshot = await _itemsRef.get();
      final items = snapshot.docs.map(InventoryItem.fromDoc).toList();

      final activeItems = items.where((i) => i.isActive).toList();
      final products = activeItems
          .where((i) => i.type == InventoryItemType.product)
          .toList();
      final services = activeItems
          .where((i) => i.type == InventoryItemType.service)
          .toList();
      final assets = activeItems
          .where((i) => i.type == InventoryItemType.asset)
          .toList();

      return InventoryStats(
        totalItems: activeItems.length,
        totalProducts: products.length,
        totalServices: services.length,
        totalAssets: assets.length,
        lowStockItems: activeItems.where((i) => i.isStockLow).length,
        outOfStockItems: activeItems
            .where((i) => i.stock == 0 && i.trackInventory)
            .length,
        totalInventoryValue: products.fold(
          0.0,
          (sum, i) => sum + i.totalInventoryValue,
        ),
        averagePrice: activeItems.isEmpty
            ? 0
            : activeItems.fold(0.0, (sum, i) => sum + i.sellingPrice) /
                  activeItems.length,
        expiringItems: activeItems
            .where(
              (i) =>
                  i.expirationDate != null &&
                  i.expirationDate!.isBefore(
                    DateTime.now().add(const Duration(days: 30)),
                  ) &&
                  i.expirationDate!.isAfter(DateTime.now()),
            )
            .length,
        expiredItems: activeItems.where((i) => i.isExpired).length,
        maintenanceNeeded: assets.where((i) => i.needsMaintenance).length,
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UTILIDADES INTERNAS
  // ═══════════════════════════════════════════════════════════

  /// Actualizar contador de items en categoría
  Future<void> _updateCategoryItemCount(String categoryId, int delta) async {
    try {
      await FirebaseHelper.inventoryCategories.doc(categoryId).update({
        'itemCount': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Error actualizando contador de categoría: $e');
    }
  }

  /// Registrar log de auditoría
  Future<void> _logAudit({
    required String action,
    String? itemId,
    String? itemName,
    String? details,
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? newData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseHelper.inventoryAuditLogs.add({
        'action': action,
        'itemId': itemId,
        'itemName': itemName,
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

  // ═══════════════════════════════════════════════════════════
  // VALIDACIONES
  // ═══════════════════════════════════════════════════════════

  /// Validar item antes de guardar
  List<String> validateItem(InventoryItem item) {
    final errors = <String>[];

    if (item.name.trim().isEmpty) {
      errors.add('El nombre es requerido');
    }
    if (item.name.length > 200) {
      errors.add('El nombre no puede exceder 200 caracteres');
    }
    if (item.description.length > 2000) {
      errors.add('La descripción no puede exceder 2000 caracteres');
    }
    if (item.purchasePrice < 0) {
      errors.add('El precio de compra no puede ser negativo');
    }
    if (item.sellingPrice < 0) {
      errors.add('El precio de venta no puede ser negativo');
    }
    if (item.sellingPrice < item.purchasePrice) {
      errors.add('El precio de venta debería ser mayor o igual al de compra');
    }
    if (item.stock < 0) {
      errors.add('El stock no puede ser negativo');
    }
    if (item.minStock < 0) {
      errors.add('El stock mínimo no puede ser negativo');
    }
    if (item.categoryId.isEmpty) {
      errors.add('La categoría es requerida');
    }

    return errors;
  }
  // ═══════════════════════════════════════════════════════════
  // FUNCIONES ADICIONALES PARA DASHBOARD
  // ═══════════════════════════════════════════════════════════

  /// Stream de estadísticas en tiempo real
  Stream<InventoryStats> streamStats() {
    return _itemsRef.snapshots().map((snapshot) {
      final items = snapshot.docs.map(InventoryItem.fromDoc).toList();

      final activeItems = items.where((i) => i.isActive).toList();
      final products = activeItems
          .where((i) => i.type == InventoryItemType.product)
          .toList();
      final services = activeItems
          .where((i) => i.type == InventoryItemType.service)
          .toList();
      final assets = activeItems
          .where((i) => i.type == InventoryItemType.asset)
          .toList();

      return InventoryStats(
        totalItems: activeItems.length,
        totalProducts: products.length,
        totalServices: services.length,
        totalAssets: assets.length,
        lowStockItems: activeItems.where((i) => i.isStockLow).length,
        outOfStockItems: activeItems
            .where((i) => i.stock == 0 && i.trackInventory)
            .length,
        totalInventoryValue: products.fold(
          0.0,
          (sum, i) => sum + i.totalInventoryValue,
        ),
        averagePrice: activeItems.isEmpty
            ? 0
            : activeItems.fold(0.0, (sum, i) => sum + i.sellingPrice) /
                  activeItems.length,
        expiringItems: activeItems
            .where(
              (i) =>
                  i.expirationDate != null &&
                  i.expirationDate!.isBefore(
                    DateTime.now().add(const Duration(days: 30)),
                  ) &&
                  i.expirationDate!.isAfter(DateTime.now()),
            )
            .length,
        expiredItems: activeItems.where((i) => i.isExpired).length,
        maintenanceNeeded: assets.where((i) => i.needsMaintenance).length,
      );
    });
  }

  /// Stream de actividad reciente (movimientos)
  Stream<List<RecentActivity>> streamRecentActivity({int limit = 5}) {
    return FirebaseHelper.inventoryMovements
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return RecentActivity(
              id: doc.id,
              type: data['type'] ?? 'adjustment',
              itemName: data['itemName'] ?? 'Item desconocido',
              quantity: data['quantity'] ?? 0,
              userName:
                  data['createdByName'] ?? data['createdByEmail'] ?? 'Usuario',
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
        });
  }

  /// Stock por categoría para gráficos
  Future<List<CategoryStock>> getStockByCategory({int limit = 5}) async {
    try {
      final snapshot = await _itemsRef.where('isActive', isEqualTo: true).get();

      final items = snapshot.docs.map(InventoryItem.fromDoc).toList();

      // Agrupar por categoría
      final Map<String, int> categoryStock = {};
      final Map<String, String> categoryNames = {};

      for (final item in items) {
        if (item.type != InventoryItemType.service) {
          final catId = item.categoryId;
          categoryStock[catId] = (categoryStock[catId] ?? 0) + item.stock;
          categoryNames[catId] = catId;
        }
      }

      // Obtener nombres de categorías
      final categoriesSnapshot = await FirebaseHelper.inventoryCategories.get();
      for (final doc in categoriesSnapshot.docs) {
        if (categoryNames.containsKey(doc.id)) {
          categoryNames[doc.id] = doc.data()['name'] ?? doc.id;
        }
      }

      // Ordenar y limitar
      final sorted = categoryStock.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(limit).map((entry) {
        return CategoryStock(
          categoryId: entry.key,
          categoryName: categoryNames[entry.key] ?? entry.key,
          totalStock: entry.value,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting stock by category: $e');
      return [];
    }
  }

  /// Generar SKU público (para el formulario)
  Future<String> generateSku(InventoryItemType type) async {
    return _generateSku(type);
  }
}

/// Modelo para estadísticas de inventario
class InventoryStats {
  final int totalItems;
  final int totalProducts;
  final int totalServices;
  final int totalAssets;
  final int lowStockItems;
  final int outOfStockItems;
  final double totalInventoryValue;
  final double averagePrice;
  final int expiringItems;
  final int expiredItems;
  final int maintenanceNeeded;

  InventoryStats({
    required this.totalItems,
    required this.totalProducts,
    required this.totalServices,
    required this.totalAssets,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.totalInventoryValue,
    required this.averagePrice,
    required this.expiringItems,
    required this.expiredItems,
    required this.maintenanceNeeded,
  });
}

/// Modelo para actividad reciente
class RecentActivity {
  final String id;
  final String type;
  final String itemName;
  final int quantity;
  final String userName;
  final DateTime createdAt;

  const RecentActivity({
    required this.id,
    required this.type,
    required this.itemName,
    required this.quantity,
    required this.userName,
    required this.createdAt,
  });

  bool get isIncoming =>
      type == 'purchase' || type == 'return_in' || type == 'adjustment';
}

/// Modelo para stock por categoría
class CategoryStock {
  final String categoryId;
  final String categoryName;
  final int totalStock;

  const CategoryStock({
    required this.categoryId,
    required this.categoryName,
    required this.totalStock,
  });
}
