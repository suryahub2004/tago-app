import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sv_card.dart';
import '../providers/family_challenge_provider.dart';

class FamilyChallengeCard extends ConsumerWidget {
  const FamilyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyChallengeProvider);

    return state.when(
      data: (challenge) {
        if (challenge == null) return const SizedBox.shrink();

        // Compute total participant progress
        final total = challenge.participants.fold<int>(
          0,
          (sum, p) => sum + ((p['progress'] as num?)?.toInt() ?? 0),
        );
        final progress = challenge.target > 0
            ? (total / (challenge.target * challenge.participants.length))
                .clamp(0.0, 1.0)
            : 0.0;

        return SvCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      challenge.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                challenge.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$total combined ${challenge.type.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Goal: ${challenge.target}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: AppColors.primary,
                  backgroundColor: AppColors.border,
                ),
              ),
              if (challenge.participants.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: challenge.participants.map((p) {
                    final prog = (p['progress'] as num?)?.toInt() ?? 0;
                    final isLeading = p['status'] == 'leading';
                    return Chip(
                      avatar: isLeading
                          ? const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14)
                          : null,
                      label: Text(
                        '$prog',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: isLeading
                          ? Colors.amber.withValues(alpha: 0.12)
                          : AppColors.surface,
                      side: BorderSide(
                        color: isLeading ? Colors.amber : AppColors.border,
                        width: 0.5,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SvCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
