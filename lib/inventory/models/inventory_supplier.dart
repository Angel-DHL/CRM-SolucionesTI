// lib/inventory/models/inventory_supplier.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Tipo de proveedor
enum SupplierType {
  manufacturer('Fabricante', Icons.factory_rounded),
  distributor('Distribuidor', Icons.local_shipping_rounded),
  wholesaler('Mayorista', Icons.warehouse_rounded),
  retailer('Minorista', Icons.storefront_rounded),
  importer('Importador', Icons.flight_land_rounded),
  service('Servicios', Icons.miscellaneous_services_rounded);

  final String label;
  final IconData icon;
  const SupplierType(this.label, this.icon);

  static SupplierType fromString(String? value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => SupplierType.distributor,
    );
  }
}

/// Estado del proveedor
enum SupplierStatus {
  active('Activo', Color(0xFF4CAF50)),
  inactive('Inactivo', Color(0xFF9E9E9E)),
  suspended('Suspendido', Color(0xFFF44336)),
  pending('Pendiente', Color(0xFFFFC107));

  final String label;
  final Color color;
  const SupplierStatus(this.label, this.color);

  static SupplierStatus fromString(String? value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => SupplierStatus.active,
    );
  }
}

/// Términos de pago
enum PaymentTerms {
  immediate('Inmediato', 0),
  net15('Neto 15', 15),
  net30('Neto 30', 30),
  net45('Neto 45', 45),
  net60('Neto 60', 60),
  net90('Neto 90', 90),
  custom('Personalizado', -1);

  final String label;
  final int days;
  const PaymentTerms(this.label, this.days);

  static PaymentTerms fromString(String? value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentTerms.net30,
    );
  }
}

class InventorySupplier {
  // ═══════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ═══════════════════════════════════════════════════════════
  final String id;
  final String code; // Código único (PRV-001)

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN BÁSICA
  // ═══════════════════════════════════════════════════════════
  final String name; // Nombre/Razón social
  final String? tradeName; // Nombre comercial
  final SupplierType type; // Tipo de proveedor
  final SupplierStatus status; // Estado
  final String? description; // Descripción
  final String? logoUrl; // URL del logo

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN FISCAL
  // ═══════════════════════════════════════════════════════════
  final String? taxId; // RFC / NIT / RUC
  final String? legalName; // Razón social legal
  final String? taxRegime; // Régimen fiscal

  // ═══════════════════════════════════════════════════════════
  // CONTACTO PRINCIPAL
  // ═══════════════════════════════════════════════════════════
  final String? contactName; // Nombre del contacto
  final String? contactPosition; // Cargo del contacto
  final String email; // Email principal
  final String? phone; // Teléfono principal
  final String? mobile; // Celular
  final String? fax; // Fax
  final String? website; // Sitio web

  // ═══════════════════════════════════════════════════════════
  // CONTACTOS ADICIONALES
  // ═══════════════════════════════════════════════════════════
  final List<SupplierContact>? additionalContacts;

  // ═══════════════════════════════════════════════════════════
  // DIRECCIÓN PRINCIPAL
  // ═══════════════════════════════════════════════════════════
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN COMERCIAL
  // ═══════════════════════════════════════════════════════════
  final PaymentTerms paymentTerms; // Términos de pago
  final int? customPaymentDays; // Días personalizados
  final double? creditLimit; // Límite de crédito
  final String? currency; // Moneda preferida
  final double? discountPercentage; // Descuento general (%)
  final int? leadTimeDays; // Tiempo de entrega (días)
  final double? minimumOrderAmount; // Pedido mínimo
  final double? shippingCost; // Costo de envío estándar
  final bool freeShippingAbove; // Envío gratis sobre monto
  final double? freeShippingThreshold; // Monto para envío gratis

