import 'package:cloud_firestore/cloud_firestore.dart';

class OperEvidence {
  final String id;
  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final String uploadedByUid;
  final String uploadedByEmail;
  final DateTime uploadedAt;

  const OperEvidence({
    required this.id,
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedByUid,
    required this.uploadedByEmail,
    required this.uploadedAt,
  });

  static OperEvidence fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return OperEvidence(
      id: doc.id,
      fileName: (d['fileName'] ?? '').toString(),
      storagePath: (d['storagePath'] ?? '').toString(),
      downloadUrl: (d['downloadUrl'] ?? '').toString(),
      uploadedByUid: (d['uploadedByUid'] ?? '').toString(),
      uploadedByEmail: (d['uploadedByEmail'] ?? '').toString(),
      uploadedAt: (d['uploadedAt'] as Timestamp).toDate(),
    );
  }
}
