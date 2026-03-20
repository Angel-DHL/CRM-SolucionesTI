// lib/inventory/services/inventory_location_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase_helper.dart';
import '../models/inventory_location.dart';

/// Filtros para búsqueda de ubicaciones
class LocationFilters {
  final String? searchQuery;
  final LocationType? type;
  final bool? isActive;
  final String? country;
  final String? state;
  final String? city;
  final bool? isShippingOrigin;
  final bool? isPickupLocation;
  final bool? acceptsReturns;
  final String? sortBy;
  final bool sortDescending;

  const LocationFilters({
    this.searchQuery,
    this.type,
    this.isActive,
    this.country,
    this.state,
    this.city,
    this.isShippingOrigin,
    this.isPickupLocation,
    this.acceptsReturns,
    this.sortBy,
    this.sortDescending = false,
  });

  static const LocationFilters none = LocationFilters();

  bool get hasFilters =>
      searchQuery != null ||
      type != null ||
      isActive != null ||
      country != null ||
      state != null ||
      city != null ||
      isShippingOrigin != null ||
      isPickupLocation != null ||
      acceptsReturns != null;
}

class InventoryLocationService {
  InventoryLocationService._();
  static final InventoryLocationService instance = InventoryLocationService._();

  CollectionReference<Map<String, dynamic>> get _locationsRef =>
      FirebaseHelper.inventoryLocations;

  // ═══════════════════════════════════════════════════════════
  // CREAR UBICACIÓN
  // ═══════════════════════════════════════════════════════════

  /// Crear nueva ubicación
  Future<String> createLocation(InventoryLocation location) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Generar código único si no existe
      String code = location.code;
      if (code.isEmpty) {
        code = await _generateLocationCode(location.type);
      }

