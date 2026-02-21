import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreDb {
  FirestoreDb._();

  static const String databaseId = 'crm-solucionesti';

  static FirebaseFirestore get instance => FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: databaseId,
  );
}
