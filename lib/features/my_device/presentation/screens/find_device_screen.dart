import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FindDeviceScreen extends ConsumerStatefulWidget {
  const FindDeviceScreen({super.key});

  @override
  ConsumerState<FindDeviceScreen> createState() => _FindDeviceScreenState();
}

class _FindDeviceScreenState extends ConsumerState<FindDeviceScreen> {
  Timer? _timer;
  int _rssi = -100;
  StreamSubscription? _scanSub;
  String? _targetDeviceId;

  @override
  void initState() {
    super.initState();
    _startFinding();
  }

  String _mode = 'Initializing...';
  BluetoothDevice? _connectedDevice;

  void _startFinding() async {
    if (Hive.isBoxOpen('settings')) {
      _targetDeviceId = Hive.box('settings').get('last_device_id') as String?;
    }

    if (_targetDeviceId == null) {
      if (mounted) setState(() => _mode = 'No Device Paired');
      return;
    }

    // Continuously monitor and poll
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) async {
      if (!mounted) return;

      // Check OS-level connection
      final devices = FlutterBluePlus.connectedDevices;
      _connectedDevice = devices.where((d) => d.remoteId.str == _targetDeviceId).firstOrNull;

      if (_connectedDevice != null) {
        // Connected Strategy
        if (mounted) setState(() => _mode = 'Live Connection');
        try {
          if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
          final rssi = await _connectedDevice!.readRssi();
          if (mounted) setState(() => _rssi = rssi);
        } catch (_) {}
      } else {
        // Disconnected Strategy
        if (mounted) setState(() => _mode = 'Background Scanning');
        try {
          if (!FlutterBluePlus.isScanningNow) {
            await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
          }
        } catch (_) {}
      }
    });

    // Listen to scan results
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (_connectedDevice != null) return; // Only process if disconnected
      for (final r in results) {
        if (r.device.remoteId.str == _targetDeviceId) {
          if (mounted) setState(() => _rssi = r.rssi);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scanSub?.cancel();
    try {
      FlutterBluePlus.stopScan();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RSSI ranges roughly from -100 (far) to -40 (very close)
    // Map this to a 0.0 to 1.0 progress
    double progress = ((_rssi + 100) / 60).clamp(0.0, 1.0);
    
    // Determine color based on proximity
    Color statusColor;
    String statusText;
    if (_rssi == -100) {
      statusColor = Colors.grey;
      statusText = "Searching...";
    } else if (progress < 0.3) {
      statusColor = Colors.blue;
      statusText = "Cold (Far Away)";
    } else if (progress < 0.7) {
      statusColor = Colors.orange;
      statusText = "Warm (Getting Closer)";
    } else {
      statusColor = Colors.green;
      statusText = "Hot! (Very Close)";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find My Ring'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[800],
                    color: statusColor,
                  ),
                ),
                Icon(
                  Icons.radar,
                  size: 80,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Signal Strength: $_rssi dBm\nMode: $_mode',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Walk around the room. The signal will turn green and the circle will fill up as you get closer to your ring.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
