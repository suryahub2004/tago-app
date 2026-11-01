import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bluetooth/ble_manager.dart';
import '../../../../shared/widgets/signal_bars.dart';
import '../../../ring/presentation/widgets/ring_vitals_card.dart';
import '../../../ring/presentation/widgets/ring_sleep_card.dart';
import 'device_metrics_toggle_screen.dart';
import 'firmware_update_screen.dart';
import '../../../../core/ble/css_ring/css_ring_service.dart';

class MyDeviceScreen extends ConsumerWidget {
  const MyDeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleManager = ref.watch(bleManagerProvider);
    final ringState = ref.watch(cssRingServiceProvider);
    
    // Fallback to the ring-specific battery if the standard one isn't populated
    final battery = bleManager.batteryLevel ?? ringState.battery?.level;
    final connState = bleManager.currentState.name.toUpperCase();
    
    final device = bleManager.connectedDevice;
    String deviceName = 'No Device';
    if (device != null) {
      if (device.platformName.isNotEmpty) {
        deviceName = device.platformName;
      } else if (device.advName.isNotEmpty) {
        deviceName = device.advName;
      } else {
        deviceName = device.remoteId.str;
      }
    }
    
    final rssi = bleManager.lastRssi ?? -100;

    return Scaffold(
      appBar: AppBar(title: const Text('My Device')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Text(
              deviceName, 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Chip(
              label: Text(connState),
              backgroundColor: bleManager.currentState.name == 'connected' ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 16),
          if (bleManager.currentState.name == 'connected')
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SignalBars(rssi: rssi),
                  const SizedBox(width: 8),
                  Text('$rssi dBm'),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const RingVitalsCard(),
          RingSleepCard(),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(
              (battery ?? 0) > 20 ? Icons.battery_full : Icons.battery_alert, 
              size: 40, 
              color: (battery ?? 0) > 20 ? Colors.green : Colors.red,
            ),
            title: Text(battery != null ? '$battery%' : 'Reading...'),
            subtitle: const Text('Battery Level'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Sync Now'),
            subtitle: const Text('Last synced: Just now'),
            trailing: ElevatedButton(onPressed: () {}, child: const Text('Sync')),
          ),
          const Divider(),
          ListTile(
            title: const Text('Firmware Update'),
            subtitle: const Text('Check for the latest updates'),
            trailing: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FirmwareUpdateScreen())),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('Check'),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Active Metrics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceMetricsToggleScreen())),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(bleManagerProvider).forgetDevice();
              if (context.mounted) {
                context.go('/onboarding/device-pairing');
              }
            },
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: const Text('Forget Device', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
