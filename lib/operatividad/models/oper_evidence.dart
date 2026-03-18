// lib/operatividad/models/oper_evidence.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class OperEvidence {
  final String id;
  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final String fileType; // 'image', 'document', 'other'
  final int fileSize; // bytes
  final String uploadedByUid;
  final String uploadedByEmail;
  final DateTime uploadedAt;

  const OperEvidence({
    required this.id,
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    this.fileType = 'document',
    this.fileSize = 0,
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
      fileType: (d['fileType'] ?? 'document').toString(),
      fileSize: (d['fileSize'] ?? 0) as int,
      uploadedByUid: (d['uploadedByUid'] ?? '').toString(),
      uploadedByEmail: (d['uploadedByEmail'] ?? '').toString(),
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isImage => fileType == 'image';

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileExtension => fileName.split('.').last.toLowerCase();
}
