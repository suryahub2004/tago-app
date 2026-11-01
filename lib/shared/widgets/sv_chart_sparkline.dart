import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SvChartSparkline extends StatelessWidget {
  const SvChartSparkline({required this.values, super.key, this.color});

  final List<double> values;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chartColor = color ?? AppColors.primary;
    
    return LineChart(
      LineChartData(
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF222222),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(0),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            barWidth: 1.8, // thin modern stroke
            color: chartColor,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) {
                // Only show dots on the endpoints (first and last spots)
                return spot.x == barData.spots.first.x || spot.x == barData.spots.last.x;
              },
              getDotPainter: (spot, percent, barData, index) {
                final isStart = spot.x == barData.spots.first.x;
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: isStart ? AppColors.accent : (color ?? AppColors.primary),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  chartColor.withValues(alpha: 0.15),
                  chartColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
