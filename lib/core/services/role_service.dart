import 'package:cloud_firestore/cloud_firestore.dart';
import '../role.dart';
import '../firebase_helper.dart';

class RoleService {
  static final CollectionReference<Map<String, dynamic>> _rolesCol =
      FirebaseHelper.db.collection('roles');

  /// Obtiene todos los roles disponibles
  static Stream<List<UserRole>> get rolesStream {
    return _rolesCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserRole.fromMap(doc.data())).toList();
    });
  }

  /// Obtiene un rol por su ID
  static Future<UserRole?> getRole(String roleId) async {
    final doc = await _rolesCol.doc(roleId).get();
    if (!doc.exists) return null;
    return UserRole.fromMap(doc.data()!);
  }

  /// Sembrar roles iniciales si la colección está vacía
  static Future<void> seedInitialRoles() async {
    final snapshot = await _rolesCol.limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Ya hay roles

    final initialRoles = [
      UserRole.admin,
      UserRole.soporteTecnico,
      UserRole.soporteSistemas,
    ];

    for (final role in initialRoles) {
      await saveRole(role);
    }
  }

  /// Crea o actualiza un rol
  static Future<void> saveRole(UserRole role) async {
    await _rolesCol.doc(role.id).set(role.toMap());
  }

  /// Elimina un rol
  static Future<void> deleteRole(String roleId) async {
    // Evitar eliminar roles básicos
    if (roleId == 'admin') return;
    await _rolesCol.doc(roleId).delete();
  }
}
