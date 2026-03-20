// lib/inventory/models/inventory_item.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'inventory_enums.dart';

class InventoryItem {
  // ═══════════════════════════════════════════════════════════
  // IDENTIFICACIÓN Y TIPO
  // ═══════════════════════════════════════════════════════════
  final String id;
  final InventoryItemType type;
  final InventoryItemStatus status;

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN BÁSICA (OBLIGATORIA)
  // ═══════════════════════════════════════════════════════════
  final String name; // Nombre del ítem
  final String sku; // SKU único (Stock Keeping Unit)
  final String categoryId; // ID de categoría principal
  final String? subcategoryId; // ID de subcategoría (opcional)
  final UnitOfMeasure unitOfMeasure; // Unidad de medida

  // ═══════════════════════════════════════════════════════════
  // DESCRIPCIÓN Y METADATOS
  // ═══════════════════════════════════════════════════════════
  final String description; // Descripción corta
  final String? detailedDescription; // Descripción detallada (markdown)
  final List<String> tags; // Etiquetas (ej: ['urgente', 'importado'])
  final String? barcode; // Código de barras
  final String? qrCode; // Código QR

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN FINANCIERA
  // ═══════════════════════════════════════════════════════════
  final double purchasePrice; // Precio de compra
  final double sellingPrice; // Precio de venta
  final double? rentalPrice; // Precio de renta (opcional)
  final String currency; // Moneda (MXN, USD, etc.)
  final double? taxRate; // Tasa de impuesto (%)
  final double? discount; // Descuento (%)

  // ═══════════════════════════════════════════════════════════
  // STOCK Y UBICACIÓN (Solo para productos/activos)
  // ═══════════════════════════════════════════════════════════
  final int stock; // Stock actual
  final int minStock; // Stock mínimo
  final int? maxStock; // Stock máximo (opcional)
  final int? reorderPoint; // Punto de reorden
  final String? defaultLocationId; // Ubicación predeterminada
  final Map<String, int>?
  stockByLocation; // Stock por ubicación {'loc1': 10, 'loc2': 5}

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN ESPECÍFICA DE PRODUCTOS
  // ═══════════════════════════════════════════════════════════
  final String? brand; // Marca
  final String? model; // Modelo
  final String? manufacturer; // Fabricante
  final String? serialNumber; // Número de serie
  final DateTime? expirationDate; // Fecha de vencimiento
  final String? batchNumber; // Número de lote
  final double? weight; // Peso (kg)
  final Map<String, double>?
  dimensions; // Dimensiones {'length': 10, 'width': 5, 'height': 3}

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN ESPECÍFICA DE ACTIVOS
  // ═══════════════════════════════════════════════════════════
  final AssetCondition? assetCondition; // Condición del activo
  final DateTime? purchaseDate; // Fecha de compra
  final DateTime? warrantyExpiryDate; // Fecha de expiración de garantía
  final double? depreciationRate; // Tasa de depreciación anual (%)
  final String? assignedToUserId; // Asignado a (ID del usuario)
  final DateTime? lastMaintenanceDate; // Última fecha de mantenimiento
  final DateTime? nextMaintenanceDate; // Próxima fecha de mantenimiento

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN ESPECÍFICA DE SERVICIOS
  // ═══════════════════════════════════════════════════════════
  final int? estimatedDuration; // Duración estimada (minutos)
  final List<String>? requiredSkills; // Habilidades requeridas
  final bool? isRecurring; // Es un servicio recurrente

  // ═══════════════════════════════════════════════════════════
  // PROVEEDORES Y RELACIONES
  // ═══════════════════════════════════════════════════════════
  final String? primarySupplierId; // Proveedor principal
  final List<String>? alternativeSupplierIds; // Proveedores alternativos
  final String? manufacturerContactInfo; // Info de contacto del fabricante

  // ═══════════════════════════════════════════════════════════
  // IMÁGENES Y ARCHIVOS
  // ═══════════════════════════════════════════════════════════
  final String? primaryImageUrl; // Imagen principal
  final List<String> additionalImageUrls; // Imágenes adicionales (máx 4)
  final List<String>?
  documentUrls; // Documentos adjuntos (manuales, facturas, etc.)

