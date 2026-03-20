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
  // COLECCIÓN (usando FirebaseHelper para la DB correcta)
  // ══════════════════════════════════════════════════════════

  static CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      FirebaseHelper.db.collection('notifications');

  // ══════════════════════════════════════════════════════════
  // INICIALIZACIÓN
  // ══════════════════════════════════════════════════════════

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
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
      }

      // Configurar notificaciones locales (solo móvil)
      if (!kIsWeb) {
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
      }

      // Listener para mensajes en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Guardar token FCM
      await _saveToken();

      // Listener para cambios de token
      _messaging.onTokenRefresh.listen((token) => _saveToken(token: token));

      _initialized = true;
      debugPrint('✅ NotificationService inicializado');
    } catch (e) {
      debugPrint('⚠️ Error inicializando NotificationService: $e');
      // No lanzar error para que la app siga funcionando
      _initialized = true;
    }
  }

  static Future<void> _saveToken({String? token}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      token ??= await _messaging.getToken();
      if (token == null) return;

      await FirebaseHelper.users.doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Token FCM guardado');
    } catch (e) {
      debugPrint('Error guardando token FCM: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Mensaje en foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    if (!kIsWeb) {
      _showLocalNotification(
        title: notification.title ?? 'Notificación',
        body: notification.body ?? '',
        payload: message.data['activityId'] ?? '',
      );
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notificación tocada: ${response.payload}');
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

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
  // ENVIAR NOTIFICACIONES
  // ══════════════════════════════════════════════════════════

  static Future<void> notifyActivityAssigned({
    required OperActivity activity,
    required List<String> assigneeUids,
  }) async {
    final senderUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final senderEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    for (final uid in assigneeUids) {
      if (uid == senderUid) continue;

      try {
        await _notificationsRef.add(
          OperNotification.createMap(
            type: NotificationType.activityAssigned,
            title: 'Nueva actividad asignada',
            body: 'Se te ha asignado: "${activity.title}"',
            activityId: activity.id,
            activityTitle: activity.title,
            recipientUid: uid,
            senderUid: senderUid,
            senderEmail: senderEmail,
          ),
        );
        debugPrint('✅ Notificación enviada a $uid');
      } catch (e) {
        debugPrint('Error enviando notificación a $uid: $e');
      }
    }
  }

  static Future<void> notifyCommentAdded({
    required OperActivity activity,
    required String commentText,
  }) async {
    final senderUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final senderEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final senderName = senderEmail.split('@').first;

    for (final uid in activity.assigneesUids) {
      if (uid == senderUid) continue;

      try {
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
      } catch (e) {
        debugPrint('Error enviando notificación de comentario: $e');
      }
    }
  }

  static Future<void> notifyStatusChanged({
    required OperActivity activity,
    required OperStatus newStatus,
  }) async {
    final senderUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final senderEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final senderName = senderEmail.split('@').first;

    for (final uid in activity.assigneesUids) {
      if (uid == senderUid) continue;

      try {
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
      } catch (e) {
        debugPrint('Error enviando notificación de estado: $e');
      }
    }
  }

  static Future<void> notifySlaWarning({required OperActivity activity}) async {
    for (final uid in activity.assigneesUids) {
      try {
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
      } catch (e) {
        debugPrint('Error enviando notificación SLA: $e');
      }
    }
  }

  // ══════════════════════════════════════════════════════════
  // LEER NOTIFICACIONES
  // ══════════════════════════════════════════════════════════

  /// Stream de notificaciones del usuario actual
  /// SIN orderBy para evitar necesitar índice compuesto
  static Stream<List<OperNotification>> streamNotifications({int limit = 20}) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      return Stream.value([]);
    }

    debugPrint('🔔 Consultando notificaciones para UID: $uid');

    return _notificationsRef
        .where('recipientUid', isEqualTo: uid)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          debugPrint('🔔 Notificaciones encontradas: ${snapshot.docs.length}');

          final notifications = snapshot.docs
              .map(OperNotification.fromDoc)
              .toList();

          // Ordenar en el cliente (para evitar índice compuesto)
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return notifications;
        });
  }

  /// Stream del conteo de no leídas
  static Stream<int> streamUnreadCount() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      return Stream.value(0);
    }

    return _notificationsRef
        .where('recipientUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Marcar como leída
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marcando como leída: $e');
    }
  }

  /// Marcar todas como leídas
  static Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      final unread = await _notificationsRef
          .where('recipientUid', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseHelper.db.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marcando todas como leídas: $e');
    }
  }

  /// Eliminar notificación
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error eliminando notificación: $e');
    }
  }
}
