// lib/core/services/push_notifications_service.dart
// Servicio de notificaciones push con Firebase Messaging

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejar mensajes cuando la app esta en background
  print('Mensaje en background: ${message.messageId}');
}

class PushNotificationsService {
  static final PushNotificationsService _instance = PushNotificationsService._internal();
  factory PushNotificationsService() => _instance;
  PushNotificationsService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Canal de notificaciones para Android
  static const _androidChannel = AndroidNotificationChannel(
    'tutormatch_default',
    'TutorMatch Notificaciones',
    description: 'Notificaciones de asesorias y mensajes',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Solicitar permisos (iOS)
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Configurar notificaciones locales
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Crear canal de Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Escuchar mensajes en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Obtener y registrar token
    await _registerToken();

    // Actualizar token cuando cambia
    _messaging.onTokenRefresh.listen((newToken) => _sendTokenToServer(newToken));
  }

  Future<void> _registerToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _sendTokenToServer(token);
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await ApiClient().post('/notifications/token', data: {
        'token': token,
        'platform': 'android',
      });
    } catch (_) {}
  }

  Future<void> removeToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await ApiClient().delete('/notifications/token');
        await _messaging.deleteToken();
      }
    } catch (_) {}
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}

final pushNotificationsProvider = Provider<PushNotificationsService>(
  (_) => PushNotificationsService(),
);
