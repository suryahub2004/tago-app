import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_avatar.dart';
import '../../../../shared/widgets/sv_badge.dart';
import '../../../../shared/widgets/sv_card.dart';
import '../../../../shared/widgets/hr_heatmap_ring.dart';
import '../widgets/family_challenge_card.dart';
import '../providers/family_hub_provider.dart';

class FamilyHubScreen extends ConsumerWidget {
  const FamilyHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyHubProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Family', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Compare',
            onPressed: () => context.go('/home/family/compare'),
            icon: const Icon(Icons.bar_chart, color: AppColors.textPrimary),
          ),
          IconButton(
            tooltip: 'Add Member',
            onPressed: () => context.go('/home/family/invite'),
            icon: const Icon(Icons.person_add_alt, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: state.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(
              child: Text(
                'No family members yet.\nInvite someone to start monitoring.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(familyHubProvider.notifier).fetchMembers(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: members.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const FamilyChallengeCard();
                }
                final member = members[index - 1];
                final color = member.status == 'Normal'
                    ? AppColors.success
                    : AppColors.warning;
                return SvCard(
                  leftBorderColor: color,
                  onTap: () =>
                      context.go('/home/family/member/${member.id}'),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          HrHeatmapRing(
                            heartRate: member.latestHr,
                            child: SvAvatar(name: member.name, imageUrl: member.avatarUrl),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: HrHeatmapRing.ringColor(member.latestHr),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      member.latestHr != null ? '${member.latestHr} bpm' : '-- bpm',
                                      style: TextStyle(
                                        color: member.latestHr != null ? AppColors.textSecondary : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SvBadge(label: member.relation),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          SvBadge(label: member.deviceType),
                          const Spacer(),
                          if (member.permissions.heartRate)
                            Text('HR ${member.latestHr ?? '--'}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          const SizedBox(width: AppSpacing.md),
                          if (member.permissions.spo2)
                            Text('SpO2 ${member.latestSpo2 ?? '--'}%', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LinearProgressIndicator(
                        value: member.latestHr != null ? (member.latestHr! / 150) : 0,
                        color: color,
                        backgroundColor: AppColors.border,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, st) => Center(
          child: Text(
            'Error loading family members',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}
