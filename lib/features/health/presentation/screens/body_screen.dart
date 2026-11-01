import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_metric_card.dart';
import '../providers/vitals_provider.dart';

class BodyScreen extends ConsumerWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(unifiedVitalsProvider('today'));

    String spo2Str = '--';
    String stressStr = '--';
    String skinTempStr = '+0.2';

    if (summaryAsync.hasValue && summaryAsync.value != null) {
      final summary = summaryAsync.value!;
      final spo2 = summary['spo2'] ?? summary['avgSpo2'];
      spo2Str = spo2 != null ? spo2.toString() : '--';
      
      final stress = summary['stress'] ?? summary['stressScore'];
      stressStr = stress != null ? stress.toString() : '--';
      
      final skinTemp = summary['skinTemp'] ?? summary['skin_temp'];
      if (skinTemp != null) {
        final val = double.tryParse(skinTemp.toString()) ?? 0.0;
        skinTempStr = val >= 0 ? '+$val' : '$val';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SvMetricCard(
            label: 'SpO2',
            value: spo2Str,
            unit: '%',
            accentColor: AppColors.spo2,
            delta: spo2Str == '--' ? 'No overnight readings' : 'Overnight avg $spo2Str%',
          ),
          const SizedBox(height: AppSpacing.md),
          SvMetricCard(
            label: 'Skin Temperature',
            value: skinTempStr,
            unit: 'C',
            accentColor: AppColors.temperature,
            delta: skinTempStr == '+0.2' ? 'vs baseline (fallback)' : 'vs baseline',
          ),
          const SizedBox(height: AppSpacing.md),
          SvMetricCard(
            label: 'Stress Level',
            value: stressStr,
            unit: 'low',
            accentColor: AppColors.stress,
            delta: stressStr == '--' ? 'No active stress logs' : 'Better than 71% of days',
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
