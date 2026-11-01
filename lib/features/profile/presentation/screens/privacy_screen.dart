import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/biometric_service.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final service = ref.read(biometricServiceProvider);
    final available = await service.isAvailable;
    final enabled = await service.isEnabled;
    if (mounted) {
      setState(() {
        _biometricsAvailable = available;
        _biometricsEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometrics(bool enable) async {
    final service = ref.read(biometricServiceProvider);
    if (enable) {
      final success = await service.authenticate();
      if (!success) return;
    }
    await service.setEnabled(enable);
    setState(() {
      _biometricsEnabled = enable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const Text(
            'Your SmartVital profile, device readings, and family sharing settings are encrypted in transit and controlled from this screen.',
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_biometricsAvailable)
            SwitchListTile(
              title: const Text('App Lock (Biometrics)'),
              subtitle: const Text('Require authentication when opening the app'),
              value: _biometricsEnabled,
              onChanged: _toggleBiometrics,
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
