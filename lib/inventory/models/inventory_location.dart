// lib/inventory/models/inventory_location.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Tipo de ubicación
enum LocationType {
  warehouse('Almacén', Icons.warehouse_rounded),
  store('Tienda', Icons.storefront_rounded),
  office('Oficina', Icons.business_rounded),
  vehicle('Vehículo', Icons.local_shipping_rounded),
  external('Externo', Icons.location_on_rounded),
  virtual('Virtual', Icons.cloud_rounded);

  final String label;
  final IconData icon;
  const LocationType(this.label, this.icon);

  static LocationType fromString(String? value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => LocationType.warehouse,
    );
  }
}

class InventoryLocation {
  // ═══════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ═══════════════════════════════════════════════════════════
  final String id;
  final String? parentId; // Ubicación padre (para sub-ubicaciones)
  final String code; // Código único (ej: "ALM-001", "EST-A1")

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN BÁSICA
  // ═══════════════════════════════════════════════════════════
  final String name; // Nombre de la ubicación
  final String? description; // Descripción
  final LocationType type; // Tipo de ubicación

  // ═══════════════════════════════════════════════════════════
  // DIRECCIÓN (Opcional - para ubicaciones físicas)
  // ═══════════════════════════════════════════════════════════
  final String? addressLine1; // Dirección línea 1
  final String? addressLine2; // Dirección línea 2
  final String? city; // Ciudad
  final String? state; // Estado
  final String? postalCode; // Código postal
  final String? country; // País
  final double? latitude; // Latitud (para mapas)
  final double? longitude; // Longitud (para mapas)

  // ═══════════════════════════════════════════════════════════
  // CONTACTO
  // ═══════════════════════════════════════════════════════════
  final String? managerName; // Nombre del encargado
  final String? managerEmail; // Email del encargado
  final String? managerPhone; // Teléfono del encargado
  final String? phone; // Teléfono de la ubicación

  // ═══════════════════════════════════════════════════════════
  // CAPACIDAD Y CONFIGURACIÓN
  // ═══════════════════════════════════════════════════════════
  final int? maxCapacity; // Capacidad máxima (unidades)
  final double? areaSquareMeters; // Área en metros cuadrados
  final bool isActive; // Está activa
  final bool acceptsReturns; // Acepta devoluciones
  final bool isShippingOrigin; // Puede enviar productos
  final bool isPickupLocation; // Punto de recogida

  // ═══════════════════════════════════════════════════════════
  // HORARIOS (Opcional)
  // ═══════════════════════════════════════════════════════════
  final Map<String, LocationSchedule>? schedule; // Horarios por día
  final String? timezone; // Zona horaria

  // ═══════════════════════════════════════════════════════════
  // JERARQUÍA
  // ═══════════════════════════════════════════════════════════
  final int level; // Nivel (0 = raíz)
  final String path; // Ruta (ej: "almacen-central/zona-a/estante-1")
  final List<String> ancestorIds; // IDs de ancestros

  // ═══════════════════════════════════════════════════════════
  // ESTADÍSTICAS (calculadas)
  // ═══════════════════════════════════════════════════════════
  final int currentItemCount; // Cantidad actual de ítems
  final int childLocationCount; // Sub-ubicaciones

  // ═══════════════════════════════════════════════════════════
  // NOTAS
  // ═══════════════════════════════════════════════════════════
  final String? notes; // Notas adicionales

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA
  // ═══════════════════════════════════════════════════════════
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? lastModifiedBy;

  InventoryLocation({
    required this.id,
    this.parentId,
    required this.code,
    required this.name,
    this.description,
    required this.type,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    this.managerName,
    this.managerEmail,
    this.managerPhone,
    this.phone,
    this.maxCapacity,
    this.areaSquareMeters,
    this.isActive = true,
    this.acceptsReturns = true,
    this.isShippingOrigin = false,
    this.isPickupLocation = false,
    this.schedule,
    this.timezone,
    this.level = 0,
    required this.path,
    this.ancestorIds = const [],
    this.currentItemCount = 0,
    this.childLocationCount = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastModifiedBy,
  });

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN DESDE FIRESTORE
  // ═══════════════════════════════════════════════════════════
  static InventoryLocation fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parsear horarios si existen
    Map<String, LocationSchedule>? schedule;
    if (data['schedule'] != null) {
      schedule = {};
      (data['schedule'] as Map<String, dynamic>).forEach((key, value) {
        schedule![key] = LocationSchedule.fromMap(value);
      });
    }

