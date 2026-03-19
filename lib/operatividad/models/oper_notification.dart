// lib/operatividad/models/oper_notification.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  activityAssigned,
  activityDueSoon,
  activityOverdue,
  commentReceived,
  statusChanged,
  slaWarning,
  slaBreached,
  workCompleted,
}

extension NotificationTypeX on NotificationType {
  String get value => name;

  String get label => switch (this) {
    NotificationType.activityAssigned => 'Actividad asignada',
    NotificationType.activityDueSoon => 'Actividad por vencer',
    NotificationType.activityOverdue => 'Actividad vencida',
    NotificationType.commentReceived => 'Nuevo comentario',
    NotificationType.statusChanged => 'Estado actualizado',
    NotificationType.slaWarning => 'SLA en riesgo',
    NotificationType.slaBreached => 'SLA incumplido',
    NotificationType.workCompleted => 'Trabajo completado',
  };

  static NotificationType from(String? v) {
    return NotificationType.values.firstWhere(
      (e) => e.value == v,
      orElse: () => NotificationType.activityAssigned,
    );
  }
}

class OperNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String activityId;
  final String activityTitle;
  final String recipientUid;
  final String senderUid;
  final String senderEmail;
  final bool isRead;
  final DateTime createdAt;

  const OperNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.activityId,
    required this.activityTitle,
    required this.recipientUid,
    required this.senderUid,
    required this.senderEmail,
    required this.isRead,
    required this.createdAt,
  });

  static OperNotification fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return OperNotification(
      id: doc.id,
      type: NotificationTypeX.from(d['type'] as String?),
      title: (d['title'] ?? '').toString(),
      body: (d['body'] ?? '').toString(),
      activityId: (d['activityId'] ?? '').toString(),
      activityTitle: (d['activityTitle'] ?? '').toString(),
      recipientUid: (d['recipientUid'] ?? '').toString(),
      senderUid: (d['senderUid'] ?? '').toString(),
      senderEmail: (d['senderEmail'] ?? '').toString(),
      isRead: d['isRead'] == true,
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> createMap({
    required NotificationType type,
    required String title,
    required String body,
    required String activityId,
    required String activityTitle,
    required String recipientUid,
    required String senderUid,
    required String senderEmail,
  }) {
    return {
      'type': type.value,
      'title': title,
      'body': body,
      'activityId': activityId,
      'activityTitle': activityTitle,
      'recipientUid': recipientUid,
      'senderUid': senderUid,
      'senderEmail': senderEmail,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  String get senderName => senderEmail.split('@').first;

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';

    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}';
  }
}
