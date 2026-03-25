import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service centralisé pour les notifications push Firebase FCM
class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'gcaisse_high',
    'G-Caisse Notifications',
    description: 'Notifications importantes G-Caisse',
    importance: Importance.high,
  );

  /// Initialiser FCM + notifications locales
  static Future<void> init(int userId) async {
    // Demander la permission
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Configurer les notifications locales Android
    await _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(initSettings);

    // Récupérer et sauvegarder le token FCM
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveAndSendToken(userId, token);
    }

    // Écouter les rafraîchissements de token
    _fcm.onTokenRefresh.listen((newToken) => _saveAndSendToken(userId, newToken));

    // Notification reçue en foreground
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Notification cliquée depuis background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static Future<void> _saveAndSendToken(int userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    try {
      await ApiService.updateFcmToken(userId, token);
    } catch (_) {}
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
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

  static void _handleNotificationTap(RemoteMessage message) {
    // Navigation selon le type de notification
    final type = message.data['type'];
    switch (type) {
      case 'transfer':
        // Naviguer vers l'historique
        break;
      case 'tontine':
        // Naviguer vers la tontine concernée
        break;
    }
  }

  /// Envoyer une notification locale (ex: confirmation de paiement)
  static Future<void> showLocal({
    required String title,
    required String body,
  }) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
