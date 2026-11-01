import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _logger = Logger();

  static const _healthChannel = AndroidNotificationChannel(
    'smartvital_health',
    'Health Alerts',
    description: 'Critical and Warning Health Alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const _ordersChannel = AndroidNotificationChannel(
    'smartvital_orders',
    'Order Updates',
    description: 'Shipping and Delivery Updates',
    importance: Importance.high,
    playSound: true,
  );

  static const _generalChannel = AndroidNotificationChannel(
    'smartvital_general',
    'General',
    description: 'General notifications and summaries',
    importance: Importance.defaultImportance,
  );

  Future<void> initialise() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _logger.i('Notification tapped with payload: ${details.payload}');
          // Navigation logic will be handled by listening to these payloads elsewhere if needed
        }
      },
    );

    // Create Android channels
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_healthChannel);
      await androidPlugin.createNotificationChannel(_ordersChannel);
      await androidPlugin.createNotificationChannel(_generalChannel);
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'smartvital_general',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      importance: _getImportance(channelId),
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> scheduleDailyReadinessNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      _generalChannel.id,
      _generalChannel.name,
      channelDescription: _generalChannel.description,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReadinessNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'smartvital_health':
        return 'Health Alerts';
      case 'smartvital_orders':
        return 'Order Updates';
      case 'smartvital_general':
      default:
        return 'General';
    }
  }

  Importance _getImportance(String channelId) {
    switch (channelId) {
      case 'smartvital_health':
        return Importance.max;
      case 'smartvital_orders':
        return Importance.high;
      case 'smartvital_general':
      default:
        return Importance.defaultImportance;
    }
  }
}
