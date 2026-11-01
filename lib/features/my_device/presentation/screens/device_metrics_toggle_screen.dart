import 'package:flutter/material.dart';

class DeviceMetricsToggleScreen extends StatelessWidget {
  const DeviceMetricsToggleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Metrics')),
      body: ListView(
        children: [
          SwitchListTile(title: const Text('❤️ Heart Rate'), value: true, onChanged: null),
          SwitchListTile(title: const Text('📊 HRV'), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text('🫁 SpO2 (ring only)'), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text('🌡️ Skin Temperature (ring only)'), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text('🚶 Steps'), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text('🔥 Calories'), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text('😴 Sleep Tracking'), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text('💪 Strain (band only)'), value: false, onChanged: (v) {}),
          SwitchListTile(title: const Text('🫁 Respiratory Rate (band only)'), value: false, onChanged: (v) {}),
        ],
      ),
    );
  }
}
