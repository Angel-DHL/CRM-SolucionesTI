// lib/core/firebase_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Helper centralizado para acceder a Firestore con el database ID correcto.
class FirebaseHelper {
  FirebaseHelper._();

  /// ID de la base de datos (si usas una diferente a "(default)")
  static const String databaseId = 'crm-solucionesti';

  /// Instancia de Firestore configurada con el databaseId correcto
  static FirebaseFirestore get db {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: databaseId,
    );
  }

  /// Referencia a la colección de actividades
  static CollectionReference<Map<String, dynamic>> get operActivities {
    return db.collection('oper_activities');
  }

  /// Referencia a la colección de usuarios
  static CollectionReference<Map<String, dynamic>> get users {
    return db.collection('users');
  }

  // ═══════════════════════════════════════════════════════════
  // COLECCIONES DE INVENTARIO
  // ═══════════════════════════════════════════════════════════

  static CollectionReference<Map<String, dynamic>> get inventoryItems =>
      db.collection('inventory_items');

  static CollectionReference<Map<String, dynamic>> get inventoryCategories =>
      db.collection('inventory_categories');

  static CollectionReference<Map<String, dynamic>> get inventoryLocations =>
      db.collection('inventory_locations');

  static CollectionReference<Map<String, dynamic>> get inventoryMovements =>
      db.collection('inventory_movements');

  static CollectionReference<Map<String, dynamic>> get inventorySuppliers =>
      db.collection('inventory_suppliers');

  static CollectionReference<Map<String, dynamic>> get inventoryAuditLogs =>
      db.collection('inventory_audit_logs');

  // Contadores para números secuenciales
  static CollectionReference<Map<String, dynamic>> get inventoryCounters =>
      db.collection('inventory_counters');

  // ═══════════════════════════════════════════════════════════
  // COLECCIONES DE CRM
  // ═══════════════════════════════════════════════════════════

  /// Leads del sitio web (colección existente)
  static CollectionReference<Map<String, dynamic>> get leads =>
      db.collection('leads');

  /// Contactos del CRM (leads convertidos + manuales)
  static CollectionReference<Map<String, dynamic>> get crmContacts =>
      db.collection('crm_contacts');

  /// Logs de actividad del CRM (notas, llamadas, cambios de estatus)
  static CollectionReference<Map<String, dynamic>> get crmActivityLogs =>
      db.collection('crm_activity_logs');

  // ═══════════════════════════════════════════════════════════
  // COLECCIONES DE VENTAS
  // ═══════════════════════════════════════════════════════════

  static CollectionReference<Map<String, dynamic>> get salesQuotes =>
      db.collection('sales_quotes');

  static CollectionReference<Map<String, dynamic>> get salesOrders =>
      db.collection('sales_orders');

  static CollectionReference<Map<String, dynamic>> get salesCounters =>
      db.collection('sales_counters');
}