      // Verificar código único
      final existing = await _locationsRef
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('El código "$code" ya existe');
      }

      // Calcular jerarquía si tiene padre
      int level = 0;
      String path = code;
      List<String> ancestorIds = [];

      if (location.parentId != null) {
        final parentDoc = await _locationsRef.doc(location.parentId).get();
        if (parentDoc.exists) {
          final parent = InventoryLocation.fromDoc(parentDoc);
          level = parent.level + 1;
          path = '${parent.path}/$code';
          ancestorIds = [...parent.ancestorIds, parent.id];
        }
      }

      final data = location
          .copyWith(
            code: code,
            level: level,
            path: path,
            ancestorIds: ancestorIds,
            createdBy: user.uid,
            lastModifiedBy: user.uid,
          )
          .toMap();

      final docRef = await _locationsRef.add(data);

      // Actualizar contador de hijos del padre
      if (location.parentId != null) {
        await _updateChildCount(location.parentId!, 1);
      }

      await _logAudit(
        action: 'create',
        locationId: docRef.id,
        locationName: location.name,
        details: 'Ubicación creada: ${location.name} ($code)',
      );

      debugPrint('✅ Ubicación creada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creando ubicación: $e');
      rethrow;
    }
  }

  /// Generar código de ubicación
  Future<String> _generateLocationCode(LocationType type) async {
    final prefix = switch (type) {
      LocationType.warehouse => 'ALM',
      LocationType.store => 'TDA',
      LocationType.office => 'OFC',
      LocationType.vehicle => 'VEH',
      LocationType.external => 'EXT',
      LocationType.virtual => 'VRT',
    };

    final counterRef = FirebaseHelper.inventoryCounters.doc('location_$prefix');

    return FirebaseHelper.db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      int nextNumber = 1;

      if (snapshot.exists) {
        nextNumber = (snapshot.data()?['current'] ?? 0) + 1;
      }

      transaction.set(counterRef, {
        'current': nextNumber,
      }, SetOptions(merge: true));

      return '$prefix-${nextNumber.toString().padLeft(4, '0')}';
    });
  }

  // ═══════════════════════════════════════════════════════════
  // LEER UBICACIONES
  // ═══════════════════════════════════════════════════════════

  /// Obtener ubicación por ID
  Future<InventoryLocation?> getLocationById(String id) async {
    try {
      final doc = await _locationsRef.doc(id).get();
      if (!doc.exists) return null;
      return InventoryLocation.fromDoc(doc);
    } catch (e) {
      debugPrint('❌ Error obteniendo ubicación: $e');
      rethrow;
    }
  }

  /// Obtener ubicación por código
  Future<InventoryLocation?> getLocationByCode(String code) async {
    try {
      final snapshot = await _locationsRef
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return InventoryLocation.fromDoc(snapshot.docs.first);
    } catch (e) {
      debugPrint('❌ Error obteniendo ubicación por código: $e');
      rethrow;
    }
  }

  /// Stream de una ubicación específica
  Stream<InventoryLocation?> streamLocation(String id) {
    return _locationsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return InventoryLocation.fromDoc(doc);
    });
  }

  /// Stream de todas las ubicaciones
  Stream<List<InventoryLocation>> streamLocations({
    LocationFilters filters = LocationFilters.none,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _locationsRef;

    // Filtros de Firestore
    if (filters.type != null) {
      query = query.where('type', isEqualTo: filters.type!.name);
    }
    if (filters.isActive != null) {
      query = query.where('isActive', isEqualTo: filters.isActive);
    }
    if (filters.isShippingOrigin != null) {
      query = query.where(
        'isShippingOrigin',
        isEqualTo: filters.isShippingOrigin,
      );
    }
    if (filters.isPickupLocation != null) {
      query = query.where(
        'isPickupLocation',
        isEqualTo: filters.isPickupLocation,
      );
    }

    // Ordenamiento
    final sortField = filters.sortBy ?? 'name';
    query = query.orderBy(sortField, descending: filters.sortDescending);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      var locations = snapshot.docs.map(InventoryLocation.fromDoc).toList();
      locations = _applyClientFilters(locations, filters);
      return locations;
    });
  }

  /// Stream de ubicaciones raíz (sin padre)
  Stream<List<InventoryLocation>> streamRootLocations({
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _locationsRef.where(
      'parentId',
      isNull: true,
    );

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(InventoryLocation.fromDoc).toList(),
        );
  }

  /// Stream de sub-ubicaciones
  Stream<List<InventoryLocation>> streamSubLocations(
    String parentId, {
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _locationsRef.where(
      'parentId',
      isEqualTo: parentId,
    );

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(InventoryLocation.fromDoc).toList(),
        );
  }

  /// Obtener árbol de ubicaciones
  Future<List<LocationNode>> getLocationTree({bool activeOnly = true}) async {
    Query<Map<String, dynamic>> query = _locationsRef;

    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }

    final snapshot = await query.orderBy('name').get();
    final locations = snapshot.docs.map(InventoryLocation.fromDoc).toList();

    // Construir árbol
    final Map<String?, List<InventoryLocation>> grouped = {};
    for (final loc in locations) {
      grouped.putIfAbsent(loc.parentId, () => []).add(loc);
    }

    List<LocationNode> buildNodes(String? parentId) {
      final children = grouped[parentId] ?? [];
      return children
          .map(
            (loc) => LocationNode(location: loc, children: buildNodes(loc.id)),
          )
          .toList();
    }

    return buildNodes(null);
  }

  /// Obtener ruta de breadcrumb
  Future<List<InventoryLocation>> getBreadcrumb(String locationId) async {
    final location = await getLocationById(locationId);
    if (location == null) return [];

    final breadcrumb = <InventoryLocation>[];

    for (final ancestorId in location.ancestorIds) {
      final ancestor = await getLocationById(ancestorId);
      if (ancestor != null) {
        breadcrumb.add(ancestor);
      }
    }

    breadcrumb.add(location);
    return breadcrumb;
  }

  /// Aplicar filtros en cliente
  List<InventoryLocation> _applyClientFilters(
    List<InventoryLocation> locations,
    LocationFilters filters,
  ) {
    var filtered = locations;

    // Búsqueda por texto
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase();
      filtered = filtered.where((loc) {
        return loc.name.toLowerCase().contains(query) ||
            loc.code.toLowerCase().contains(query) ||
            (loc.description?.toLowerCase().contains(query) ?? false) ||
            (loc.city?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filtros geográficos
    if (filters.country != null) {
      filtered = filtered
          .where(
            (l) => l.country?.toLowerCase() == filters.country!.toLowerCase(),
          )
          .toList();
    }
    if (filters.state != null) {
      filtered = filtered
          .where((l) => l.state?.toLowerCase() == filters.state!.toLowerCase())
          .toList();
    }
    if (filters.city != null) {
      filtered = filtered
          .where((l) => l.city?.toLowerCase() == filters.city!.toLowerCase())
          .toList();
    }

    // Filtro de devoluciones
    if (filters.acceptsReturns != null) {
      filtered = filtered
          .where((l) => l.acceptsReturns == filters.acceptsReturns)
          .toList();
    }

    return filtered;
  }

  // ═══════════════════════════════════════════════════════════
  // ACTUALIZAR UBICACIÓN
  // ═══════════════════════════════════════════════════════════

  /// Actualizar ubicación
  Future<void> updateLocation(InventoryLocation location) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final data = {
        ...location.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': user.uid,
      };
      data.remove('createdAt');

      await _locationsRef.doc(location.id).update(data);

      await _logAudit(
        action: 'update',
        locationId: location.id,
        locationName: location.name,
        details: 'Ubicación actualizada: ${location.name}',
      );

      debugPrint('✅ Ubicación actualizada: ${location.id}');
    } catch (e) {
      debugPrint('❌ Error actualizando ubicación: $e');
      rethrow;
    }
  }

  /// Actualizar campos específicos
  Future<void> updateLocationFields(
    String locationId,
    Map<String, dynamic> fields,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      fields['updatedAt'] = FieldValue.serverTimestamp();
      fields['lastModifiedBy'] = user.uid;

      await _locationsRef.doc(locationId).update(fields);
      debugPrint('✅ Campos actualizados: $locationId');
    } catch (e) {
      debugPrint('❌ Error actualizando campos: $e');
      rethrow;
    }
  }

  /// Activar/desactivar ubicación
  Future<void> toggleActive(String locationId, bool isActive) async {
    await updateLocationFields(locationId, {'isActive': isActive});
  }

  /// Mover ubicación a otro padre
  Future<void> moveLocation(String locationId, String? newParentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final location = await getLocationById(locationId);
      if (location == null) throw Exception('Ubicación no encontrada');

      // Verificar que no se mueva a sí mismo o a un descendiente
      if (newParentId != null) {
        final newParent = await getLocationById(newParentId);
        if (newParent != null && newParent.ancestorIds.contains(locationId)) {
          throw Exception(
            'No se puede mover una ubicación a uno de sus descendientes',
          );
        }
      }

      final oldParentId = location.parentId;

      // Calcular nueva jerarquía
      int newLevel = 0;
      String newPath = location.code;
      List<String> newAncestorIds = [];

      if (newParentId != null) {
        final newParent = await getLocationById(newParentId);
        if (newParent != null) {
          newLevel = newParent.level + 1;
          newPath = '${newParent.path}/${location.code}';
          newAncestorIds = [...newParent.ancestorIds, newParent.id];
        }
      }

      await _locationsRef.doc(locationId).update({
        'parentId': newParentId,
        'level': newLevel,
        'path': newPath,
        'ancestorIds': newAncestorIds,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': user.uid,
      });

      // Actualizar contadores
      if (oldParentId != null) {
        await _updateChildCount(oldParentId, -1);
      }
      if (newParentId != null) {
        await _updateChildCount(newParentId, 1);
      }

      // Actualizar hijos recursivamente
      await _updateChildrenPaths(locationId, newPath, newLevel, newAncestorIds);

      await _logAudit(
        action: 'move',
        locationId: locationId,
        locationName: location.name,
        details: 'Ubicación movida de $oldParentId a $newParentId',
      );

      debugPrint('✅ Ubicación movida: $locationId');
    } catch (e) {
      debugPrint('❌ Error moviendo ubicación: $e');
      rethrow;
    }
  }

  /// Actualizar paths de hijos recursivamente
  Future<void> _updateChildrenPaths(
    String parentId,
    String parentPath,
    int parentLevel,
    List<String> parentAncestorIds,
  ) async {
    final children = await _locationsRef
        .where('parentId', isEqualTo: parentId)
        .get();

    for (final childDoc in children.docs) {
      final child = InventoryLocation.fromDoc(childDoc);
      final newPath = '$parentPath/${child.code}';
      final newLevel = parentLevel + 1;
      final newAncestorIds = [...parentAncestorIds, parentId];

      await _locationsRef.doc(child.id).update({
        'path': newPath,
        'level': newLevel,
        'ancestorIds': newAncestorIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _updateChildrenPaths(child.id, newPath, newLevel, newAncestorIds);
    }
  }

  /// Actualizar contador de stock de ubicación
  Future<void> updateItemCount(String locationId, int delta) async {
    await _locationsRef.doc(locationId).update({
      'currentItemCount': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════
  // ELIMINAR UBICACIÓN
  // ═══════════════════════════════════════════════════════════

  /// Verificar si se puede eliminar
  Future<bool> canDeleteLocation(String locationId) async {
    final location = await getLocationById(locationId);
    if (location == null) return false;

    // No se puede eliminar si tiene hijos
    if (location.childLocationCount > 0) return false;

    // No se puede eliminar si tiene items
    if (location.currentItemCount > 0) return false;

    return true;
  }

  /// Eliminar ubicación
  Future<void> deleteLocation(String locationId) async {
    if (!await canDeleteLocation(locationId)) {
      throw Exception(
        'No se puede eliminar: la ubicación tiene sub-ubicaciones o items',
      );
    }

    try {
      final location = await getLocationById(locationId);

      await _locationsRef.doc(locationId).delete();

      if (location?.parentId != null) {
        await _updateChildCount(location!.parentId!, -1);
      }

      await _logAudit(
        action: 'delete',
        locationId: locationId,
        locationName: location?.name,
        details: 'Ubicación eliminada',
      );

      debugPrint('✅ Ubicación eliminada: $locationId');
    } catch (e) {
      debugPrint('❌ Error eliminando ubicación: $e');
      rethrow;
    }
  }

  /// Desactivar ubicación
  Future<void> deactivateLocation(String locationId) async {
    await updateLocationFields(locationId, {'isActive': false});

    await _logAudit(
      action: 'deactivate',
      locationId: locationId,
      details: 'Ubicación desactivada',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HORARIOS
  // ═══════════════════════════════════════════════════════════

  /// Actualizar horario de un día
  Future<void> updateSchedule(
    String locationId,
    String day,
    LocationSchedule schedule,
  ) async {
    await _locationsRef.doc(locationId).update({
      'schedule.$day': schedule.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualizar horario completo
  Future<void> updateFullSchedule(
    String locationId,
    Map<String, LocationSchedule> schedule,
  ) async {
    final scheduleMap = <String, dynamic>{};
    schedule.forEach((key, value) {
      scheduleMap[key] = value.toMap();
    });

    await _locationsRef.doc(locationId).update({
      'schedule': scheduleMap,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Verificar si está abierto ahora
  bool isOpenNow(InventoryLocation location) {
    if (location.schedule == null) return true; // Sin horario = siempre abierto

    final now = DateTime.now();
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final today = dayNames[now.weekday - 1];

    final todaySchedule = location.schedule![today];
    if (todaySchedule == null || !todaySchedule.isOpen) return false;

    if (todaySchedule.openTime == null || todaySchedule.closeTime == null) {
      return true; // Sin horas específicas = abierto todo el día
    }

    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Verificar si está en horario de break
    if (todaySchedule.breakStart != null && todaySchedule.breakEnd != null) {
      if (currentTime.compareTo(todaySchedule.breakStart!) >= 0 &&
          currentTime.compareTo(todaySchedule.breakEnd!) < 0) {
        return false;
      }
    }

    return currentTime.compareTo(todaySchedule.openTime!) >= 0 &&
        currentTime.compareTo(todaySchedule.closeTime!) < 0;
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════

  /// Obtener estadísticas de ubicaciones
  Future<LocationStats> getStats() async {
    try {
      final snapshot = await _locationsRef.get();
      final locations = snapshot.docs.map(InventoryLocation.fromDoc).toList();

      final active = locations.where((l) => l.isActive).toList();
      final withItems = active.where((l) => l.currentItemCount > 0).toList();
      final nearCapacity = active.where((l) => l.isNearCapacity).toList();

      // Agrupar por tipo
      final byType = <LocationType, int>{};
      for (final l in active) {
        byType[l.type] = (byType[l.type] ?? 0) + 1;
      }

      // Total de items
      int totalItems = 0;
      for (final l in active) {
        totalItems += l.currentItemCount;
      }

      return LocationStats(
        totalLocations: locations.length,
        activeLocations: active.length,
        locationsWithItems: withItems.length,
        locationsNearCapacity: nearCapacity.length,
        totalItemsStored: totalItems,
        locationsByType: byType,
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  /// Obtener ubicaciones con más stock
  Future<List<InventoryLocation>> getTopStockLocations({int limit = 10}) async {
    final snapshot = await _locationsRef
        .where('isActive', isEqualTo: true)
        .orderBy('currentItemCount', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map(InventoryLocation.fromDoc).toList();
  }

  /// Obtener ubicaciones cerca de capacidad máxima
  Stream<List<InventoryLocation>> streamNearCapacityLocations() {
    return _locationsRef.where('isActive', isEqualTo: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(InventoryLocation.fromDoc)
          .where((l) => l.isNearCapacity)
          .toList();
    });
  }

  // ═══════════════════════════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════════════════════════

  Future<void> _updateChildCount(String locationId, int delta) async {
    try {
      await _locationsRef.doc(locationId).update({
        'childLocationCount': FieldValue.increment(delta),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Error actualizando contador de hijos: $e');
    }
  }

  Future<void> _logAudit({
    required String action,
    String? locationId,
    String? locationName,
    String? details,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseHelper.inventoryAuditLogs.add({
        'module': 'locations',
        'action': action,
        'entityId': locationId,
        'entityName': locationName,
        'details': details,
        'userId': user?.uid,
        'userEmail': user?.email,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Error registrando auditoría: $e');
    }
  }

  /// Validar ubicación
  List<String> validateLocation(InventoryLocation location) {
    final errors = <String>[];

    if (location.name.trim().isEmpty) {
      errors.add('El nombre es requerido');
    }
    if (location.name.length > 100) {
      errors.add('El nombre no puede exceder 100 caracteres');
    }
    if (location.maxCapacity != null && location.maxCapacity! < 0) {
      errors.add('La capacidad máxima no puede ser negativa');
    }
    if (location.areaSquareMeters != null && location.areaSquareMeters! < 0) {
      errors.add('El área no puede ser negativa');
    }

    return errors;
  }
}

/// Nodo del árbol de ubicaciones
class LocationNode {
  final InventoryLocation location;
  final List<LocationNode> children;

  LocationNode({required this.location, required this.children});

  bool get hasChildren => children.isNotEmpty;
}

/// Estadísticas de ubicaciones
class LocationStats {
  final int totalLocations;
  final int activeLocations;
  final int locationsWithItems;
  final int locationsNearCapacity;
  final int totalItemsStored;
  final Map<LocationType, int> locationsByType;

  LocationStats({
    required this.totalLocations,
    required this.activeLocations,
    required this.locationsWithItems,
    required this.locationsNearCapacity,
    required this.totalItemsStored,
    required this.locationsByType,
  });
}