  // ═══════════════════════════════════════════════════════════
  // CATEGORÍAS Y PRODUCTOS
  // ═══════════════════════════════════════════════════════════
  final List<String>? categoryIds; // Categorías que provee
  final List<String>? productIds; // Productos específicos
  final List<String>? tags; // Etiquetas

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN BANCARIA
  // ═══════════════════════════════════════════════════════════
  final String? bankName; // Nombre del banco
  final String? bankAccountNumber; // Número de cuenta
  final String? bankAccountType; // Tipo de cuenta
  final String? bankRoutingNumber; // Número de ruta / CLABE
  final String? swiftCode; // Código SWIFT

  // ═══════════════════════════════════════════════════════════
  // CALIFICACIÓN Y EVALUACIÓN
  // ═══════════════════════════════════════════════════════════
  final double? rating; // Calificación (1-5)
  final int? totalOrders; // Total de órdenes
  final int? completedOrders; // Órdenes completadas
  final int? cancelledOrders; // Órdenes canceladas
  final double? onTimeDeliveryRate; // Tasa de entrega a tiempo (%)
  final double? qualityRate; // Tasa de calidad (%)
  final DateTime? lastOrderDate; // Última fecha de pedido

  // ═══════════════════════════════════════════════════════════
  // DOCUMENTOS
  // ═══════════════════════════════════════════════════════════
  final List<String>? contractUrls; // Contratos
  final List<String>? certificateUrls; // Certificaciones
  final List<String>? otherDocumentUrls; // Otros documentos

  // ═══════════════════════════════════════════════════════════
  // NOTAS
  // ═══════════════════════════════════════════════════════════
  final String? notes; // Notas generales
  final String? internalNotes; // Notas internas

  // ═══════════════════════════════════════════════════════════
  // CONFIGURACIÓN
  // ═══════════════════════════════════════════════════════════
  final bool isPreferred; // Proveedor preferido
  final bool autoReorder; // Reordenar automático
  final bool sendPurchaseOrders; // Enviar órdenes por email

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA
  // ═══════════════════════════════════════════════════════════
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? lastModifiedBy;

  InventorySupplier({
    required this.id,
    required this.code,
    required this.name,
    this.tradeName,
    required this.type,
    required this.status,
    this.description,
    this.logoUrl,
    this.taxId,
    this.legalName,
    this.taxRegime,
    this.contactName,
    this.contactPosition,
    required this.email,
    this.phone,
    this.mobile,
    this.fax,
    this.website,
    this.additionalContacts,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    required this.paymentTerms,
    this.customPaymentDays,
    this.creditLimit,
    this.currency,
    this.discountPercentage,
    this.leadTimeDays,
    this.minimumOrderAmount,
    this.shippingCost,
    this.freeShippingAbove = false,
    this.freeShippingThreshold,
    this.categoryIds,
    this.productIds,
    this.tags,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountType,
    this.bankRoutingNumber,
    this.swiftCode,
    this.rating,
    this.totalOrders,
    this.completedOrders,
    this.cancelledOrders,
    this.onTimeDeliveryRate,
    this.qualityRate,
    this.lastOrderDate,
    this.contractUrls,
    this.certificateUrls,
    this.otherDocumentUrls,
    this.notes,
    this.internalNotes,
    this.isPreferred = false,
    this.autoReorder = false,
    this.sendPurchaseOrders = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastModifiedBy,
  });

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN DESDE FIRESTORE
  // ═══════════════════════════════════════════════════════════
  static InventorySupplier fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parsear contactos adicionales
    List<SupplierContact>? contacts;
    if (data['additionalContacts'] != null) {
      contacts = (data['additionalContacts'] as List)
          .map((c) => SupplierContact.fromMap(c))
          .toList();
    }

