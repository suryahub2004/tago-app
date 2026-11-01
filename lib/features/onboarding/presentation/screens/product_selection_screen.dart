import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_badge.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../../auth/domain/auth_state.dart';
import '../providers/onboarding_provider.dart';

class ProductSelectionScreen extends ConsumerWidget {
  const ProductSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Text(
              'Choose your device',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'SmartVital adapts metrics, coaching, and alerts to the devices you wear.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: AppSpacing.xxl),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 620;
                final cards = [
                  _DeviceCard(
                    title: 'Smart Ring',
                    imagePath: 'assets/images/smart_ring.png',
                    selected:
                        state.deviceType == DeviceType.ring ||
                        state.deviceType == DeviceType.both,
                    chips: const ['SpO2', 'Temperature', 'HRV', 'Cycle'],
                    onTap: () => ref
                        .read(onboardingProvider.notifier)
                        .setDeviceType(DeviceType.ring),
                  ),
                  _DeviceCard(
                    title: 'Whoop Band',
                    imagePath: 'assets/images/smart_band.png',
                    selected:
                        state.deviceType == DeviceType.band ||
                        state.deviceType == DeviceType.both,
                    chips: const [
                      'Strain',
                      'Recovery',
                      'VO2 Max',
                      'Respiratory',
                    ],
                    onTap: () => ref
                        .read(onboardingProvider.notifier)
                        .setDeviceType(DeviceType.band),
                  ),
                ];
                if (stacked) {
                  return Column(
                    children: [
                      cards[0],
                      const SizedBox(height: AppSpacing.md),
                      cards[1],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: cards[1]),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SwitchListTile(
              value: state.deviceType == DeviceType.both,
              onChanged: (_) => ref
                  .read(onboardingProvider.notifier)
                  .setDeviceType(DeviceType.both),
              title: const Text(
                'I have both',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SvButton(
              label: 'Continue',
              onPressed: state.deviceType == null
                  ? null
                  : () => context.go('/onboarding/questionnaire'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.title,
    required this.imagePath,
    required this.selected,
    required this.chips,
    required this.onTap,
  });

  final String title;
  final String imagePath;
  final bool selected;
  final List<String> chips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selected
                ? [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryDark.withValues(alpha: 0.05)]
                : [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.white24,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle, color: AppColors.primaryLight),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in chips)
                  SvBadge(label: chip, color: AppColors.primaryLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
