import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import 'local_notification_service.dart';
import 'notification_handler.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message logic if needed here
  // Note: FlutterLocalNotifications handles showing it if it's sent as a notification payload.
  // This is primarily for data-only messages in the background.
}

class PushNotificationService {
  PushNotificationService({
    required this.apiClient,
    required this.localNotificationService,
    required this.secureStorage,
    required this.container,
  });

  final ApiClient apiClient;
  final LocalNotificationService localNotificationService;
  final SecureStorage secureStorage;
  final ProviderContainer container;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialise() async {
    // 1. Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Set background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Get FCM token and upload to backend
    final token = await _fcm.getToken();
    if (token != null) {
      await _uploadToken(token);
    }

    // 3. Listen for token refresh
    _fcm.onTokenRefresh.listen(_uploadToken);

    // 4. Foreground messages -> show local notification
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // 5. Background tap -> navigate
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // 6. App opened from terminated state via notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      _handleTap(initial);
    }
  }

  Future<void> _uploadToken(String token) async {
    try {
      await apiClient.patchMap('/users/me', data: {'fcmToken': token});
      await secureStorage.write('fcm_token', token);
    } catch (e) {
      // Intentionally ignore failure to upload token if user is not logged in yet.
    }
  }

  void _handleForeground(RemoteMessage message) {
    // We parse type to channel
    final String type = message.data['type'] ?? 'general';
    String channelId = 'smartvital_general';
    
    if (type == 'critical_alert' || type == 'warning_alert') {
      channelId = 'smartvital_health';
    } else if (type.startsWith('order_')) {
      channelId = 'smartvital_orders';
    }

    localNotificationService.show(
      id: message.messageId.hashCode,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
      channelId: channelId,
    );
  }

  void _handleTap(RemoteMessage message) {
    final type = message.data['type']?.toString() ?? '';
    final deepLink = message.data['deepLink']?.toString() ?? '';
    final entityId = message.data['entityId']?.toString();
    
    NotificationHandler.navigate(container, type, deepLink, entityId);
  }
}
