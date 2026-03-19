// lib/operatividad/services/activity_log_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/firebase_helper.dart';
import '../models/oper_activity.dart';
import '../models/oper_log.dart';

/// Servicio centralizado para registrar cambios en actividades.
///
/// Registra automáticamente en la subcolección `logs` de cada actividad.
class ActivityLogService {
  ActivityLogService._();

  static CollectionReference<Map<String, dynamic>> _logsRef(String activityId) {
    return FirebaseHelper.operActivities.doc(activityId).collection('logs');
  }

  static String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  static String get _currentEmail =>
      FirebaseAuth.instance.currentUser?.email ?? '';

  /// Registra un log genérico
  static Future<void> log({
    required String activityId,
    required LogAction action,
    required String description,
    Map<String, dynamic>? previousValue,
    Map<String, dynamic>? newValue,
  }) async {
    try {
      await _logsRef(activityId).add(
        OperLog.createMap(
          action: action,
          description: description,
          performedByUid: _currentUid,
          performedByEmail: _currentEmail,
          previousValue: previousValue,
          newValue: newValue,
        ),
      );
    } catch (e) {
      // Silenciar errores de log para no afectar la operación principal
      // ignore: avoid_print
      print('Error registrando log: $e');
    }
  }

  /// Registra creación de actividad
  static Future<void> logCreated({
    required String activityId,
    required String title,
  }) async {
    await log(
      activityId: activityId,
      action: LogAction.created,
      description: 'Actividad "$title" creada',
    );
  }

  /// Registra cambio de estado
  static Future<void> logStatusChange({
    required String activityId,
    required OperStatus previousStatus,
    required OperStatus newStatus,
  }) async {
    await log(
      activityId: activityId,
      action: LogAction.statusChanged,
      description:
          'Estado cambiado de "${previousStatus.label}" a "${newStatus.label}"',
      previousValue: {'status': previousStatus.value},
      newValue: {'status': newStatus.value},
    );
  }

  /// Registra cambio de progreso
  static Future<void> logProgressChange({
    required String activityId,
    required int previousProgress,
    required int newProgress,
  }) async {
    await log(
      activityId: activityId,
      action: LogAction.progressChanged,
      description: 'Progreso actualizado de $previousProgress% a $newProgress%',
      previousValue: {'progress': previousProgress},
      newValue: {'progress': newProgress},
    );
  }

  /// Registra inicio de trabajo
  static Future<void> logWorkStarted({required String activityId}) async {
    await log(
      activityId: activityId,
      action: LogAction.workStarted,
      description: 'Trabajo iniciado por $_currentEmail',
    );
  }

  /// Registra fin de trabajo
  static Future<void> logWorkEnded({
    required String activityId,
    Duration? duration,
  }) async {
    final durationText = duration != null
        ? ' (${duration.inHours}h ${duration.inMinutes % 60}m)'
        : '';

    await log(
      activityId: activityId,
      action: LogAction.workEnded,
      description: 'Trabajo finalizado por $_currentEmail$durationText',
    );
  }

  /// Registra subida de evidencia
  static Future<void> logEvidenceUploaded({
    required String activityId,
    required String fileName,
  }) async {
    await log(
      activityId: activityId,
      action: LogAction.evidenceUploaded,
      description: 'Evidencia "$fileName" subida por $_currentEmail',
    );
  }

  /// Registra eliminación de evidencia
  static Future<void> logEvidenceDeleted({
    required String activityId,
    required String fileName,
  }) async {
    await log(
      activityId: activityId,
      action: LogAction.evidenceDeleted,
      description: 'Evidencia "$fileName" eliminada por $_currentEmail',
    );
  }

  /// Registra comentario
  static Future<void> logCommentAdded({required String activityId}) async {
    await log(
      activityId: activityId,
      action: LogAction.commentAdded,
      description: 'Comentario agregado por $_currentEmail',
    );
  }

  /// Registra incumplimiento de SLA
  static Future<void> logSlaBreached({
    required String activityId,
    required double slaHours,
  }) async {
    await log(
      activityId: activityId,
      action: LogAction.slaBreached,
      description: 'SLA de ${slaHours}h incumplido',
    );
  }

  /// Registra cambio de prioridad
  static Future<void> logPriorityChanged({
    required String activityId,
    required String previousPriority,
    required String newPriority,
  }) async {
    await log(
      activityId: activityId,
      action: LogAction.priorityChanged,
      description: 'Prioridad cambiada de "$previousPriority" a "$newPriority"',
      previousValue: {'priority': previousPriority},
      newValue: {'priority': newPriority},
    );
  }
}
