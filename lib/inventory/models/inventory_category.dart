// lib/inventory/models/inventory_category.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Íconos predefinidos para categorías
enum CategoryIcon {
  // ══════════════════════════════════════
  // HARDWARE / EQUIPOS
  // ══════════════════════════════════════
  computer('computer', Icons.computer_rounded),
  laptop('laptop', Icons.laptop_rounded),
  desktopMac('desktop_mac', Icons.desktop_mac_rounded),
  desktopWindows('desktop_windows', Icons.desktop_windows_rounded),
  phone('phone', Icons.phone_android_rounded),
  phoneIphone('phone_iphone', Icons.phone_iphone_rounded),
  tablet('tablet', Icons.tablet_rounded),
  printer('printer', Icons.print_rounded),
  keyboard('keyboard', Icons.keyboard_rounded),
  mouse('mouse', Icons.mouse_rounded),
  monitor('monitor', Icons.monitor_rounded),
  headphones('headphones', Icons.headphones_rounded),
  headset('headset', Icons.headset_mic_rounded),
  speaker('speaker', Icons.speaker_rounded),
  webcam('webcam', Icons.videocam_rounded),
  camera('camera', Icons.camera_alt_rounded),
  scanner('scanner', Icons.scanner_rounded),
  battery('battery', Icons.battery_charging_full_rounded),
  powerSupply('power_supply', Icons.power_rounded),
  usb('usb', Icons.usb_rounded),

  // ══════════════════════════════════════
  // REDES E INFRAESTRUCTURA
  // ══════════════════════════════════════
  cable('cable', Icons.cable_rounded),
  wifi('wifi', Icons.wifi_rounded),
  router('router', Icons.router_rounded),
  ethernet('ethernet', Icons.settings_ethernet_rounded),
  bluetooth('bluetooth', Icons.bluetooth_rounded),
  hotspot('hotspot', Icons.wifi_tethering_rounded),
  dns('dns', Icons.dns_rounded),
  hub('hub', Icons.hub_rounded),
  lan('lan', Icons.lan_rounded),
  cellTower('cell_tower', Icons.cell_tower_rounded),
  satellite('satellite', Icons.satellite_alt_rounded),

  // ══════════════════════════════════════
  // SERVIDORES Y ALMACENAMIENTO
  // ══════════════════════════════════════
  storage('storage', Icons.storage_rounded),
  memory('memory', Icons.memory_rounded),
  server('server', Icons.dns_rounded),
  database('database', Icons.dataset_rounded),
  cloudStorage('cloud_storage', Icons.cloud_upload_rounded),
  backup('backup', Icons.backup_rounded),
  sdCard('sd_card', Icons.sd_card_rounded),
  hardDrive('hard_drive', Icons.save_rounded),
  chip('chip', Icons.developer_board_rounded),

  // ══════════════════════════════════════
  // SEGURIDAD
  // ══════════════════════════════════════
  security('security', Icons.security_rounded),
  shield('shield', Icons.shield_rounded),
  lock('lock', Icons.lock_rounded),
  vpn('vpn', Icons.vpn_lock_rounded),
  fingerprint('fingerprint', Icons.fingerprint_rounded),
  key('key', Icons.vpn_key_rounded),
  firewall('firewall', Icons.local_fire_department_rounded),
  verifiedUser('verified_user', Icons.verified_user_rounded),
  privacyTip('privacy_tip', Icons.privacy_tip_rounded),

  // ══════════════════════════════════════
  // SOFTWARE Y DESARROLLO
  // ══════════════════════════════════════
  code('code', Icons.code_rounded),
  terminal('terminal', Icons.terminal_rounded),
  bug('bug', Icons.bug_report_rounded),
  api('api', Icons.api_rounded),
  integration('integration', Icons.integration_instructions_rounded),
  apps('apps', Icons.apps_rounded),
  webApp('web_app', Icons.web_rounded),
  mobileApp('mobile_app', Icons.app_shortcut_rounded),
  dataObject('data_object', Icons.data_object_rounded),
  smartToy('smart_toy', Icons.smart_toy_rounded),

  // ══════════════════════════════════════
  // SOPORTE Y SERVICIOS TI
  // ══════════════════════════════════════
  support('support', Icons.support_agent_rounded),
  helpDesk('help_desk', Icons.contact_support_rounded),
  liveHelp('live_help', Icons.live_help_rounded),
  troubleshoot('troubleshoot', Icons.troubleshoot_rounded),
  buildCircle('build_circle', Icons.build_circle_rounded),
  settingsApp('settings_app', Icons.settings_applications_rounded),
  systemUpdate('system_update', Icons.system_update_rounded),
  update('update', Icons.update_rounded),
  sync('sync', Icons.sync_rounded),
  speed('speed', Icons.speed_rounded),
  monitoring('monitoring', Icons.monitor_heart_rounded),

  // ══════════════════════════════════════
  // CLOUD Y SERVICIOS
  // ══════════════════════════════════════
  cloud('cloud', Icons.cloud_rounded),
  cloudSync('cloud_sync', Icons.cloud_sync_rounded),
  cloudDone('cloud_done', Icons.cloud_done_rounded),
  design('design', Icons.design_services_rounded),
  analytics('analytics', Icons.analytics_rounded),
  insights('insights', Icons.insights_rounded),
  dashboard('dashboard', Icons.dashboard_rounded),

  // ══════════════════════════════════════
  // OFICINA
  // ══════════════════════════════════════
  office('office', Icons.business_center_rounded),
  desk('desk', Icons.desk_rounded),
  chair('chair', Icons.chair_rounded),
  folder('folder', Icons.folder_rounded),
  document('document', Icons.description_rounded),
  email('email', Icons.email_rounded),
  calendarMonth('calendar', Icons.calendar_month_rounded),

  // ══════════════════════════════════════
  // HERRAMIENTAS
  // ══════════════════════════════════════
  tools('tools', Icons.build_rounded),
  handyman('handyman', Icons.handyman_rounded),
  construction('construction', Icons.construction_rounded),
  engineering('engineering', Icons.engineering_rounded),
  electricBolt('electric_bolt', Icons.electric_bolt_rounded),
  precision('precision', Icons.precision_manufacturing_rounded),

  // ══════════════════════════════════════
  // TRANSPORTE
  // ══════════════════════════════════════
  vehicle('vehicle', Icons.directions_car_rounded),
  truck('truck', Icons.local_shipping_rounded),

  // ══════════════════════════════════════
  // OTROS / GENERAL
  // ══════════════════════════════════════
  inventory('inventory', Icons.inventory_2_rounded),
  category('category', Icons.category_rounded),
  box('box', Icons.inbox_rounded),
  package('package', Icons.inventory_rounded),
  qrCode('qr_code', Icons.qr_code_rounded),
  tag('tag', Icons.label_rounded),
  recycling('recycling', Icons.recycling_rounded),
  science('science', Icons.science_rounded),
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
