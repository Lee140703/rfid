import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'notification_service.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/rfid_scan_screen.dart';
import 'screens/onboarding_screen.dart';

/// ✅ Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ✅ Prevent duplicate navigation
bool hasNavigatedFromNotification = false;

/// 🔔 Background notification handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint("🔔 Background Notification Received");

  if (message.notification != null) {
    await NotificationService.showNotification(
      message.notification!.title ?? '',
      message.notification!.body ?? '',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    /// 🔥 Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    /// 🔔 Background handler
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    /// 🔔 Notification setup
    await NotificationService.init();

    /// 🔔 Request permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    /// 🔑 Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint("🔥 FCM TOKEN: $token");

    /// 🔔 Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("🔔 Foreground Notification Received");

      if (message.notification != null) {
        NotificationService.showNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
        );
      }
    });

    /// 🔔 Notification clicked (APP IN BACKGROUND)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!hasNavigatedFromNotification) {
        hasNavigatedFromNotification = true;

        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/rfid_scan',
          (route) => false,
        );
      }
    });

    /// 🔔 App opened from TERMINATED state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!hasNavigatedFromNotification) {
          hasNavigatedFromNotification = true;

          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/rfid_scan',
            (route) => false,
          );
        }
      });
    }
  } catch (e) {
    debugPrint("🔥 Firebase Initialization Error: $e");
  }

  runApp(const AssetApp());
}

class AssetApp extends StatelessWidget {
  const AssetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Asset Management App',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
      ),

      /// 🔥 Start from splash
      home: const SplashScreen(),

      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/rfid_scan': (context) => const RFIDScanScreen(),
      },
    );
  }
}
