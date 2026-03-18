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
}
