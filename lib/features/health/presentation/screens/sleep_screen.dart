import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/vitals_provider.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  int _selectedPeriodIndex = 0; // Today

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(unifiedVitalsProvider('today'));
    String sleepScoreStr = '--';
    
    int deepMin = 120;
    int remMin = 90;
    int lightMin = 200;
    int awakeMin = 30;
    int totalMin = 440;
    String sleepTimeStr = '7h 30m';
    String restingHrStr = '48 bpm';

    if (summaryAsync.hasValue && summaryAsync.value != null) {
      final summary = summaryAsync.value!;
      final score = summary['sleepScore'];
      if (score != null) {
        sleepScoreStr = score.toString();
      }

      final deep = summary['deepSleep'];
      final light = summary['lightSleep'];
      final rem = summary['remSleep'];
      final awake = summary['awakeSleep'];
      final total = summary['sleepTime'];
      final hr = summary['avgHr'] ?? summary['heartRate'] ?? summary['heart_rate'];

      if (deep != null) deepMin = (deep as num).toInt();
      if (light != null) lightMin = (light as num).toInt();
      if (rem != null) remMin = (rem as num).toInt();
      if (awake != null) awakeMin = (awake as num).toInt();
      if (total != null && (total as num) > 0) {
        totalMin = total.toInt();
        sleepTimeStr = '${totalMin ~/ 60}h ${totalMin % 60}m';
      }
      if (hr != null && (hr as num) > 0) {
        restingHrStr = '${hr.toInt()} bpm';
      }
    }

    final totalStagesMin = (awakeMin + lightMin + deepMin + remMin).clamp(1, 999999);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // Tab Period Selector
          _buildPeriodSelector(),
          const SizedBox(height: 24),

          // Circle Score Header
          _buildScoreCircleHeader(sleepScoreStr),
          const SizedBox(height: 24),

          // Sleep Stats Card Row
          _buildSleepStatsCard(sleepTimeStr, restingHrStr),
          const SizedBox(height: 24),

          // Sleep Stages Card
          _buildSleepStagesCard(totalStagesMin, awakeMin, lightMin, deepMin, remMin),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildRedesignedCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13141E),
        border: Border.all(color: const Color(0xFF1E1F2B), width: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: padding,
      child: child,
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'Week', 'Month', 'Year'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF13141E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1F2B), width: 0.5),
      ),
      child: Row(
        children: List.generate(periods.length, (index) {
          final isSelected = _selectedPeriodIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriodIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  periods[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF555555),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScoreCircleHeader(String scoreStr) {
    final scoreVal = double.tryParse(scoreStr) ?? 0.0;
    final progress = scoreVal > 0 ? (scoreVal / 100.0).clamp(0.0, 1.0) : 0.75;

    return _buildRedesignedCard(
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    backgroundColor: const Color(0xFF1E1F2B),
                  ),
                ),
                Text(
                  scoreStr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sleep Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scoreVal >= 80 ? 'Optimal Recovery' : (scoreVal > 0 ? 'Good Rest' : 'No Sleep Data'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepStatsCard(String sleepTimeStr, String restingHrStr) {
    return _buildRedesignedCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: _buildSleepMetricItem(sleepTimeStr, 'Sleep Time')),
          Container(width: 0.5, height: 28, color: const Color(0xFF1E1F2B)),
          Expanded(child: _buildSleepMetricItem('04 days', 'Irregular days')),
          Container(width: 0.5, height: 28, color: const Color(0xFF1E1F2B)),
          Expanded(child: _buildSleepMetricItem(restingHrStr, 'Resting HR')),
        ],
      ),
    );
  }

  Widget _buildSleepMetricItem(String val, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          val,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSleepStagesCard(int total, int awakeMin, int lightMin, int deepMin, int remMin) {
    return _buildRedesignedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sleep Stages',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStagePercentage('Awake', '${awakeMin * 100 ~/ total}%', const Color(0xFFEF4444)),
              _buildStagePercentage('Light', '${lightMin * 100 ~/ total}%', const Color(0xFF6366F1)),
              _buildStagePercentage('Deep', '${deepMin * 100 ~/ total}%', const Color(0xFFA78BFA)),
              _buildStagePercentage('REM', '${remMin * 100 ~/ total}%', const Color(0xFF34D399)),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (awakeMin > 0) Expanded(flex: awakeMin, child: Container(color: const Color(0xFFEF4444))),
                  if (lightMin > 0) Expanded(flex: lightMin, child: Container(color: const Color(0xFF6366F1))),
                  if (deepMin > 0) Expanded(flex: deepMin, child: Container(color: const Color(0xFFA78BFA))),
                  if (remMin > 0) Expanded(flex: remMin, child: Container(color: const Color(0xFF34D399))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLegendItem(const Color(0xFFEF4444), 'Awake', '${awakeMin ~/ 60}h ${awakeMin % 60}m'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFF6366F1), 'Light', '${lightMin ~/ 60}h ${lightMin % 60}m'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFFA78BFA), 'Deep', '${deepMin ~/ 60}h ${deepMin % 60}m'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFF34D399), 'REM', '${remMin ~/ 60}h ${remMin % 60}m'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagePercentage(String label, String percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          percentage,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String duration) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        Text(
          duration,
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
