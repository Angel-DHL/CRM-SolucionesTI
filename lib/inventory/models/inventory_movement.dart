// lib/inventory/models/inventory_movement.dart

import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'inventory_enums.dart';

class InventoryMovement {
  // ═══════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ═══════════════════════════════════════════════════════════
  final String id;
  final String movementNumber; // Número de movimiento (MOV-2024-001)

  // ═══════════════════════════════════════════════════════════
  // TIPO Y ESTADO
  // ═══════════════════════════════════════════════════════════
  final MovementType type; // Tipo de movimiento
  final MovementStatus status; // Estado del movimiento

  // ═══════════════════════════════════════════════════════════
  // ÍTEM Y CANTIDADES
  // ═══════════════════════════════════════════════════════════
  final String itemId; // ID del ítem
  final String itemName; // Nombre del ítem (desnormalizado)
  final String itemSku; // SKU del ítem (desnormalizado)
  final int quantity; // Cantidad del movimiento
  final int previousStock; // Stock antes del movimiento
  final int newStock; // Stock después del movimiento

  // ═══════════════════════════════════════════════════════════
  // UBICACIONES
  // ═══════════════════════════════════════════════════════════
  final String? fromLocationId; // Ubicación origen
  final String? fromLocationName; // Nombre origen (desnormalizado)
  final String? toLocationId; // Ubicación destino
  final String? toLocationName; // Nombre destino (desnormalizado)

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN FINANCIERA
  // ═══════════════════════════════════════════════════════════
  final double? unitCost; // Costo unitario
  final double? totalCost; // Costo total
  final String? currency; // Moneda

  // ═══════════════════════════════════════════════════════════
  // REFERENCIA EXTERNA
  // ═══════════════════════════════════════════════════════════
  final String? referenceType; // Tipo de referencia (order, return, etc.)
  final String? referenceId; // ID de referencia externa
  final String? referenceNumber; // Número de referencia (factura, orden, etc.)
  final String? supplierId; // ID del proveedor (si aplica)
  final String? supplierName; // Nombre del proveedor
  final String? customerId; // ID del cliente (si aplica)
  final String? customerName; // Nombre del cliente

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN DE LOTE (para productos con lotes)
  // ═══════════════════════════════════════════════════════════
  final String? batchNumber; // Número de lote
  final DateTime? expirationDate; // Fecha de vencimiento
  final String? serialNumbers; // Números de serie (separados por coma)

  // ═══════════════════════════════════════════════════════════
  // RAZÓN Y NOTAS
  // ═══════════════════════════════════════════════════════════
  final String reason; // Razón del movimiento
  final String? notes; // Notas adicionales
  final String? internalNotes; // Notas internas (privadas)

  // ═══════════════════════════════════════════════════════════
  // DOCUMENTOS
  // ═══════════════════════════════════════════════════════════
  final List<String>? attachmentUrls; // URLs de documentos adjuntos

  // ═══════════════════════════════════════════════════════════
  // APROBACIÓN (para movimientos que requieren autorización)
  // ═══════════════════════════════════════════════════════════
  final bool requiresApproval; // Requiere aprobación
  final String? approvedBy; // Aprobado por (UID)
  final DateTime? approvedAt; // Fecha de aprobación
  final String? rejectedBy; // Rechazado por (UID)
  final DateTime? rejectedAt; // Fecha de rechazo
  final String? rejectionReason; // Razón de rechazo

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA COMPLETA
  // ═══════════════════════════════════════════════════════════
  final DateTime createdAt;
  final DateTime? completedAt; // Fecha de completado
  final String createdBy; // UID del creador
  final String? createdByEmail; // Email del creador (desnormalizado)
  final String? createdByName; // Nombre del creador (desnormalizado)
  final String? deviceInfo; // Info del dispositivo
  final String? ipAddress; // Dirección IP

