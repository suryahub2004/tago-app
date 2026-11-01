import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class SleepHypnogram extends StatelessWidget {
  const SleepHypnogram({
    super.key,
    required this.deepMinutes,
    required this.remMinutes,
    required this.lightMinutes,
    required this.awakeMinutes,
  });

  final int deepMinutes;
  final int remMinutes;
  final int lightMinutes;
  final int awakeMinutes;

  @override
  Widget build(BuildContext context) {
    final total = deepMinutes + remMinutes + lightMinutes + awakeMinutes;
    if (total <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Sleep Stages',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                if (awakeMinutes > 0)
                  Expanded(
                    flex: awakeMinutes,
                    child: Container(color: AppColors.danger),
                  ),
                if (remMinutes > 0)
                  Expanded(
                    flex: remMinutes,
                    child: Container(color: AppColors.hrv), // Purple for REM
                  ),
                if (lightMinutes > 0)
                  Expanded(
                    flex: lightMinutes,
                    child: Container(color: AppColors.primary), // Yellow/Light blue for Light
                  ),
                if (deepMinutes > 0)
                  Expanded(
                    flex: deepMinutes,
                    child: Container(color: AppColors.sleep), // Deep blue for Deep
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _LegendItem(color: AppColors.danger, label: 'Awake', value: awakeMinutes),
            _LegendItem(color: AppColors.hrv, label: 'REM', value: remMinutes),
            _LegendItem(color: AppColors.primary, label: 'Light', value: lightMinutes),
            _LegendItem(color: AppColors.sleep, label: 'Deep', value: deepMinutes),
          ],
        )
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            Text('${(value / 60).floor()}h ${value % 60}m', style: const TextStyle(fontSize: 10, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
