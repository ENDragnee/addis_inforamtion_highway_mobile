import 'dart:async';
import 'package:addis_information_highway_mobile/services/api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// This function must be a top-level function (not a class method)
// to be handled by the isolate when the app is in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final ApiService _apiService;
  final GlobalKey<NavigatorState> _navigatorKey;

  NotificationService(this._apiService, this._navigatorKey);

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Initializes the notification service, requests permissions, and sets up listeners.
  Future<void> initialize() async {
    // 1. Request permission from the user for notifications
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');

      // 2. Get the device's unique push token (FCM)
      final String? fcmToken = await _fcm.getToken();
      print('Firebase Messaging Token: $fcmToken');

      // 3. Send this token to your backend
      if (fcmToken != null) {
        await _apiService.registerFcmToken(fcmToken);
      }

      // 4. Set up listeners for incoming messages
      _setupNotificationListeners();
    } else {
      print('User declined or has not accepted permission');
    }
  }

  void _setupNotificationListeners() {
    // For handling messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        // Here you could show an in-app banner or a local notification
        // using a package like flutter_local_notifications.
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // For handling when a user taps a notification and the app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleMessage(message);
    });

    // For handling when a user taps a notification and the app is launched from terminated state
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App launched from terminated state by a notification!');
        _handleMessage(message);
      }
    });

    // Set the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Handles deep-linking when a notification is tapped.
  void _handleMessage(RemoteMessage message) {
    // The backend should send the requestId in the 'data' payload of the notification
    final String? requestId = message.data['requestId'];

    if (requestId != null && _navigatorKey.currentContext != null) {
      print('Deep-linking to request ID: $requestId');
      // Use GoRouter to navigate to the specific request detail screen
      GoRouter.of(_navigatorKey.currentContext!).go('/request/$requestId');
    }
  }
}