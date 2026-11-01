import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/family_comparison_provider.dart';
import '../../data/models/family_models.dart';

class FamilyComparisonScreen extends ConsumerWidget {
  const FamilyComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyComparisonProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Family Comparison'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(familyComparisonProvider),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(
                'Could not load comparison data.\n${e.toString().replaceFirst("Exception: ", "")}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(familyComparisonProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Text(
                'No family members to compare.\nInvite family members first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildChart(
                title: 'Steps Today',
                subtitle: 'Goal: 10,000 steps',
                data: data,
                valueMapper: (m) => m.steps,
                color: AppColors.success,
              ),
              const SizedBox(height: 24),
              _buildChart(
                title: 'Sleep Score',
                subtitle: 'Higher is better (0–100)',
                data: data,
                valueMapper: (m) => m.sleep,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              _buildChart(
                title: 'Heart Rate',
                subtitle: 'Average BPM',
                data: data,
                valueMapper: (m) => m.heartRate,
                color: AppColors.heartRate,
              ),
              const SizedBox(height: 24),
              _buildChart(
                title: 'SpO2',
                subtitle: 'Blood oxygen % (normal ≥ 95)',
                data: data,
                valueMapper: (m) => m.spo2,
                color: AppColors.spo2,
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChart({
    required String title,
    required String subtitle,
    required List<MemberComparison> data,
    required int Function(MemberComparison) valueMapper,
    required Color color,
  }) {
    final hasData = data.any((m) => valueMapper(m) > 0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No data shared yet',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                primaryXAxis: const CategoryAxis(
                  majorGridLines: MajorGridLines(width: 0),
                  axisLine: AxisLine(width: 0),
                  labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                primaryYAxis: const NumericAxis(
                  majorGridLines: MajorGridLines(
                    width: 0.5,
                    color: AppColors.border,
                  ),
                  axisLine: AxisLine(width: 0),
                  labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<MemberComparison, String>>[
                  ColumnSeries<MemberComparison, String>(
                    name: title,
                    color: color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    dataSource: data,
                    xValueMapper: (m, _) => m.name,
                    yValueMapper: (m, _) => valueMapper(m) > 0 ? valueMapper(m) : null,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
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