  // ═══════════════════════════════════════════════════════════
  // CONFIGURACIÓN Y PREFERENCIAS
  // ═══════════════════════════════════════════════════════════
  final bool isActive; // Está activo
  final bool isFeatured; // Es destacado
  final bool allowBackorder; // Permite pedidos sin stock
  final bool trackInventory; // Rastrear inventario
  final int? displayOrder; // Orden de visualización

  // ═══════════════════════════════════════════════════════════
  // NOTAS Y OBSERVACIONES
  // ═══════════════════════════════════════════════════════════
  final String? internalNotes; // Notas internas (privadas)
  final String? publicNotes; // Notas públicas (visibles para clientes)

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA Y METADATOS
  // ═══════════════════════════════════════════════════════════
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // UID del creador
  final String? lastModifiedBy; // UID del último modificador
  final Map<String, dynamic>? customFields; // Campos personalizados adicionales

  // ═══════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════
  InventoryItem({
    required this.id,
    required this.type,
    required this.status,
    required this.name,
    required this.sku,
    required this.categoryId,
    this.subcategoryId,
    required this.unitOfMeasure,
    required this.description,
    this.detailedDescription,
    this.tags = const [],
    this.barcode,
    this.qrCode,
    required this.purchasePrice,
    required this.sellingPrice,
    this.rentalPrice,
    this.currency = 'MXN',
    this.taxRate,
    this.discount,
    this.stock = 0,
    this.minStock = 0,
    this.maxStock,
    this.reorderPoint,
    this.defaultLocationId,
    this.stockByLocation,
    this.brand,
    this.model,
    this.manufacturer,
    this.serialNumber,
    this.expirationDate,
    this.batchNumber,
    this.weight,
    this.dimensions,
    this.assetCondition,
    this.purchaseDate,
    this.warrantyExpiryDate,
    this.depreciationRate,
    this.assignedToUserId,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.estimatedDuration,
    this.requiredSkills,
    this.isRecurring,
    this.primarySupplierId,
    this.alternativeSupplierIds,
    this.manufacturerContactInfo,
    this.primaryImageUrl,
    this.additionalImageUrls = const [],
    this.documentUrls,
    this.isActive = true,
    this.isFeatured = false,
    this.allowBackorder = false,
    this.trackInventory = true,
    this.displayOrder,
    this.internalNotes,
    this.publicNotes,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastModifiedBy,
    this.customFields,
  });

  // ═══════════════════════════════════════════════════════════
  // MÉTODOS DE CONVERSIÓN
  // ═══════════════════════════════════════════════════════════

