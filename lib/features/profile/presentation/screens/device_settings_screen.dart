import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_badge.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../../../shared/widgets/sv_card.dart';
import '../../../../core/bluetooth/ble_manager.dart';
import '../../../../core/ble/css_ring/css_ring_service.dart';

class DeviceSettingsScreen extends ConsumerWidget {
  const DeviceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleManager = ref.watch(bleManagerProvider);
    final cssRing = ref.watch(cssRingServiceProvider);
    
    final isCssRing = cssRing.isConnected;
    final battery = isCssRing ? (cssRing.battery?.level ?? 0) : (bleManager.batteryLevel ?? 0);
    final connState = isCssRing ? 'CONNECTED' : bleManager.currentState.name.toUpperCase();
    final deviceName = isCssRing ? 'Smart Ring' : (bleManager.connectedDevice?.platformName ?? 'No Device Connected');

    return Scaffold(
      appBar: AppBar(title: const Text('My Devices')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SvCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      deviceName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    SvBadge(label: connState),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Battery $battery%'),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: battery / 100,
                  color: battery > 20 ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.md),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: SvButton(
                        label: 'Sync now',
                        variant: SvButtonVariant.secondary,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SvButton(label: 'Update firmware', onPressed: () {}),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.border),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Continuous HR Monitoring', style: TextStyle(color: AppColors.textPrimary)),
                  value: ref.watch(cssRingServiceProvider).isMonitoring,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    if (val) {
                      ref.read(cssRingServiceProvider.notifier).startMonitoring();
                    } else {
                      ref.read(cssRingServiceProvider.notifier).stopMonitoring();
                    }
                  },
                ),
                const Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: SvButton(
                        label: 'Fetch Sleep Data',
                        variant: SvButtonVariant.secondary,
                        onPressed: () {
                          ref.read(cssRingServiceProvider.notifier).requestSleep();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Requesting sleep data...')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SvButton(
                        label: 'Fetch BP',
                        variant: SvButtonVariant.secondary,
                        onPressed: () {
                          ref.read(cssRingServiceProvider.notifier).requestBP();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Requesting BP data...')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SvButton(
            label: 'Add Device', 
            onPressed: () => context.push('/onboarding/device-pairing'),
          ),
        ],
      ),
    );
  }
}
