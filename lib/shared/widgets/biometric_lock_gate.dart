import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/biometric_service.dart';
import '../../core/constants/app_colors.dart';
import 'sv_button.dart';

class BiometricLockGate extends ConsumerStatefulWidget {
  const BiometricLockGate({super.key, required this.child, this.onUnlocked});
  final Widget child;
  final VoidCallback? onUnlocked;

  @override
  ConsumerState<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends ConsumerState<BiometricLockGate> {
  bool _unlocked = false;
  bool _isChecking = true;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkAndAuthenticate();
  }

  Future<void> _checkAndAuthenticate() async {
    final service = ref.read(biometricServiceProvider);
    final enabled = await service.isEnabled;
    if (!mounted) return;
    setState(() {
      _isEnabled = enabled;
    });

    if (enabled) {
      _authenticate();
    } else {
      setState(() {
        _unlocked = true;
        _isChecking = false;
      });
      widget.onUnlocked?.call();
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isChecking = true;
    });
    final service = ref.read(biometricServiceProvider);
    final success = await service.authenticate();
    if (mounted) {
      setState(() {
        _unlocked = success;
        _isChecking = false;
      });
      if (success) widget.onUnlocked?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) return widget.child;

    if (_unlocked) return widget.child;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: _isChecking
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'App Locked',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Authenticate to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SvButton(
                    label: 'Unlock',
                    onPressed: _authenticate,
                  ),
                ],
              ),
      ),
    );
  }
}
