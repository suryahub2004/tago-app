import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationHandler {
  static void navigate(ProviderContainer container, String type, String deepLink, String? entityId) {
    final GoRouter router = container.read(appRouterProvider);
    switch (type) {
      case 'order_confirmed':
      case 'order_shipped':
      case 'order_delivered':
        router.push('/home/shop/order/$entityId');
        break;
      case 'critical_alert':
        // If parent: go to family member screen
        // If user: go to relevant health screen
        if (deepLink.isNotEmpty) {
          router.push(deepLink);
        } else {
          router.push('/home/dashboard');
        }
        break;
      case 'daily_summary':
        router.push('/home/dashboard');
        break;
      case 'sleep_reminder':
        router.push('/home/health/sleep');
        break;
      case 'device_battery':
        router.push('/home/profile/devices');
        break;
      case 'family_invite':
        router.push('/home/family/invite');
        break;
      case 'family_checkin':
        router.push('/home/family');
        break;
      default:
        if (deepLink.isNotEmpty) {
          router.push(deepLink);
        } else {
          router.push('/home/dashboard');
        }
    }
  }
}
