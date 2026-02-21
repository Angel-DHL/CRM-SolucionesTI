import 'package:cloud_firestore/cloud_firestore.dart';

enum OperStatus { planned, inProgress, done, verified, blocked }

extension OperStatusX on OperStatus {
  String get value => switch (this) {
    OperStatus.planned => 'planned',
    OperStatus.inProgress => 'in_progress',
    OperStatus.done => 'done',
    OperStatus.verified => 'verified',
    OperStatus.blocked => 'blocked',
  };

  String get label => switch (this) {
    OperStatus.planned => 'Planeada',
    OperStatus.inProgress => 'En progreso',
    OperStatus.done => 'Realizada',
    OperStatus.verified => 'Verificada',
    OperStatus.blocked => 'Bloqueada',
  };

  static OperStatus from(String? v) => switch (v) {
    'planned' => OperStatus.planned,
    'in_progress' => OperStatus.inProgress,
    'done' => OperStatus.done,
    'verified' => OperStatus.verified,
    'blocked' => OperStatus.blocked,
    _ => OperStatus.planned,
  };
}

class OperActivity {
  final String id;
  final String title;
  final String description;
  final DateTime plannedStartAt;
  final DateTime plannedEndAt;

  final List<String> assigneesUids;
  final List<String> assigneesEmails;

  final OperStatus status;
  final int progress; // 0..100

  final DateTime? actualStartAt;
  final DateTime? actualEndAt;

  // Registro de trabajo (inicio/fin de ejecución por el usuario)
  final DateTime? workStartAt;
  final DateTime? workEndAt;

  final String createdByUid;
  final String createdByEmail;

  final DateTime createdAt;
  final DateTime updatedAt;

  const OperActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.plannedStartAt,
    required this.plannedEndAt,
    required this.assigneesUids,
    required this.assigneesEmails,
    required this.status,
    required this.progress,
    required this.actualStartAt,
    required this.actualEndAt,
    required this.workStartAt,
    required this.workEndAt,
    required this.createdByUid,
    required this.createdByEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  static OperActivity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    DateTime ts(Timestamp t) => t.toDate();

    return OperActivity(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      plannedStartAt: ts(d['plannedStartAt'] as Timestamp),
      plannedEndAt: ts(d['plannedEndAt'] as Timestamp),
      assigneesUids: List<String>.from(d['assigneesUids'] ?? const []),
      assigneesEmails: List<String>.from(d['assigneesEmails'] ?? const []),
      status: OperStatusX.from(d['status'] as String?),
      progress: (d['progress'] ?? 0) as int,
      actualStartAt: d['actualStartAt'] == null
          ? null
          : ts(d['actualStartAt'] as Timestamp),
      actualEndAt: d['actualEndAt'] == null
          ? null
          : ts(d['actualEndAt'] as Timestamp),
      workStartAt: d['workStartAt'] == null
          ? null
          : ts(d['workStartAt'] as Timestamp),
      workEndAt: d['workEndAt'] == null
          ? null
          : ts(d['workEndAt'] as Timestamp),
      createdByUid: (d['createdByUid'] ?? '').toString(),
      createdByEmail: (d['createdByEmail'] ?? '').toString(),
      createdAt: ts(d['createdAt'] as Timestamp),
      updatedAt: ts(d['updatedAt'] as Timestamp),
    );
  }

  static Map<String, dynamic> createMap({
    required String title,
    required String description,
    required DateTime plannedStartAt,
    required DateTime plannedEndAt,
    required List<String> assigneesUids,
    required List<String> assigneesEmails,
    required String createdByUid,
    required String createdByEmail,
  }) {
    return {
      'title': title,
      'description': description,
      'plannedStartAt': Timestamp.fromDate(plannedStartAt),
      'plannedEndAt': Timestamp.fromDate(plannedEndAt),
      'assigneesUids': assigneesUids,
      'assigneesEmails': assigneesEmails,
      'status': OperStatus.planned.value,
      'progress': 0,
      'actualStartAt': null,
      'actualEndAt': null,
      'workStartAt': null,
      'workEndAt': null,
      'createdByUid': createdByUid,
      'createdByEmail': createdByEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