  /// Convertir desde DocumentSnapshot de Firestore
  static InventoryItem fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InventoryItem(
      id: doc.id,
      type: InventoryItemType.fromString(data['type']),
      status: InventoryItemStatus.fromString(data['status']),
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      categoryId: data['categoryId'] ?? '',
      subcategoryId: data['subcategoryId'],
      unitOfMeasure: UnitOfMeasure.fromString(data['unitOfMeasure']),
      description: data['description'] ?? '',
      detailedDescription: data['detailedDescription'],
      tags: List<String>.from(data['tags'] ?? []),
      barcode: data['barcode'],
      qrCode: data['qrCode'],
      purchasePrice: (data['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (data['sellingPrice'] ?? 0).toDouble(),
      rentalPrice: data['rentalPrice']?.toDouble(),
      currency: data['currency'] ?? 'MXN',
      taxRate: data['taxRate']?.toDouble(),
      discount: data['discount']?.toDouble(),
      stock: data['stock'] ?? 0,
      minStock: data['minStock'] ?? 0,
      maxStock: data['maxStock'],
      reorderPoint: data['reorderPoint'],
      defaultLocationId: data['defaultLocationId'],
      stockByLocation: data['stockByLocation'] != null
          ? Map<String, int>.from(data['stockByLocation'])
          : null,
      brand: data['brand'],
      model: data['model'],
      manufacturer: data['manufacturer'],
      serialNumber: data['serialNumber'],
      expirationDate: data['expirationDate'] != null
          ? (data['expirationDate'] as Timestamp).toDate()
          : null,
      batchNumber: data['batchNumber'],
      weight: data['weight']?.toDouble(),
      dimensions: data['dimensions'] != null
          ? Map<String, double>.from(data['dimensions'])
          : null,
      assetCondition: data['assetCondition'] != null
          ? AssetCondition.fromString(data['assetCondition'])
          : null,
      purchaseDate: data['purchaseDate'] != null
          ? (data['purchaseDate'] as Timestamp).toDate()
          : null,
      warrantyExpiryDate: data['warrantyExpiryDate'] != null
          ? (data['warrantyExpiryDate'] as Timestamp).toDate()
          : null,
      depreciationRate: data['depreciationRate']?.toDouble(),
      assignedToUserId: data['assignedToUserId'],
      lastMaintenanceDate: data['lastMaintenanceDate'] != null
          ? (data['lastMaintenanceDate'] as Timestamp).toDate()
          : null,
      nextMaintenanceDate: data['nextMaintenanceDate'] != null
          ? (data['nextMaintenanceDate'] as Timestamp).toDate()
          : null,
      estimatedDuration: data['estimatedDuration'],
      requiredSkills: data['requiredSkills'] != null
          ? List<String>.from(data['requiredSkills'])
          : null,
      isRecurring: data['isRecurring'],
      primarySupplierId: data['primarySupplierId'],
      alternativeSupplierIds: data['alternativeSupplierIds'] != null
          ? List<String>.from(data['alternativeSupplierIds'])
          : null,
      manufacturerContactInfo: data['manufacturerContactInfo'],
      primaryImageUrl: data['primaryImageUrl'],
      additionalImageUrls: List<String>.from(data['additionalImageUrls'] ?? []),
      documentUrls: data['documentUrls'] != null
          ? List<String>.from(data['documentUrls'])
          : null,
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      allowBackorder: data['allowBackorder'] ?? false,
      trackInventory: data['trackInventory'] ?? true,
      displayOrder: data['displayOrder'],
      internalNotes: data['internalNotes'],
      publicNotes: data['publicNotes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      lastModifiedBy: data['lastModifiedBy'],
      customFields: data['customFields'],
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'status': status.name,
      'name': name,
      'sku': sku,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'unitOfMeasure': unitOfMeasure.name,
      'description': description,
      'detailedDescription': detailedDescription,
      'tags': tags,
      'barcode': barcode,
      'qrCode': qrCode,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'rentalPrice': rentalPrice,
      'currency': currency,
      'taxRate': taxRate,
      'discount': discount,
      'stock': stock,
      'minStock': minStock,
      'maxStock': maxStock,
      'reorderPoint': reorderPoint,
      'defaultLocationId': defaultLocationId,
      'stockByLocation': stockByLocation,
      'brand': brand,
      'model': model,
      'manufacturer': manufacturer,
      'serialNumber': serialNumber,
      'expirationDate': expirationDate != null
          ? Timestamp.fromDate(expirationDate!)
          : null,
      'batchNumber': batchNumber,
      'weight': weight,
      'dimensions': dimensions,
      'assetCondition': assetCondition?.name,
      'purchaseDate': purchaseDate != null
          ? Timestamp.fromDate(purchaseDate!)
          : null,
      'warrantyExpiryDate': warrantyExpiryDate != null
          ? Timestamp.fromDate(warrantyExpiryDate!)
          : null,
      'depreciationRate': depreciationRate,
      'assignedToUserId': assignedToUserId,
      'lastMaintenanceDate': lastMaintenanceDate != null
          ? Timestamp.fromDate(lastMaintenanceDate!)
          : null,
      'nextMaintenanceDate': nextMaintenanceDate != null
          ? Timestamp.fromDate(nextMaintenanceDate!)
          : null,
      'estimatedDuration': estimatedDuration,
      'requiredSkills': requiredSkills,
      'isRecurring': isRecurring,
      'primarySupplierId': primarySupplierId,
      'alternativeSupplierIds': alternativeSupplierIds,
      'manufacturerContactInfo': manufacturerContactInfo,
      'primaryImageUrl': primaryImageUrl,
      'additionalImageUrls': additionalImageUrls,
      'documentUrls': documentUrls,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'allowBackorder': allowBackorder,
      'trackInventory': trackInventory,
      'displayOrder': displayOrder,
      'internalNotes': internalNotes,
      'publicNotes': publicNotes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
      'customFields': customFields,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTODOS ÚTILES
  // ═══════════════════════════════════════════════════════════

  /// Stock está bajo el mínimo
  bool get isStockLow => trackInventory && stock <= minStock;

  /// Stock está en punto de reorden
  bool get needsReorder =>
      trackInventory && reorderPoint != null && stock <= reorderPoint!;

  /// Tiene garantía vigente
  bool get hasValidWarranty =>
      warrantyExpiryDate != null && warrantyExpiryDate!.isAfter(DateTime.now());

  /// Está vencido (para productos con fecha de caducidad)
  bool get isExpired =>
      expirationDate != null && expirationDate!.isBefore(DateTime.now());

  /// Necesita mantenimiento
  bool get needsMaintenance =>
      nextMaintenanceDate != null &&
      nextMaintenanceDate!.isBefore(DateTime.now());

  /// Margen de ganancia
  double get profitMargin => sellingPrice - purchasePrice;

  /// Margen de ganancia porcentual
  double get profitMarginPercentage =>
      purchasePrice > 0 ? (profitMargin / purchasePrice) * 100 : 0;

  /// Valor total del inventario
  double get totalInventoryValue => purchasePrice * stock;

  /// Crear copia con modificaciones
  InventoryItem copyWith({
    String? id,
    InventoryItemType? type,
    InventoryItemStatus? status,
    String? name,
    String? sku,
    String? categoryId,
    String? subcategoryId,
    UnitOfMeasure? unitOfMeasure,
    String? description,
    String? detailedDescription,
    List<String>? tags,
    String? barcode,
    String? qrCode,
    double? purchasePrice,
    double? sellingPrice,
    double? rentalPrice,
    String? currency,
    double? taxRate,
    double? discount,
    int? stock,
    int? minStock,
    int? maxStock,
    int? reorderPoint,
    String? defaultLocationId,
    Map<String, int>? stockByLocation,
    String? brand,
    String? model,
    String? manufacturer,
    String? serialNumber,
    DateTime? expirationDate,
    String? batchNumber,
    double? weight,
    Map<String, double>? dimensions,
    AssetCondition? assetCondition,
    DateTime? purchaseDate,
    DateTime? warrantyExpiryDate,
    double? depreciationRate,
    String? assignedToUserId,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    int? estimatedDuration,
    List<String>? requiredSkills,
    bool? isRecurring,
    String? primarySupplierId,
    List<String>? alternativeSupplierIds,
    String? manufacturerContactInfo,
    String? primaryImageUrl,
    List<String>? additionalImageUrls,
    List<String>? documentUrls,
    bool? isActive,
    bool? isFeatured,
    bool? allowBackorder,
    bool? trackInventory,
    int? displayOrder,
    String? internalNotes,
    String? publicNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
    Map<String, dynamic>? customFields,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      description: description ?? this.description,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      tags: tags ?? this.tags,
      barcode: barcode ?? this.barcode,
      qrCode: qrCode ?? this.qrCode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      rentalPrice: rentalPrice ?? this.rentalPrice,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
      discount: discount ?? this.discount,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      defaultLocationId: defaultLocationId ?? this.defaultLocationId,
      stockByLocation: stockByLocation ?? this.stockByLocation,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      expirationDate: expirationDate ?? this.expirationDate,
      batchNumber: batchNumber ?? this.batchNumber,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      assetCondition: assetCondition ?? this.assetCondition,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
      depreciationRate: depreciationRate ?? this.depreciationRate,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      isRecurring: isRecurring ?? this.isRecurring,
      primarySupplierId: primarySupplierId ?? this.primarySupplierId,
      alternativeSupplierIds:
          alternativeSupplierIds ?? this.alternativeSupplierIds,
      manufacturerContactInfo:
          manufacturerContactInfo ?? this.manufacturerContactInfo,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      additionalImageUrls: additionalImageUrls ?? this.additionalImageUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      allowBackorder: allowBackorder ?? this.allowBackorder,
      trackInventory: trackInventory ?? this.trackInventory,
      displayOrder: displayOrder ?? this.displayOrder,
      internalNotes: internalNotes ?? this.internalNotes,
      publicNotes: publicNotes ?? this.publicNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      customFields: customFields ?? this.customFields,
    );
  }
}
