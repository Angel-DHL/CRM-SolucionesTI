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

  /// Stream de todos los usuarios
  static Stream<List<Map<String, dynamic>>> get usersStream {
    return _usersCol.orderBy('firstName').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
    });
  }

  /// Obtener un usuario por UID
  static Future<Map<String, dynamic>?> getUserById(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) return null;
    return {'uid': doc.id, ...doc.data()!};
  }

  /// Buscar usuarios por nombre o email
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final snapshot = await _usersCol.get();
    final q = query.toLowerCase();
    return snapshot.docs
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .where((u) {
          final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          return name.contains(q) || email.contains(q);
        })
        .toList();
  }

  /// Obtener estadísticas de usuarios
  static Future<Map<String, int>> getUserStats() async {
    final snapshot = await _usersCol.get();
    final docs = snapshot.docs.map((d) => d.data()).toList();
    final total = docs.length;
    final active = docs.where((d) => d['active'] != false).length;
    final inactive = total - active;

    // Conteo por rol
    final roleCount = <String, int>{};
    for (final d in docs) {
      final role = (d['role'] ?? 'soporte_tecnico').toString();
      roleCount[role] = (roleCount[role] ?? 0) + 1;
    }

    return {
      'total': total,
      'active': active,
      'inactive': inactive,
      ...roleCount,
    };
  }

  /// Obtener usuarios por rol
  static Future<List<Map<String, dynamic>>> getUsersByRole(String roleId) async {
    final snapshot = await _usersCol.where('role', isEqualTo: roleId).get();
    return snapshot.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
  }

  /// Conteo de usuarios por rol
  static Future<int> countUsersByRole(String roleId) async {
    final snapshot = await _usersCol.where('role', isEqualTo: roleId).get();
    return snapshot.docs.length;
  }

  /// Actualizar perfil de un usuario (admin)
  static Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _usersCol.doc(uid).update(data);
  }

  /// Actualiza el rol de un usuario
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
      debugPrint('Error al actualizar rol: $e');
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