  InventoryMovement({
    required this.id,
    required this.movementNumber,
    required this.type,
    required this.status,
    required this.itemId,
    required this.itemName,
    required this.itemSku,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.fromLocationId,
    this.fromLocationName,
    this.toLocationId,
    this.toLocationName,
    this.unitCost,
    this.totalCost,
    this.currency,
    this.referenceType,
    this.referenceId,
    this.referenceNumber,
    this.supplierId,
    this.supplierName,
    this.customerId,
    this.customerName,
    this.batchNumber,
    this.expirationDate,
    this.serialNumbers,
    required this.reason,
    this.notes,
    this.internalNotes,
    this.attachmentUrls,
    this.requiresApproval = false,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    required this.createdAt,
    this.completedAt,
    required this.createdBy,
    this.createdByEmail,
    this.createdByName,
    this.deviceInfo,
    this.ipAddress,
  });

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN DESDE FIRESTORE
  // ═══════════════════════════════════════════════════════════
  static InventoryMovement fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InventoryMovement(
      id: doc.id,
      movementNumber: data['movementNumber'] ?? '',
      type: MovementType.fromString(data['type']),
      status: MovementStatus.fromString(data['status']),
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemSku: data['itemSku'] ?? '',
      quantity: data['quantity'] ?? 0,
      previousStock: data['previousStock'] ?? 0,
      newStock: data['newStock'] ?? 0,
      fromLocationId: data['fromLocationId'],
      fromLocationName: data['fromLocationName'],
      toLocationId: data['toLocationId'],
      toLocationName: data['toLocationName'],
      unitCost: data['unitCost']?.toDouble(),
      totalCost: data['totalCost']?.toDouble(),
      currency: data['currency'],
      referenceType: data['referenceType'],
      referenceId: data['referenceId'],
      referenceNumber: data['referenceNumber'],
      supplierId: data['supplierId'],
      supplierName: data['supplierName'],
      customerId: data['customerId'],
      customerName: data['customerName'],
      batchNumber: data['batchNumber'],
      expirationDate: data['expirationDate'] != null
          ? (data['expirationDate'] as Timestamp).toDate()
          : null,
      serialNumbers: data['serialNumbers'],
      reason: data['reason'] ?? '',
      notes: data['notes'],
      internalNotes: data['internalNotes'],
      attachmentUrls: data['attachmentUrls'] != null
          ? List<String>.from(data['attachmentUrls'])
          : null,
      requiresApproval: data['requiresApproval'] ?? false,
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedBy: data['rejectedBy'],
      rejectedAt: data['rejectedAt'] != null
          ? (data['rejectedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] ?? '',
      createdByEmail: data['createdByEmail'],
      createdByName: data['createdByName'],
      deviceInfo: data['deviceInfo'],
      ipAddress: data['ipAddress'],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN A MAP PARA FIRESTORE
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic> toMap() {
    return {
      'movementNumber': movementNumber,
      'type': type.name,
      'status': status.name,
      'itemId': itemId,
      'itemName': itemName,
      'itemSku': itemSku,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'fromLocationId': fromLocationId,
      'fromLocationName': fromLocationName,
      'toLocationId': toLocationId,
      'toLocationName': toLocationName,
      'unitCost': unitCost,
      'totalCost': totalCost,
      'currency': currency,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'referenceNumber': referenceNumber,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'customerId': customerId,
      'customerName': customerName,
      'batchNumber': batchNumber,
      'expirationDate': expirationDate != null
          ? Timestamp.fromDate(expirationDate!)
          : null,
      'serialNumbers': serialNumbers,
      'reason': reason,
      'notes': notes,
      'internalNotes': internalNotes,
      'attachmentUrls': attachmentUrls,
      'requiresApproval': requiresApproval,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedBy': rejectedBy,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdBy': createdBy,
      'createdByEmail': createdByEmail,
      'createdByName': createdByName,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTODOS ÚTILES
  // ═══════════════════════════════════════════════════════════

  /// Es un movimiento de entrada
  bool get isIncoming => type.isIncoming;

  /// Es un movimiento de salida
  bool get isOutgoing => type.isOutgoing;

  /// Está pendiente de aprobación
  bool get isPendingApproval =>
      requiresApproval && status == MovementStatus.pending;

  /// Fue aprobado
  bool get isApproved => approvedBy != null && approvedAt != null;

  /// Fue rechazado
  bool get isRejected => rejectedBy != null && rejectedAt != null;

  /// Es una transferencia
  bool get isTransfer => type == MovementType.transfer;

  /// Diferencia de stock
  int get stockDifference => newStock - previousStock;

  /// CopyWith
  InventoryMovement copyWith({
    String? id,
    String? movementNumber,
    MovementType? type,
    MovementStatus? status,
    String? itemId,
    String? itemName,
    String? itemSku,
    int? quantity,
    int? previousStock,
    int? newStock,
    String? fromLocationId,
    String? fromLocationName,
    String? toLocationId,
    String? toLocationName,
    double? unitCost,
    double? totalCost,
    String? currency,
    String? referenceType,
    String? referenceId,
    String? referenceNumber,
    String? supplierId,
    String? supplierName,
    String? customerId,
    String? customerName,
    String? batchNumber,
    DateTime? expirationDate,
    String? serialNumbers,
    String? reason,
    String? notes,
    String? internalNotes,
    List<String>? attachmentUrls,
    bool? requiresApproval,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedBy,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? completedAt,
    String? createdBy,
    String? createdByEmail,
    String? createdByName,
    String? deviceInfo,
    String? ipAddress,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      movementNumber: movementNumber ?? this.movementNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemSku: itemSku ?? this.itemSku,
      quantity: quantity ?? this.quantity,
      previousStock: previousStock ?? this.previousStock,
      newStock: newStock ?? this.newStock,
      fromLocationId: fromLocationId ?? this.fromLocationId,
      fromLocationName: fromLocationName ?? this.fromLocationName,
      toLocationId: toLocationId ?? this.toLocationId,
      toLocationName: toLocationName ?? this.toLocationName,
      unitCost: unitCost ?? this.unitCost,
      totalCost: totalCost ?? this.totalCost,
      currency: currency ?? this.currency,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      batchNumber: batchNumber ?? this.batchNumber,
      expirationDate: expirationDate ?? this.expirationDate,
      serialNumbers: serialNumbers ?? this.serialNumbers,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      internalNotes: internalNotes ?? this.internalNotes,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdByName: createdByName ?? this.createdByName,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }
}

/// Estado del movimiento (agregar al archivo de enums)
enum MovementStatus {
  pending('Pendiente', Color(0xFFFFC107)),
  approved('Aprobado', Color(0xFF4CAF50)),
  rejected('Rechazado', Color(0xFFF44336)),
  completed('Completado', Color(0xFF2196F3)),
  cancelled('Cancelado', Color(0xFF9E9E9E));

  final String label;
  final Color color;
  const MovementStatus(this.label, this.color);

  static MovementStatus fromString(String? value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => MovementStatus.pending,
    );
  }
}
