import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ble/css_ring/css_ring_service.dart';
import '../../../../core/ble/css_ring/css_ring_models.dart';
import '../providers/workout_provider.dart';
import 'create_plan_screen.dart';

class WorkoutHubScreen extends ConsumerWidget {
  const WorkoutHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(workoutProvider);
    final ring = ref.watch(cssRingServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Fitness'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Plan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
            ).then((_) => ref.read(workoutProvider.notifier).loadPlans()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI Coach readiness card (using live ring data when available)
          _buildReadinessCard(ring),
          const SizedBox(height: 20),

          const Text(
            'My Plans',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          plansAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                    const SizedBox(height: 12),
                    Text(e.toString(), textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(workoutProvider.notifier).loadPlans(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (plans) {
              if (plans.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.fitness_center_outlined,
                          size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      const Text(
                        'No workout plans yet.\nTap + to create your first plan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreatePlanScreen()),
                        ).then((_) => ref.read(workoutProvider.notifier).loadPlans()),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Plan'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: plans.map((plan) {
                  final startDate = plan.startDate;
                  final dateStr = DateFormat.MMMd().format(startDate);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: plan.isActive
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: plan.isActive ? AppColors.primary : AppColors.border,
                        width: plan.isActive ? 1.0 : 0.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fitness_center_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        plan.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${plan.goal} • Started $dateStr • ${plan.durationWeeks}w',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: plan.isActive
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const Icon(Icons.chevron_right,
                              color: AppColors.textTertiary),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildReadinessCard(CssRingState ring) {
    final hr = ring.vitals?.heartRate ?? 0;
    final hrv = ring.vitals?.hrv ?? 0;

    String readinessText;
    Color readinessColor;
    IconData readinessIcon;

    if (!ring.isConnected || (hr == 0 && hrv == 0)) {
      readinessText = 'Connect your ring for AI recommendations';
      readinessColor = AppColors.textSecondary;
      readinessIcon = Icons.device_unknown_outlined;
    } else if (hrv >= 60) {
      readinessText = 'High readiness — great day for strength training!';
      readinessColor = AppColors.success;
      readinessIcon = Icons.emoji_events_rounded;
    } else if (hrv >= 35) {
      readinessText = 'Moderate readiness — light to moderate workout recommended.';
      readinessColor = AppColors.warning;
      readinessIcon = Icons.directions_walk_rounded;
    } else {
      readinessText = 'Low readiness — rest or recovery workout today.';
      readinessColor = AppColors.danger;
      readinessIcon = Icons.bedtime_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: readinessColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(readinessIcon, color: readinessColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Coach',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  readinessText,
                  style: TextStyle(
                    color: readinessColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
