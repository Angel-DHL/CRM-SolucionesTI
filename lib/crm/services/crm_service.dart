// lib/crm/services/crm_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase_helper.dart';
import '../models/crm_enums.dart';
import '../models/crm_contact.dart';
import '../models/crm_activity_log.dart';

/// Filtros de búsqueda para contactos CRM
class CrmFilters {
  final String? searchQuery;
  final ContactStatus? status;
  final ContactSource? source;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final String? sortBy;
  final bool sortDescending;

  const CrmFilters({
    this.searchQuery,
    this.status,
    this.source,
    this.createdAfter,
    this.createdBefore,
    this.sortBy,
    this.sortDescending = true,
  });

  static const CrmFilters none = CrmFilters();

  bool get hasFilters =>
      searchQuery != null ||
      status != null ||
      source != null ||
      createdAfter != null ||
      createdBefore != null;

  CrmFilters copyWith({
    String? searchQuery,
    ContactStatus? status,
    ContactSource? source,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? sortBy,
    bool? sortDescending,
  }) {
    return CrmFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      status: status ?? this.status,
      source: source ?? this.source,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }
}

/// Servicio principal del módulo CRM
class CrmService {
  CrmService._();
  static final CrmService instance = CrmService._();

  // Referencias
  CollectionReference<Map<String, dynamic>> get _contactsRef =>
      FirebaseHelper.crmContacts;

  CollectionReference<Map<String, dynamic>> get _leadsRef =>
      FirebaseHelper.leads;

  CollectionReference<Map<String, dynamic>> get _logsRef =>
      FirebaseHelper.crmActivityLogs;

  // ═══════════════════════════════════════════════════════════
  // LEADS DEL SITIO WEB
  // ═══════════════════════════════════════════════════════════

  /// Stream de leads del sitio web (colección 'leads')
  Stream<List<Map<String, dynamic>>> streamLeads({bool onlyUnread = false}) {
    Query<Map<String, dynamic>> query = _leadsRef
        .orderBy('createdAt', descending: true);

    if (onlyUnread) {
      query = query.where('leido', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Marcar un lead como leído
  Future<void> markLeadAsRead(String leadId) async {
    try {
      await _leadsRef.doc(leadId).update({
        'leido': true,
      });
    } catch (e) {
      debugPrint('❌ Error marcando lead como leído: $e');
      rethrow;
    }
  }

  /// Convertir un lead del sitio web a contacto CRM
  Future<String> convertLeadToContact(String leadId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Obtener documento original del lead
      final leadDoc = await _leadsRef.doc(leadId).get();
      if (!leadDoc.exists) throw Exception('Lead no encontrado');

      // Verificar si ya fue convertido
      final existing = await _contactsRef
          .where('leadId', isEqualTo: leadId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('Este lead ya fue convertido');
      }

      // Crear contacto desde el lead
      final contact = CrmContact.fromLeadDoc(leadDoc, user.uid);
      final data = contact.toMap();

      // Guardar en crm_contacts
      final docRef = await _contactsRef.add(data);

      // Marcar lead original como procesado
      await _leadsRef.doc(leadId).update({
        'leido': true,
        'estado': 'convertido',
        'convertedAt': FieldValue.serverTimestamp(),
        'convertedBy': user.uid,
        'crmContactId': docRef.id,
      });

      // Log de conversión
      await _addLog(
        contactId: docRef.id,
        type: CrmActivityType.conversion,
        titulo: 'Lead convertido a contacto CRM',
        descripcion: 'Importado desde formulario web',
      );

      debugPrint('✅ Lead convertido: $leadId → ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error convirtiendo lead: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CRUD DE CONTACTOS
  // ═══════════════════════════════════════════════════════════

  /// Crear nuevo contacto manualmente
  Future<String> createContact(CrmContact contact) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final data = contact.copyWith(
        createdBy: user.uid,
        lastModifiedBy: user.uid,
      ).toMap();

      final docRef = await _contactsRef.add(data);

      await _addLog(
        contactId: docRef.id,
        type: CrmActivityType.nota,
        titulo: 'Contacto creado manualmente',
      );

      debugPrint('✅ Contacto creado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creando contacto: $e');
      rethrow;
    }
  }

  /// Obtener contacto por ID
  Future<CrmContact?> getContactById(String id) async {
    try {
      final doc = await _contactsRef.doc(id).get();
      if (!doc.exists) return null;
      return CrmContact.fromDoc(doc);
    } catch (e) {
      debugPrint('❌ Error obteniendo contacto: $e');
      rethrow;
    }
  }

  /// Stream de un contacto específico
  Stream<CrmContact?> streamContact(String id) {
    return _contactsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CrmContact.fromDoc(doc);
    });
  }

  /// Stream de contactos con filtros
  Stream<List<CrmContact>> streamContacts({
    CrmFilters filters = CrmFilters.none,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _contactsRef;

    // Filtros en Firestore
    if (filters.status != null) {
      query = query.where('status', isEqualTo: filters.status!.value);
    }
    if (filters.source != null) {
      query = query.where('source', isEqualTo: filters.source!.value);
    }

    // Ordenamiento
    final sortField = filters.sortBy ?? 'createdAt';
    query = query.orderBy(sortField, descending: filters.sortDescending);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      var contacts = snapshot.docs.map(CrmContact.fromDoc).toList();

      // Filtros en cliente (búsqueda de texto)
      if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
        final q = filters.searchQuery!.toLowerCase();
        contacts = contacts.where((c) {
          return c.nombre.toLowerCase().contains(q) ||
              c.apellidos.toLowerCase().contains(q) ||
              c.email.toLowerCase().contains(q) ||
              c.telefono.contains(q) ||
              (c.empresa?.toLowerCase().contains(q) ?? false) ||
              (c.mensaje?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      if (filters.createdAfter != null) {
        contacts = contacts
            .where((c) => c.createdAt.isAfter(filters.createdAfter!))
            .toList();
      }
      if (filters.createdBefore != null) {
        contacts = contacts
            .where((c) => c.createdAt.isBefore(filters.createdBefore!))
            .toList();
      }

      return contacts;
    });
  }

  /// Stream de todos los clientes activos (para selector en operatividad)
  Stream<List<CrmContact>> streamActiveClients() {
    return _contactsRef
        .where('status', isEqualTo: ContactStatus.cliente.value)
        .snapshots()
        .map((s) {
          final clients = s.docs.map(CrmContact.fromDoc).toList();
          clients.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
          return clients;
        });
  }

  /// Stream de todos los contactos (para selector general)
  Stream<List<CrmContact>> streamAllContacts() {
    return _contactsRef
        .orderBy('nombre')
        .snapshots()
        .map((s) => s.docs.map(CrmContact.fromDoc).toList());
  }

  /// Actualizar contacto
  Future<void> updateContact(CrmContact contact) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final data = contact.copyWith(lastModifiedBy: user.uid).toUpdateMap();
      await _contactsRef.doc(contact.id).update(data);
      debugPrint('✅ Contacto actualizado: ${contact.id}');
    } catch (e) {
      debugPrint('❌ Error actualizando contacto: $e');
      rethrow;
    }
  }

  /// Cambiar estatus de un contacto
  Future<void> updateStatus(String contactId, ContactStatus newStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Obtener estatus anterior
      final doc = await _contactsRef.doc(contactId).get();
      if (!doc.exists) throw Exception('Contacto no encontrado');

      final oldStatus = (doc.data()?['status'] ?? 'lead') as String;

      await _contactsRef.doc(contactId).update({
        'status': newStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': user.uid,
      });

      // Log automático del cambio
      final oldLabel = ContactStatusX.from(oldStatus).label;
      final newLabel = newStatus.label;

      await _addLog(
        contactId: contactId,
        type: CrmActivityType.cambioEstatus,
        titulo: 'Estatus cambiado: $oldLabel → $newLabel',
        previousStatus: oldStatus,
        newStatus: newStatus.value,
      );

      debugPrint('✅ Estatus actualizado: $contactId → ${newStatus.value}');
    } catch (e) {
      debugPrint('❌ Error actualizando estatus: $e');
      rethrow;
    }
  }

