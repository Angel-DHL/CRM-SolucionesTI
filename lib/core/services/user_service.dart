import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_helper.dart';

class UserService {
  static final CollectionReference<Map<String, dynamic>> _usersCol =
      FirebaseHelper.db.collection('users');

  /// Obtiene todos los usuarios
  static Stream<List<Map<String, dynamic>>> get usersStream {
    return _usersCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Actualiza el rol de un usuario
  static Future<void> updateRole(String uid, String newRole) async {
    // Nota: Esto solo actualiza Firestore. Para actualizar Custom Claims 
    // se requiere una Cloud Function o Admin SDK.
    await _usersCol.doc(uid).update({'role': newRole});
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
