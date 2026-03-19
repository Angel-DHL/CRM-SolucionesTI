// lib/operatividad/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/firebase_helper.dart';
import '../models/oper_activity.dart';
import '../models/oper_notification.dart';

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ══════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ══════════════════════════════════════════════════════════

  /// Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    if (_initialized) return;

    // Solicitar permisos
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('✅ Notificaciones autorizadas');
    } else {
      debugPrint('❌ Notificaciones no autorizadas');
      return;
    }

    // Configurar notificaciones locales
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Canal de notificaciones Android
    const androidChannel = AndroidNotificationChannel(
      'operatividad_channel',
      'Operatividad',
      description: 'Notificaciones del módulo de operatividad',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // Listener para mensajes en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Guardar token FCM
    await _saveToken();

    // Listener para cambios de token
    _messaging.onTokenRefresh.listen((token) => _saveToken(token: token));

    _initialized = true;
    debugPrint('✅ NotificationService inicializado');
  }

  /// Guardar el token FCM del dispositivo
  static Future<void> _saveToken({String? token}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    token ??= await _messaging.getToken();
    if (token == null) return;

    try {
      await FirebaseHelper.users.doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Token FCM guardado');
    } catch (e) {
      debugPrint('Error guardando token FCM: $e');
    }
  }

  /// Manejar mensaje en foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      '📩 Mensaje recibido en foreground: ${message.notification?.title}',
    );

    final notification = message.notification;
    if (notification == null) return;

    _showLocalNotification(
      title: notification.title ?? 'Notificación',
      body: notification.body ?? '',
      payload: message.data['activityId'] ?? '',
    );
  }

  /// Callback cuando se toca una notificación
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notificación tocada: ${response.payload}');
    // La navegación se manejará desde el widget que escucha
  }

  /// Mostrar notificación local
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'operatividad_channel',
      'Operatividad',
      channelDescription: 'Notificaciones del módulo de operatividad',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ══════════════════════════════════════════════════════════
  // ENVIAR NOTIFICACIONES (in-app)
  // ══════════════════════════════════════════════════════════

  /// Colección de notificaciones
  static CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      FirebaseHelper.db.collection('notifications');

  /// Enviar notificación de actividad asignada
  static Future<void> notifyActivityAssigned({
    required OperActivity activity,
    required List<String> assigneeUids,
  }) async {
    final senderUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final senderEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    for (final uid in assigneeUids) {
      if (uid == senderUid) continue; // No notificar al que asigna

      await _notificationsRef.add(
        OperNotification.createMap(
          type: NotificationType.activityAssigned,
          title: 'Nueva actividad asignada',
          body: 'Se te ha asignado la actividad "${activity.title}"',
          activityId: activity.id,
          activityTitle: activity.title,
          recipientUid: uid,
          senderUid: senderUid,
          senderEmail: senderEmail,
        ),
      );
    }
  }

  /// Enviar notificación de comentario
  static Future<void> notifyCommentAdded({
    required OperActivity activity,
    required String commentText,
  }) async {
    final senderUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final senderEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final senderName = senderEmail.split('@').first;

    for (final uid in activity.assigneesUids) {
      if (uid == senderUid) continue;

      await _notificationsRef.add(
        OperNotification.createMap(
          type: NotificationType.commentReceived,
          title: 'Nuevo comentario',
          body: '$senderName comentó en "${activity.title}": $commentText',
          activityId: activity.id,
          activityTitle: activity.title,
          recipientUid: uid,
          senderUid: senderUid,
          senderEmail: senderEmail,
        ),
      );
    }
  }

  /// Enviar notificación de cambio de estado
  static Future<void> notifyStatusChanged({
    required OperActivity activity,
    required OperStatus newStatus,
  }) async {
    final senderUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final senderEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final senderName = senderEmail.split('@').first;

    for (final uid in activity.assigneesUids) {
      if (uid == senderUid) continue;

      await _notificationsRef.add(
        OperNotification.createMap(
          type: NotificationType.statusChanged,
          title: 'Estado actualizado',
          body: '$senderName cambió "${activity.title}" a ${newStatus.label}',
          activityId: activity.id,
          activityTitle: activity.title,
          recipientUid: uid,
          senderUid: senderUid,
          senderEmail: senderEmail,
        ),
      );
    }
  }

  /// Enviar notificación de SLA en riesgo
  static Future<void> notifySlaWarning({required OperActivity activity}) async {
    for (final uid in activity.assigneesUids) {
      await _notificationsRef.add(
        OperNotification.createMap(
          type: NotificationType.slaWarning,
          title: '⚠️ SLA en riesgo',
          body:
              'La actividad "${activity.title}" está próxima a incumplir el SLA',
          activityId: activity.id,
          activityTitle: activity.title,
          recipientUid: uid,
          senderUid: 'system',
          senderEmail: 'sistema@crm.com',
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════
  // GESTIÓN DE NOTIFICACIONES
  // ══════════════════════════════════════════════════════════

  /// Stream de notificaciones del usuario actual
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamNotifications({
    int limit = 20,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _notificationsRef
        .where('recipientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Contar notificaciones no leídas
  static Stream<int> streamUnreadCount() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _notificationsRef
        .where('recipientUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Marcar notificación como leída
  static Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({'isRead': true});
  }

  /// Marcar todas como leídas
  static Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final unread = await _notificationsRef
        .where('recipientUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseHelper.db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Eliminar una notificación
  static Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.doc(notificationId).delete();
  }
}
