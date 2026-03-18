// lib/operatividad/models/oper_comment.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class OperComment {
  final String id;
  final String text;
  final String authorUid;
  final String authorEmail;
  final DateTime createdAt;
  final DateTime? editedAt;
  final List<String> mentions; // UIDs mencionados con @
  final String? replyToId; // ID del comentario al que responde

  const OperComment({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorEmail,
    required this.createdAt,
    this.editedAt,
    this.mentions = const [],
    this.replyToId,
  });

  static OperComment fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return OperComment(
      id: doc.id,
      text: (d['text'] ?? '').toString(),
      authorUid: (d['authorUid'] ?? '').toString(),
      authorEmail: (d['authorEmail'] ?? '').toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (d['editedAt'] as Timestamp?)?.toDate(),
      mentions: List<String>.from(d['mentions'] ?? const []),
      replyToId: d['replyToId'] as String?,
    );
  }

  static Map<String, dynamic> createMap({
    required String text,
    required String authorUid,
    required String authorEmail,
    List<String> mentions = const [],
    String? replyToId,
  }) {
    return {
      'text': text,
      'authorUid': authorUid,
      'authorEmail': authorEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'editedAt': null,
      'mentions': mentions,
      'replyToId': replyToId,
    };
  }

  bool get isEdited => editedAt != null;

  String get authorInitial =>
      authorEmail.isNotEmpty ? authorEmail.substring(0, 1).toUpperCase() : '?';

  String get authorName => authorEmail.split('@').first;

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
