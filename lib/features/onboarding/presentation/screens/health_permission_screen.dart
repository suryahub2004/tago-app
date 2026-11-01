import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class HealthPermissionScreen extends ConsumerWidget {
  const HealthPermissionScreen({super.key});

  Future<void> _continue(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    ref.read(onboardingProvider.notifier).setHealthSyncEnabled(enabled);
    final user = ref.read(currentUserProvider);
    final profile = user?.healthProfile.copyWith(healthSyncEnabled: enabled);
    if (profile != null) {
      await ref.read(authProvider.notifier).updateHealthProfile(profile);
    }
    if (context.mounted) context.go('/onboarding/device-pairing');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health sync')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'Connect Apple Health or Google Fit',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'SmartVital reads heart rate, HRV, SpO2, steps, active energy, sleep, temperature, respiratory rate, and workouts. Device readings can be written back to your platform health record.',
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final item in [
            'Read daily activity and sleep trends',
            'Write verified device readings',
            'Use platform data to fill gaps when offline',
          ])
            CheckboxListTile(value: true, onChanged: (_) {}, title: Text(item)),
          const SizedBox(height: AppSpacing.xl),
          SvButton(
            label: 'Allow All',
            onPressed: () => _continue(context, ref, true),
          ),
          TextButton(
            onPressed: () => _continue(context, ref, false),
            child: const Text('Skip for Now'),
          ),
        ],
      ),
    );
  }
}