  /// Soft delete (marcar como inactivo)
  Future<void> deactivateContact(String contactId) async {
    await updateStatus(contactId, ContactStatus.inactivo);
  }

  /// Eliminar contacto permanentemente
  Future<void> deleteContact(String contactId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      // Eliminar logs asociados
      final logs = await _logsRef
          .where('contactId', isEqualTo: contactId)
          .get();
      final batch = FirebaseHelper.db.batch();
      for (final doc in logs.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_contactsRef.doc(contactId));
      await batch.commit();

      debugPrint('✅ Contacto eliminado: $contactId');
    } catch (e) {
      debugPrint('❌ Error eliminando contacto: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LOGS DE ACTIVIDAD
  // ═══════════════════════════════════════════════════════════

  /// Agregar log de actividad
  Future<void> addActivityLog({
    required String contactId,
    required CrmActivityType type,
    required String titulo,
    String? descripcion,
  }) async {
    await _addLog(
      contactId: contactId,
      type: type,
      titulo: titulo,
      descripcion: descripcion,
    );
  }

  Future<void> _addLog({
    required String contactId,
    required CrmActivityType type,
    required String titulo,
    String? descripcion,
    String? previousStatus,
    String? newStatus,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final log = CrmActivityLog(
        id: '',
        contactId: contactId,
        type: type,
        titulo: titulo,
        descripcion: descripcion,
        previousStatus: previousStatus,
        newStatus: newStatus,
        createdAt: DateTime.now(),
        createdBy: user.uid,
        createdByEmail: user.email,
      );

      await _logsRef.add(log.toMap());
    } catch (e) {
      debugPrint('❌ Error agregando log CRM: $e');
    }
  }

  /// Stream del historial de un contacto
  Stream<List<CrmActivityLog>> streamActivityLogs(String contactId) {
    return _logsRef
        .where('contactId', isEqualTo: contactId)
        .snapshots()
        .map((s) {
          final logs = s.docs.map(CrmActivityLog.fromDoc).toList();
          logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return logs;
        });
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADÍSTICAS
  // ═══════════════════════════════════════════════════════════

  /// Conteo por estatus para el dashboard
  Stream<Map<ContactStatus, int>> streamStatusCounts() {
    return _contactsRef.snapshots().map((snapshot) {
      final counts = <ContactStatus, int>{};
      for (final status in ContactStatus.values) {
        counts[status] = 0;
      }
      for (final doc in snapshot.docs) {
        final statusStr = doc.data()['status'] as String?;
        final status = ContactStatusX.from(statusStr);
        counts[status] = (counts[status] ?? 0) + 1;
      }
      return counts;
    });
  }

  /// Stream de leads no leídos (badge count)
  Stream<int> streamUnreadLeadsCount() {
    return _leadsRef
        .where('leido', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }
}
