import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_notification_service.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});
