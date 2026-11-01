import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/bluetooth/background_ble_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  }

  await initializeBackgroundService();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await Hive.openBox('settings');

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  final container = ProviderContainer();

  try {
    final localNotificationService = LocalNotificationService();
    await localNotificationService.initialise();
    final pushNotificationService = PushNotificationService(
      apiClient: container.read(apiClientProvider),
      localNotificationService: localNotificationService,
      secureStorage: container.read(secureStorageProvider),
      container: container,
    );
    await pushNotificationService.initialise();
  } catch (e) {
    debugPrint('Push Notification init failed: $e');
  }

  runApp(UncontrolledProviderScope(
    container: container,
    child: const SmartVitalApp(),
  ));
}
