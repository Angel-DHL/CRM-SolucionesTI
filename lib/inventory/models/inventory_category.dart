// lib/inventory/models/inventory_category.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Íconos predefinidos para categorías
enum CategoryIcon {
  // Tecnología
  computer('computer', Icons.computer_rounded),
  phone('phone', Icons.phone_android_rounded),
  tablet('tablet', Icons.tablet_rounded),
  printer('printer', Icons.print_rounded),
  keyboard('keyboard', Icons.keyboard_rounded),
  monitor('monitor', Icons.monitor_rounded),
  headphones('headphones', Icons.headphones_rounded),
  cable('cable', Icons.cable_rounded),
  storage('storage', Icons.storage_rounded),
  memory('memory', Icons.memory_rounded),

  // Oficina
  office('office', Icons.business_center_rounded),
  desk('desk', Icons.desk_rounded),
  chair('chair', Icons.chair_rounded),
  folder('folder', Icons.folder_rounded),
  document('document', Icons.description_rounded),

  // Herramientas
  tools('tools', Icons.build_rounded),
  handyman('handyman', Icons.handyman_rounded),
  construction('construction', Icons.construction_rounded),
  engineering('engineering', Icons.engineering_rounded),

  // Servicios
  support('support', Icons.support_agent_rounded),
  cloud('cloud', Icons.cloud_rounded),
  code('code', Icons.code_rounded),
  design('design', Icons.design_services_rounded),
  analytics('analytics', Icons.analytics_rounded),

  // Transporte
  vehicle('vehicle', Icons.directions_car_rounded),
  truck('truck', Icons.local_shipping_rounded),

  // Otros
  inventory('inventory', Icons.inventory_2_rounded),
  category('category', Icons.category_rounded),
  box('box', Icons.inbox_rounded),
  package('package', Icons.inventory_rounded),
  other('other', Icons.widgets_rounded);

  final String value;
  final IconData icon;
  const CategoryIcon(this.value, this.icon);

  static CategoryIcon fromString(String? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => CategoryIcon.category,
    );
  }
}

/// Colores predefinidos para categorías
enum CategoryColor {
  blue('blue', Color(0xFF2196F3)),
  indigo('indigo', Color(0xFF3F51B5)),
  purple('purple', Color(0xFF9C27B0)),
  pink('pink', Color(0xFFE91E63)),
  red('red', Color(0xFFF44336)),
  orange('orange', Color(0xFFFF9800)),
  amber('amber', Color(0xFFFFC107)),
  yellow('yellow', Color(0xFFFFEB3B)),
  lime('lime', Color(0xFFCDDC39)),
  green('green', Color(0xFF4CAF50)),
  teal('teal', Color(0xFF009688)),
  cyan('cyan', Color(0xFF00BCD4)),
  brown('brown', Color(0xFF795548)),
  grey('grey', Color(0xFF9E9E9E)),
  blueGrey('blueGrey', Color(0xFF607D8B));

  final String value;
  final Color color;
  const CategoryColor(this.value, this.color);

  static CategoryColor fromString(String? value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => CategoryColor.blue,
    );
  }
}

class InventoryCategory {
  // ═══════════════════════════════════════════════════════════
  // IDENTIFICACIÓN
  // ═══════════════════════════════════════════════════════════
  final String id;
  final String? parentId; // ID de categoría padre (null = raíz)

  // ═══════════════════════════════════════════════════════════
  // INFORMACIÓN BÁSICA
  // ═══════════════════════════════════════════════════════════
  final String name; // Nombre de la categoría
  final String? description; // Descripción
  final String slug; // Slug para URLs amigables
  final CategoryIcon icon; // Ícono de la categoría
  final CategoryColor color; // Color de la categoría

  // ═══════════════════════════════════════════════════════════
  // JERARQUÍA Y ORDEN
  // ═══════════════════════════════════════════════════════════
  final int level; // Nivel de profundidad (0 = raíz)
  final String path; // Ruta completa (ej: "electronica/computadoras/laptops")
  final List<String> ancestorIds; // IDs de ancestros [abuelo, padre]
  final int displayOrder; // Orden de visualización

  // ═══════════════════════════════════════════════════════════
  // CONFIGURACIÓN
  // ═══════════════════════════════════════════════════════════
  final bool isActive; // Está activa
  final bool allowProducts; // Permite productos
  final bool allowServices; // Permite servicios
  final bool allowAssets; // Permite activos

  // ═══════════════════════════════════════════════════════════
  // IMAGEN
  // ═══════════════════════════════════════════════════════════
  final String? imageUrl; // Imagen de la categoría

  // ═══════════════════════════════════════════════════════════
  // METADATOS SEO (opcional para futuro portal web)
  // ═══════════════════════════════════════════════════════════
  final String? metaTitle; // Título SEO
  final String? metaDescription; // Descripción SEO
  final List<String>? metaKeywords; // Palabras clave SEO