    return InventoryLocation(
      id: doc.id,
      parentId: data['parentId'],
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      type: LocationType.fromString(data['type']),
      addressLine1: data['addressLine1'],
      addressLine2: data['addressLine2'],
      city: data['city'],
      state: data['state'],
      postalCode: data['postalCode'],
      country: data['country'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      managerName: data['managerName'],
      managerEmail: data['managerEmail'],
      managerPhone: data['managerPhone'],
      phone: data['phone'],
      maxCapacity: data['maxCapacity'],
      areaSquareMeters: data['areaSquareMeters']?.toDouble(),
      isActive: data['isActive'] ?? true,
      acceptsReturns: data['acceptsReturns'] ?? true,
      isShippingOrigin: data['isShippingOrigin'] ?? false,
      isPickupLocation: data['isPickupLocation'] ?? false,
      schedule: schedule,
      timezone: data['timezone'],
      level: data['level'] ?? 0,
      path: data['path'] ?? '',
      ancestorIds: List<String>.from(data['ancestorIds'] ?? []),
      currentItemCount: data['currentItemCount'] ?? 0,
      childLocationCount: data['childLocationCount'] ?? 0,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      lastModifiedBy: data['lastModifiedBy'],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN A MAP PARA FIRESTORE
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic> toMap() {
    // Convertir horarios a map
    Map<String, dynamic>? scheduleMap;
    if (schedule != null) {
      scheduleMap = {};
      schedule!.forEach((key, value) {
        scheduleMap![key] = value.toMap();
      });
    }

    return {
      'parentId': parentId,
      'code': code,
      'name': name,
      'description': description,
      'type': type.name,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'managerName': managerName,
      'managerEmail': managerEmail,
      'managerPhone': managerPhone,
      'phone': phone,
      'maxCapacity': maxCapacity,
      'areaSquareMeters': areaSquareMeters,
      'isActive': isActive,
      'acceptsReturns': acceptsReturns,
      'isShippingOrigin': isShippingOrigin,
      'isPickupLocation': isPickupLocation,
      'schedule': scheduleMap,
      'timezone': timezone,
      'level': level,
      'path': path,
      'ancestorIds': ancestorIds,
      'currentItemCount': currentItemCount,
      'childLocationCount': childLocationCount,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTODOS ÚTILES
  // ═══════════════════════════════════════════════════════════

  /// Es ubicación raíz
  bool get isRoot => parentId == null;

  /// Tiene sub-ubicaciones
  bool get hasChildren => childLocationCount > 0;

  /// Dirección completa formateada
  String get fullAddress {
    final parts = <String>[];
    if (addressLine1 != null && addressLine1!.isNotEmpty)
      parts.add(addressLine1!);
    if (addressLine2 != null && addressLine2!.isNotEmpty)
      parts.add(addressLine2!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  /// Tiene coordenadas de mapa
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Porcentaje de capacidad usado
  double get capacityUsedPercentage {
    if (maxCapacity == null || maxCapacity == 0) return 0;
    return (currentItemCount / maxCapacity!) * 100;
  }

  /// Está casi lleno (>80%)
  bool get isNearCapacity => capacityUsedPercentage >= 80;

  /// CopyWith
  InventoryLocation copyWith({
    String? id,
    String? parentId,
    String? code,
    String? name,
    String? description,
    LocationType? type,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    String? managerName,
    String? managerEmail,
    String? managerPhone,
    String? phone,
    int? maxCapacity,
    double? areaSquareMeters,
    bool? isActive,
    bool? acceptsReturns,
    bool? isShippingOrigin,
    bool? isPickupLocation,
    Map<String, LocationSchedule>? schedule,
    String? timezone,
    int? level,
    String? path,
    List<String>? ancestorIds,
    int? currentItemCount,
    int? childLocationCount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
  }) {
    return InventoryLocation(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      managerName: managerName ?? this.managerName,
      managerEmail: managerEmail ?? this.managerEmail,
      managerPhone: managerPhone ?? this.managerPhone,
      phone: phone ?? this.phone,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      areaSquareMeters: areaSquareMeters ?? this.areaSquareMeters,
      isActive: isActive ?? this.isActive,
      acceptsReturns: acceptsReturns ?? this.acceptsReturns,
      isShippingOrigin: isShippingOrigin ?? this.isShippingOrigin,
      isPickupLocation: isPickupLocation ?? this.isPickupLocation,
      schedule: schedule ?? this.schedule,
      timezone: timezone ?? this.timezone,
      level: level ?? this.level,
      path: path ?? this.path,
      ancestorIds: ancestorIds ?? this.ancestorIds,
      currentItemCount: currentItemCount ?? this.currentItemCount,
      childLocationCount: childLocationCount ?? this.childLocationCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}

/// Modelo auxiliar para horarios
class LocationSchedule {
  final bool isOpen;
  final String? openTime; // Formato "HH:mm"
  final String? closeTime; // Formato "HH:mm"
  final String? breakStart; // Inicio de descanso
  final String? breakEnd; // Fin de descanso

  LocationSchedule({
    this.isOpen = true,
    this.openTime,
    this.closeTime,
    this.breakStart,
    this.breakEnd,
  });

  static LocationSchedule fromMap(Map<String, dynamic> map) {
    return LocationSchedule(
      isOpen: map['isOpen'] ?? true,
      openTime: map['openTime'],
      closeTime: map['closeTime'],
      breakStart: map['breakStart'],
      breakEnd: map['breakEnd'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'openTime': openTime,
      'closeTime': closeTime,
      'breakStart': breakStart,
      'breakEnd': breakEnd,
    };
  }
}
