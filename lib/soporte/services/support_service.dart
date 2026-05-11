// lib/soporte/services/support_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/firebase_helper.dart';
import '../models/support_case.dart';
import '../models/support_enums.dart';

class SupportService {
  SupportService._();
  static final SupportService instance = SupportService._();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  // ═══════════════════════════════════════════════════════════
  // FOLIOS AUTOMÁTICOS
  // ═══════════════════════════════════════════════════════════

  Future<String> _nextFolio() async {
    try {
      final ref = FirebaseHelper.supportCounters.doc('SPT');
      final result = await FirebaseHelper.db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        int current = 0;
        if (snap.exists) {
          current = (snap.data()?['current'] ?? 0) as int;
        }
        final next = current + 1;
        tx.set(ref, {'current': next}, SetOptions(merge: true));
        return next;
      });
      return 'SPT-${result.toString().padLeft(4, '0')}';
    } catch (e) {
      final ts = DateTime.now().millisecondsSinceEpoch % 100000;
      return 'SPT-$ts';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CRUD DE CASOS
  // ═══════════════════════════════════════════════════════════

  Stream<List<SupportCase>> streamCases({CaseStatus? status, CaseCategory? category}) {
    Query<Map<String, dynamic>> query = FirebaseHelper.supportCases;

    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category.value);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SupportCase.fromDoc).toList());
  }

  Stream<SupportCase?> streamCase(String id) {
    return FirebaseHelper.supportCases.doc(id).snapshots().map(
      (s) => s.exists ? SupportCase.fromDoc(s) : null,
    );
  }

  Future<String> createCase(SupportCase c) async {
    try {
      final folio = await _nextFolio();
      final data = c.copyWith(
        folio: folio,
        createdByUid: _uid,
        createdByEmail: _email,
      ).toMap();

      final doc = await FirebaseHelper.supportCases.add(data);
      return doc.id;
    } catch (e) {
      debugPrint('Error creating support case: $e');
      rethrow;
    }
  }

  Future<void> updateCase(SupportCase c) async {
    await FirebaseHelper.supportCases.doc(c.id).update(c.toUpdateMap());
  }

  Future<void> changeStatus(String caseId, CaseStatus newStatus) async {
    final updates = <String, dynamic>{
      'status': newStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (newStatus == CaseStatus.resuelto) {
      updates['resolvedAt'] = FieldValue.serverTimestamp();
    }
    if (newStatus == CaseStatus.cerrado) {
      updates['closedAt'] = FieldValue.serverTimestamp();
    }

    await FirebaseHelper.supportCases.doc(caseId).update(updates);
  }

  Future<void> resolveCase(String caseId, String solucion) async {
    await FirebaseHelper.supportCases.doc(caseId).update({
      'status': CaseStatus.resuelto.value,
      'solucion': solucion,
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignCase(String caseId, String uid, String email) async {
    await FirebaseHelper.supportCases.doc(caseId).update({
      'assignedToUid': uid,
      'assignedToEmail': email,
      'status': CaseStatus.enProgreso.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════
  // COMENTARIOS DEL CASO
  // ═══════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> _commentsCol(String caseId) =>
      FirebaseHelper.supportCases.doc(caseId).collection('comments');

  Stream<List<Map<String, dynamic>>> streamComments(String caseId) {
    return _commentsCol(caseId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addComment(String caseId, String text) async {
    await _commentsCol(caseId).add({
      'text': text,
      'authorUid': _uid,
      'authorEmail': _email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════
  // CREAR CASO DESDE OPERATIVIDAD
  // ═══════════════════════════════════════════════════════════

  Future<String> createCaseFromOperActivity({
    required String activityId,
    required String activityTitle,
    required String description,
    CaseCategory category = CaseCategory.otro,
    CasePriority priority = CasePriority.media,
  }) async {
    final c = SupportCase(
      id: '',
      folio: '',
      titulo: 'Soporte: $activityTitle',
      descripcion: description,
      status: CaseStatus.abierto,
      priority: priority,
      category: category,
      origin: CaseOrigin.operatividad,
      originId: activityId,
      tags: ['operatividad', 'auto-generado'],
      createdByUid: _uid,
      createdByEmail: _email,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return createCase(c);
  }

  // ═══════════════════════════════════════════════════════════
  // DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getDashboardStats() async {
    final snap = await FirebaseHelper.supportCases.get();
    final cases = snap.docs.map(SupportCase.fromDoc).toList();

    final abiertos = cases.where((c) => c.status == CaseStatus.abierto).length;
    final enProgreso = cases.where((c) => c.status == CaseStatus.enProgreso).length;
    final resueltos = cases.where((c) => c.status == CaseStatus.resuelto || c.status == CaseStatus.cerrado).length;
    final urgentes = cases.where((c) => c.priority == CasePriority.urgente && c.isOpen).length;

    // Tiempo promedio de resolución
    final resolved = cases.where((c) => c.resolvedAt != null);
    double avgResolution = 0;
    if (resolved.isNotEmpty) {
      final totalMinutes = resolved.fold<int>(0, (s, c) => s + c.tiempoResolucion!.inMinutes);
      avgResolution = totalMinutes / resolved.length;
    }

    // Casos por categoría
    final porCategoria = <String, int>{};
    for (final cat in CaseCategory.values) {
      porCategoria[cat.value] = cases.where((c) => c.category == cat).length;
    }

    return {
      'total': cases.length,
      'abiertos': abiertos,
      'enProgreso': enProgreso,
      'resueltos': resueltos,
      'urgentes': urgentes,
      'avgResolutionMinutes': avgResolution,
      'porCategoria': porCategoria,
    };
  }
}