  // ═══════════════════════════════════════════════════════════
  // ESTADÍSTICAS (calculadas)
  // ═══════════════════════════════════════════════════════════
  final int itemCount; // Cantidad de ítems en esta categoría
  final int childCategoryCount; // Cantidad de subcategorías

  // ═══════════════════════════════════════════════════════════
  // AUDITORÍA
  // ═══════════════════════════════════════════════════════════
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? lastModifiedBy;

  InventoryCategory({
    required this.id,
    this.parentId,
    required this.name,
    this.description,
    required this.slug,
    required this.icon,
    required this.color,
    this.level = 0,
    required this.path,
    this.ancestorIds = const [],
    this.displayOrder = 0,
    this.isActive = true,
    this.allowProducts = true,
    this.allowServices = true,
    this.allowAssets = true,
    this.imageUrl,
    this.metaTitle,
    this.metaDescription,
    this.metaKeywords,
    this.itemCount = 0,
    this.childCategoryCount = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastModifiedBy,
  });

  // ═══════════════════════════════════════════════════════════
  // CONVERSIÓN DESDE FIRESTORE
  // ═══════════════════════════════════════════════════════════
  static InventoryCategory fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InventoryCategory(
      id: doc.id,
      parentId: data['parentId'],
      name: data['name'] ?? '',
      description: data['description'],
      slug: data['slug'] ?? '',
      icon: CategoryIcon.fromString(data['icon']),
      color: CategoryColor.fromString(data['color']),
      level: data['level'] ?? 0,
      path: data['path'] ?? '',
      ancestorIds: List<String>.from(data['ancestorIds'] ?? []),
      displayOrder: data['displayOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
      allowProducts: data['allowProducts'] ?? true,
      allowServices: data['allowServices'] ?? true,
      allowAssets: data['allowAssets'] ?? true,
      imageUrl: data['imageUrl'],
      metaTitle: data['metaTitle'],
      metaDescription: data['metaDescription'],
      metaKeywords: data['metaKeywords'] != null
          ? List<String>.from(data['metaKeywords'])
          : null,
      itemCount: data['itemCount'] ?? 0,
      childCategoryCount: data['childCategoryCount'] ?? 0,
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
      'parentId': parentId,
      'name': name,
      'description': description,
      'slug': slug,
      'icon': icon.value,
      'color': color.value,
      'level': level,
      'path': path,
      'ancestorIds': ancestorIds,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'allowProducts': allowProducts,
      'allowServices': allowServices,
      'allowAssets': allowAssets,
      'imageUrl': imageUrl,
      'metaTitle': metaTitle,
      'metaDescription': metaDescription,
      'metaKeywords': metaKeywords,
      'itemCount': itemCount,
      'childCategoryCount': childCategoryCount,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  /// Map para actualización (sin sobrescribir createdAt)
  Map<String, dynamic> toUpdateMap() {
    return {
      'parentId': parentId,
      'name': name,
      'description': description,
      'slug': slug,
      'icon': icon.value,
      'color': color.value,
      'level': level,
      'path': path,
      'ancestorIds': ancestorIds,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'allowProducts': allowProducts,
      'allowServices': allowServices,
      'allowAssets': allowAssets,
      'imageUrl': imageUrl,
      'metaTitle': metaTitle,
      'metaDescription': metaDescription,
      'metaKeywords': metaKeywords,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastModifiedBy': lastModifiedBy,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // MÉTODOS ÚTILES
  // ═══════════════════════════════════════════════════════════

  /// Es categoría raíz
  bool get isRoot => parentId == null;

  /// Tiene subcategorías
  bool get hasChildren => childCategoryCount > 0;

  /// Tiene ítems
  bool get hasItems => itemCount > 0;

  /// Nombre completo con path
  String get fullPath => path.replaceAll('/', ' > ');

  /// Generar slug desde nombre
  static String generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  /// CopyWith
  InventoryCategory copyWith({
    String? id,
    String? parentId,
    String? name,
    String? description,
    String? slug,
    CategoryIcon? icon,
    CategoryColor? color,
    int? level,
    String? path,
    List<String>? ancestorIds,
    int? displayOrder,
    bool? isActive,
    bool? allowProducts,
    bool? allowServices,
    bool? allowAssets,
    String? imageUrl,
    String? metaTitle,
    String? metaDescription,
    List<String>? metaKeywords,
    int? itemCount,
    int? childCategoryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? lastModifiedBy,
  }) {
    return InventoryCategory(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      level: level ?? this.level,
      path: path ?? this.path,
      ancestorIds: ancestorIds ?? this.ancestorIds,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      allowProducts: allowProducts ?? this.allowProducts,
      allowServices: allowServices ?? this.allowServices,
      allowAssets: allowAssets ?? this.allowAssets,
      imageUrl: imageUrl ?? this.imageUrl,
      metaTitle: metaTitle ?? this.metaTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      metaKeywords: metaKeywords ?? this.metaKeywords,
      itemCount: itemCount ?? this.itemCount,
      childCategoryCount: childCategoryCount ?? this.childCategoryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }
}
