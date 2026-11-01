import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import 'sv_card.dart';

class SvMetricCard extends StatelessWidget {
  const SvMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    super.key,
    this.accentColor,
    this.delta,
    this.deltaPositive,
    this.onTap,
    this.chart,
    this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final Color? accentColor;
  final String? delta;
  final bool? deltaPositive;
  final VoidCallback? onTap;
  final Widget? chart;
  final IconData? icon;

  IconData _getIconData() {
    if (icon != null) return icon!;
    final lower = label.toLowerCase();
    if (lower.contains('heart') || lower.contains('bpm')) return Icons.favorite_border_rounded;
    if (lower.contains('sleep')) return Icons.nights_stay_outlined;
    if (lower.contains('activity') || lower.contains('cal') || lower.contains('step')) return Icons.local_fire_department_outlined;
    if (lower.contains('oxygen') || lower.contains('spo2')) return Icons.air_rounded;
    if (lower.contains('temp')) return Icons.thermostat_outlined;
    return Icons.health_and_safety_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;
    final displayIcon = _getIconData();

    return SvCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  displayIcon,
                  color: accent,
                  size: 18,
                  semanticLabel: label,
                ),
              ),
              const Spacer(),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (deltaPositive == false ? AppColors.danger : AppColors.success).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    delta!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: deltaPositive == false
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value, 
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                unit, 
                style: const TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          if (chart != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(height: 40, child: RepaintBoundary(child: chart!)),
          ],
        ],
      ),
    );
  }
}