    return InventorySupplier(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      tradeName: data['tradeName'],
      type: SupplierType.fromString(data['type']),
      status: SupplierStatus.fromString(data['status']),
      description: data['description'],
      logoUrl: data['logoUrl'],
      taxId: data['taxId'],
      legalName: data['legalName'],
      taxRegime: data['taxRegime'],
      contactName: data['contactName'],
      contactPosition: data['contactPosition'],
      email: data['email'] ?? '',
      phone: data['phone'],
      mobile: data['mobile'],
      fax: data['fax'],
      website: data['website'],
      additionalContacts: contacts,
      addressLine1: data['addressLine1'],
      addressLine2: data['addressLine2'],
      city: data['city'],
      state: data['state'],
      postalCode: data['postalCode'],
      country: data['country'],
      paymentTerms: PaymentTerms.fromString(data['paymentTerms']),
      customPaymentDays: data['customPaymentDays'],
      creditLimit: data['creditLimit']?.toDouble(),
      currency: data['currency'],
      discountPercentage: data['discountPercentage']?.toDouble(),
      leadTimeDays: data['leadTimeDays'],
      minimumOrderAmount: data['minimumOrderAmount']?.toDouble(),
      shippingCost: data['shippingCost']?.toDouble(),
      freeShippingAbove: data['freeShippingAbove'] ?? false,
      freeShippingThreshold: data['freeShippingThreshold']?.toDouble(),
      categoryIds: data['categoryIds'] != null
          ? List<String>.from(data['categoryIds'])
          : null,
      productIds: data['productIds'] != null
          ? List<String>.from(data['productIds'])
          : null,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      bankName: data['bankName'],
      bankAccountNumber: data['bankAccountNumber'],
      bankAccountType: data['bankAccountType'],
      bankRoutingNumber: data['bankRoutingNumber'],
      swiftCode: data['swiftCode'],
      rating: data['rating']?.toDouble(),
      totalOrders: data['totalOrders'],
      completedOrders: data['completedOrders'],
      cancelledOrders: data['cancelledOrders'],
      onTimeDeliveryRate: data['onTimeDeliveryRate']?.toDouble(),
      qualityRate: data['qualityRate']?.toDouble(),
      lastOrderDate: data['lastOrderDate'] != null
          ? (data['lastOrderDate'] as Timestamp).toDate()
          : null,
      contractUrls: data['contractUrls'] != null
          ? List<String>.from(data['contractUrls'])
          : null,
      certificateUrls: data['certificateUrls'] != null
          ? List<String>.from(data['certificateUrls'])
          : null,
      otherDocumentUrls: data['otherDocumentUrls'] != null
          ? List<String>.from(data['otherDocumentUrls'])
          : null,
      notes: data['notes'],
      internalNotes: data['internalNotes'],
      isPreferred: data['isPreferred'] ?? false,
      autoReorder: data['autoReorder'] ?? false,
      sendPurchaseOrders: data['sendPurchaseOrders'] ?? true,
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
    return {
      'code': code,
      'name': name,
      'tradeName': tradeName,
      'type': type.name,
      'status': status.name,
      'description': description,
      'logoUrl': logoUrl,
      'taxId': taxId,
      'legalName': legalName,
      'taxRegime': taxRegime,
      'contactName': contactName,
      'contactPosition': contactPosition,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'fax': fax,
      'website': website,
      'additionalContacts': additionalContacts?.map((c) => c.toMap()).toList(),
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'paymentTerms': paymentTerms.name,
      'customPaymentDays': customPaymentDays,
      'creditLimit': creditLimit,
      'currency': currency,
      'discountPercentage': discountPercentage,
      'leadTimeDays': leadTimeDays,
      'minimumOrderAmount': minimumOrderAmount,
      'shippingCost': shippingCost,
      'freeShippingAbove': freeShippingAbove,
      'freeShippingThreshold': freeShippingThreshold,
      'categoryIds': categoryIds,
      'productIds': productIds,
      'tags': tags,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountType': bankAccountType,
      'bankRoutingNumber': bankRoutingNumber,
      'swiftCode': swiftCode,
      'rating': rating,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'onTimeDeliveryRate': onTimeDeliveryRate,
      'qualityRate': qualityRate,
      'lastOrderDate': lastOrderDate != null
          ? Timestamp.fromDate(lastOrderDate!)
          : null,
      'contractUrls': contractUrls,
      'certificateUrls': certificateUrls,
      'otherDocumentUrls': otherDocumentUrls,
      'notes': notes,
      'internalNotes': internalNotes,
      'isPreferred': isPreferred,
      'autoReorder': autoReorder,
      'sendPurchaseOrders': sendPurchaseOrders,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTODOS ÚTILES
  // ═══════════════════════════════════════════════════════════

  /// Dirección completa
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

  /// Días de pago
  int get effectivePaymentDays {
    if (paymentTerms == PaymentTerms.custom) {
      return customPaymentDays ?? 30;
    }
    return paymentTerms.days;
  }

  /// Tasa de cumplimiento
  double get fulfillmentRate {
    if (totalOrders == null || totalOrders == 0) return 0;
    return ((completedOrders ?? 0) / totalOrders!) * 100;
  }

  /// Tiene crédito disponible
  bool hasCreditAvailable(double amount) {
    if (creditLimit == null) return true;
    return amount <= creditLimit!;
  }

  /// Calificación en estrellas
  int get ratingStars => (rating ?? 0).round();

  /// CopyWith (simplificado para brevedad)
  InventorySupplier copyWith({
    String? id,
    String? code,
    String? name,
    String? tradeName,
    SupplierType? type,
    SupplierStatus? status,
    String? description,
    String? logoUrl,
    String? email,
    PaymentTerms? paymentTerms,
    bool? isPreferred,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
    // ... agregar más campos según necesidad
  }) {
    return InventorySupplier(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      tradeName: tradeName ?? this.tradeName,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      email: email ?? this.email,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      isPreferred: isPreferred ?? this.isPreferred,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      // ... mantener otros campos existentes
      taxId: this.taxId,
      legalName: this.legalName,
      taxRegime: this.taxRegime,
      contactName: this.contactName,
      contactPosition: this.contactPosition,
      phone: this.phone,
      mobile: this.mobile,
      fax: this.fax,
      website: this.website,
      additionalContacts: this.additionalContacts,
      addressLine1: this.addressLine1,
      addressLine2: this.addressLine2,
      city: this.city,
      state: this.state,
      postalCode: this.postalCode,
      country: this.country,
      customPaymentDays: this.customPaymentDays,
      creditLimit: this.creditLimit,
      currency: this.currency,
      discountPercentage: this.discountPercentage,
      leadTimeDays: this.leadTimeDays,
      minimumOrderAmount: this.minimumOrderAmount,
      shippingCost: this.shippingCost,
      freeShippingAbove: this.freeShippingAbove,
      freeShippingThreshold: this.freeShippingThreshold,
      categoryIds: this.categoryIds,
      productIds: this.productIds,
      tags: this.tags,
      bankName: this.bankName,
      bankAccountNumber: this.bankAccountNumber,
      bankAccountType: this.bankAccountType,
      bankRoutingNumber: this.bankRoutingNumber,
      swiftCode: this.swiftCode,
      rating: this.rating,
      totalOrders: this.totalOrders,
      completedOrders: this.completedOrders,
      cancelledOrders: this.cancelledOrders,
      onTimeDeliveryRate: this.onTimeDeliveryRate,
      qualityRate: this.qualityRate,
      lastOrderDate: this.lastOrderDate,
      contractUrls: this.contractUrls,
      certificateUrls: this.certificateUrls,
      otherDocumentUrls: this.otherDocumentUrls,
      notes: this.notes,
      internalNotes: this.internalNotes,
      autoReorder: this.autoReorder,
      sendPurchaseOrders: this.sendPurchaseOrders,
    );
  }
}

/// Modelo auxiliar para contactos adicionales
class SupplierContact {
  final String name;
  final String? position;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? department;
  final bool isPrimary;
  final String? notes;

  SupplierContact({
    required this.name,
    this.position,
    this.email,
    this.phone,
    this.mobile,
    this.department,
    this.isPrimary = false,
    this.notes,
  });

  static SupplierContact fromMap(Map<String, dynamic> map) {
    return SupplierContact(
      name: map['name'] ?? '',
      position: map['position'],
      email: map['email'],
      phone: map['phone'],
      mobile: map['mobile'],
      department: map['department'],
      isPrimary: map['isPrimary'] ?? false,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'department': department,
      'isPrimary': isPrimary,
      'notes': notes,
    };
  }
}
