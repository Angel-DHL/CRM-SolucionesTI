// lib/soporte/services/knowledge_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../core/firebase_helper.dart';
import '../models/knowledge_article.dart';
import '../models/support_enums.dart';

class KnowledgeService {
  KnowledgeService._();
  static final KnowledgeService instance = KnowledgeService._();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  // ═══════════════════════════════════════════════════════════
  // ARTÍCULOS DE BASE DE CONOCIMIENTO
  // ═══════════════════════════════════════════════════════════

  Stream<List<KnowledgeArticle>> streamArticles({CaseCategory? category}) {
    Query<Map<String, dynamic>> q = FirebaseHelper.supportArticles;
    if (category != null) {
      q = q.where('categoria', isEqualTo: category.value);
    }
    return q.orderBy('createdAt', descending: true).snapshots().map(
      (s) => s.docs.map(KnowledgeArticle.fromDoc).toList(),
    );
  }

  Future<KnowledgeArticle?> getArticle(String id) async {
    final doc = await FirebaseHelper.supportArticles.doc(id).get();
    if (!doc.exists) return null;
    return KnowledgeArticle.fromDoc(doc);
  }

  Future<String> createArticle(KnowledgeArticle article) async {
    final data = article.toMap();
    data['createdByUid'] = _uid;
    data['createdByEmail'] = _email;
    final doc = await FirebaseHelper.supportArticles.add(data);
    return doc.id;
  }

  Future<void> updateArticle(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await FirebaseHelper.supportArticles.doc(id).update(updates);
  }

  Future<void> incrementViews(String id) async {
    await FirebaseHelper.supportArticles.doc(id).update({
      'vistas': FieldValue.increment(1),
    });
  }

  Future<void> voteUtility(String id) async {
    await FirebaseHelper.supportArticles.doc(id).update({
      'utilidad': FieldValue.increment(1),
    });
  }

  Future<List<KnowledgeArticle>> searchArticles(String query) async {
    // Búsqueda básica por tags y título
    final snap = await FirebaseHelper.supportArticles.get();
    final articles = snap.docs.map(KnowledgeArticle.fromDoc).toList();
    final lowerQuery = query.toLowerCase();

    return articles.where((a) {
      return a.titulo.toLowerCase().contains(lowerQuery) ||
          a.tags.any((t) => t.toLowerCase().contains(lowerQuery)) ||
          a.problemaSintomas.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // FAQs
  // ═══════════════════════════════════════════════════════════

  Stream<List<SupportFaq>> streamFaqs({CaseCategory? category}) {
    Query<Map<String, dynamic>> q = FirebaseHelper.supportFaqs;
    if (category != null) {
      q = q.where('categoria', isEqualTo: category.value);
    }
    return q.orderBy('orden').snapshots().map(
      (s) => s.docs.map(SupportFaq.fromDoc).toList(),
    );
  }

  Future<void> createFaq(SupportFaq faq) async {
    await FirebaseHelper.supportFaqs.add(faq.toMap());
  }

  Future<void> updateFaq(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await FirebaseHelper.supportFaqs.doc(id).update(updates);
  }

  Future<void> deleteFaq(String id) async {
    await FirebaseHelper.supportFaqs.doc(id).delete();
  }

  // ═══════════════════════════════════════════════════════════
  // MANUALES / GUÍAS
  // ═══════════════════════════════════════════════════════════

  Stream<List<SupportManual>> streamManuals() {
    return FirebaseHelper.supportManuals
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(SupportManual.fromDoc).toList());
  }

  Future<String> uploadManual({
    required String nombre,
    required String descripcion,
    required Uint8List fileBytes,
    required String fileName,
    required CaseCategory categoria,
    bool generadoPorIA = false,
  }) async {
    try {
      // Subir a Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('support_manuals')
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = await storageRef.putData(
        fileBytes,
        SettableMetadata(contentType: _getContentType(fileName)),
      );
      final url = await uploadTask.ref.getDownloadURL();

      // Guardar metadata en Firestore
      final manual = SupportManual(
        id: '',
        nombre: nombre,
        descripcion: descripcion,
        url: url,
        fileName: fileName,
        fileSize: fileBytes.length,
        categoria: categoria,
        generadoPorIA: generadoPorIA,
        createdByUid: _uid,
        createdByEmail: _email,
        createdAt: DateTime.now(),
      );

      final doc = await FirebaseHelper.supportManuals.add(manual.toMap());
      return doc.id;
    } catch (e) {
      debugPrint('Error uploading manual: $e');
      rethrow;
    }
  }

  Future<void> deleteManual(String id, String fileName) async {
    try {
      // Eliminar de Storage
      final ref = FirebaseStorage.instance.ref().child('support_manuals').child(fileName);
      await ref.delete();
    } catch (_) {
      // Si no se puede eliminar del storage, continuar
    }
    await FirebaseHelper.supportManuals.doc(id).delete();
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'doc' || 'docx' => 'application/msword',
      'xls' || 'xlsx' => 'application/vnd.ms-excel',
      'ppt' || 'pptx' => 'application/vnd.ms-powerpoint',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }
}
