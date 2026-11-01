import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/notifications/local_notification_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  // Defaults based on specification
  bool warningAlerts = true;
  bool dailySummary = true;
  bool dailyReadiness = true;
  bool sleepReminder = true;
  bool familyCheckIn = true;
  bool familyAlerts = true;
  bool orderUpdates = true;
  bool shopAndDeals = false;
  bool deviceBattery = true;
  bool firmwareUpdates = true;

  Future<void> _updateSettings() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patchMap('/users/me/notification-settings', data: {
        'warningAlerts': warningAlerts,
        'dailySummary': dailySummary,
        'dailyReadiness': dailyReadiness,
        'sleepReminder': sleepReminder,
        'familyCheckIn': familyCheckIn,
        'familyAlerts': familyAlerts,
        'orderUpdates': orderUpdates,
        'shopAndDeals': shopAndDeals,
        'deviceBattery': deviceBattery,
        'firmwareUpdates': firmwareUpdates,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          const SwitchListTile(
            value: true,
            onChanged: null,
            title: Text('Health Alerts (Critical)'),
            subtitle: Text('SpO2, HR emergencies'),
            secondary: Icon(Icons.lock),
          ),
          SwitchListTile(
            value: warningAlerts,
            onChanged: (val) {
              setState(() => warningAlerts = val);
              _updateSettings();
            },
            title: const Text('Health Alerts (Warning)'),
            subtitle: const Text('Elevated readings'),
          ),
          SwitchListTile(
            value: dailySummary,
            onChanged: (val) {
              setState(() => dailySummary = val);
              _updateSettings();
            },
            title: const Text('Daily Summary'),
            subtitle: const Text('8 PM daily snapshot'),
          ),
          SwitchListTile(
            value: dailyReadiness,
            onChanged: (val) {
              setState(() => dailyReadiness = val);
              if (!val) {
                ref.read(localNotificationServiceProvider).cancelDailyReadinessNotification(100);
              } else {
                // To reschedule immediately, we would need the score again, but 
                // fetching it again will trigger the scheduling anyway.
              }
              _updateSettings();
            },
            title: const Text('Morning Readiness'),
            subtitle: const Text('8 AM readiness score notification'),
          ),
          SwitchListTile(
            value: sleepReminder,
            onChanged: (val) {
              setState(() => sleepReminder = val);
              _updateSettings();
            },
            title: const Text('Sleep Reminder'),
            subtitle: const Text('30 min before bedtime'),
          ),
          SwitchListTile(
            value: familyCheckIn,
            onChanged: (val) {
              setState(() => familyCheckIn = val);
              _updateSettings();
            },
            title: const Text('Family Check-in'),
            subtitle: const Text('When parent sends check-in'),
          ),
          SwitchListTile(
            value: familyAlerts,
            onChanged: (val) {
              setState(() => familyAlerts = val);
              _updateSettings();
            },
            title: const Text('Family Alerts'),
            subtitle: const Text('When member has an alert'),
          ),
          SwitchListTile(
            value: orderUpdates,
            onChanged: (val) {
              setState(() => orderUpdates = val);
              _updateSettings();
            },
            title: const Text('Order Updates'),
            subtitle: const Text('Shipping, delivery'),
          ),
          SwitchListTile(
            value: shopAndDeals,
            onChanged: (val) {
              setState(() => shopAndDeals = val);
              _updateSettings();
            },
            title: const Text('Shop & Deals'),
            subtitle: const Text('Flash sales, new products'),
          ),
          SwitchListTile(
            value: deviceBattery,
            onChanged: (val) {
              setState(() => deviceBattery = val);
              _updateSettings();
            },
            title: const Text('Device Battery'),
            subtitle: const Text('Below 20%'),
          ),
          SwitchListTile(
            value: firmwareUpdates,
            onChanged: (val) {
              setState(() => firmwareUpdates = val);
              _updateSettings();
            },
            title: const Text('Firmware Updates'),
            subtitle: const Text('New firmware available'),
          ),
        ],
      ),
    );
  }
}
