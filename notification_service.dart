import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🔔 Background handler (MUST be top-level)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint("🔔 Background notification received");

  if (message.notification != null) {
    await NotificationService.showNotification(
      message.notification!.title ?? '',
      message.notification!.body ?? '',
    );
  }
}

class NotificationService {
  /// Local notification plugin
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Notification channel (Android)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications',
    importance: Importance.max,
    playSound: true,
  );

  /// 🔔 Initialize notification system
  static Future<void> init() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    /// Request notification permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    /// Important for foreground notifications
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    /// Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("🔔 Notification tapped");
      },
    );

    /// Create Android notification channel
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    /// 🔔 Foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("🔔 Foreground notification received");

      if (message.notification != null) {
        showNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
        );
      }
    });

    /// 🔔 When notification clicked (background state)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🔔 Notification clicked (background)");
    });

    /// 🔔 Background notifications
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    /// 🔑 Get FCM token
    String? token = await messaging.getToken();
    debugPrint("🔥 FCM TOKEN: $token");
  }

  /// 🔔 Show local notification
  static Future<void> showNotification(
    String title,
    String body,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      ticker: 'ticker',
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    /// Unique ID
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
    );
  }
}
