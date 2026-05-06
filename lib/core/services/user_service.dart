import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../firebase_helper.dart';

class UserService {
  static final CollectionReference<Map<String, dynamic>> _usersCol =
      FirebaseHelper.db.collection('users');

  static const String _region = 'us-central1';
  static const String _projectId = 'crm-solucionesti';
  static const String _functionName = 'setUserRole';

  static Uri get _endpoint => Uri.parse(
    'https://$_region-$_projectId.cloudfunctions.net/$_functionName',
  );

  /// Obtiene todos los usuarios
  static Stream<List<Map<String, dynamic>>> get usersStream {
    return _usersCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Actualiza el rol de un usuario tanto en Firestore como en Auth (via Cloud Function)
  static Future<void> updateRole(String uid, String newRole) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final idToken = await user.getIdToken(true);

    try {
      final resp = await http.post(
        _endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'uid': uid,
          'role': newRole,
        }),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final errorData = jsonDecode(resp.body);
        throw Exception(errorData['error'] ?? 'Error HTTP ${resp.statusCode}');
      }
    } catch (e) {
      print('Error al actualizar rol: $e');
      rethrow;
    }
  }

  /// Desactiva un usuario
  static Future<void> toggleUserStatus(String uid, bool active) async {
    await _usersCol.doc(uid).update({'active': active});
  }

  /// Elimina un usuario de Firestore
  static Future<void> deleteUserFirestore(String uid) async {
    await _usersCol.doc(uid).delete();
  }
}
