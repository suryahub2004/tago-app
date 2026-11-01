import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/ble/css_ring/css_ring_service.dart';
import '../providers/vitals_provider.dart';

class HeartScreen extends ConsumerStatefulWidget {
  const HeartScreen({super.key});

  @override
  ConsumerState<HeartScreen> createState() => _HeartScreenState();
}

class _HeartScreenState extends ConsumerState<HeartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // 2-second cycle for animation loops
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Double pulse ("lub-dub") scale factor equation for realistic heartbeat animation
  double _getHeartScale(double t) {
    if (t < 0.12) {
      return 1.0 + 0.18 * sin(t / 0.12 * pi);
    } else if (t < 0.20) {
      return 1.0;
    } else if (t < 0.32) {
      return 1.0 + 0.11 * sin((t - 0.20) / 0.12 * pi);
    } else {
      return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(unifiedVitalsProvider('today'));

    String hrStr = '--';
    String hrvStr = '--';
    String restingHrStr = '--';
    String spo2Str = '--';

    if (summaryAsync.hasValue && summaryAsync.value != null) {
      final summary = summaryAsync.value!;
      hrStr = summary['avgHr']?.toString() ?? '--';
      hrvStr = summary['avgHrv']?.toString() ?? '--';
      restingHrStr = summary['minHr']?.toString() ?? '--';
      spo2Str = summary['spo2']?.toString() ?? '--';
    }

    final hrvVal = double.tryParse(hrvStr) ?? 0.0;
    final hrvProgress = hrvVal > 0 ? (hrvVal / 120.0).clamp(0.0, 1.0) : 0.5;

    final restingHrVal = double.tryParse(restingHrStr) ?? 0.0;
    final restingHrProgress = restingHrVal > 0 ? (restingHrVal / 100.0).clamp(0.0, 1.0) : 0.6;

    final ring = ref.watch(cssRingServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final phase = _animationController.value;
          final scale = ring.isMonitoring ? _getHeartScale(phase) : 1.0;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              _buildHeartRateCard(context, ref, hrStr, ring, phase, scale),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildRedesignedSmallMetricCard(
                      title: 'HRV',
                      value: hrvStr,
                      unit: 'ms',
                      accentColor: const Color(0xFF34D399),
                      icon: Icons.bolt,
                      progress: hrvProgress,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRedesignedSmallMetricCard(
                      title: 'Resting HR',
                      value: restingHrStr,
                      unit: 'bpm',
                      accentColor: const Color(0xFFEF4444),
                      icon: Icons.favorite_border_rounded,
                      progress: restingHrProgress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildBloodOxygenCard(spo2Str),
              const SizedBox(height: 120), // padding for bottom nav
            ],
          );
        },
      ),
    );
  }

  Widget _buildRedesignedCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    BoxDecoration? decoration,
  }) {
    return Container(
      decoration: decoration ?? BoxDecoration(
        color: const Color(0xFF13141E),
        border: Border.all(color: const Color(0xFF1E1F2B), width: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: padding,
      child: child,
    );
  }

  Widget _buildHeartRateCard(
    BuildContext context,
    WidgetRef ref,
    String databaseHrStr,
    dynamic ring,
    double phase,
    double scale,
  ) {
    String hrStr = '--';
    String status = '--';
    Color statusColor = AppColors.textTertiary;

    if (ring.isMonitoring) {
      if (ring.liveHeartRate == null) {
        hrStr = 'Starting...';
        status = 'Initializing';
        statusColor = Colors.orangeAccent;
      } else if (ring.liveHeartRate == 0) {
        hrStr = 'Sensing...';
        status = 'Calibrating';
        statusColor = Colors.yellow;
      } else {
        hrStr = ring.liveHeartRate.toString();
        final val = ring.liveHeartRate!;
        if (val < 60) {
          status = 'Low';
          statusColor = Colors.blue;
        } else if (val > 100) {
          status = 'High';
          statusColor = const Color(0xFFEF4444);
        } else {
          status = 'Normal';
          statusColor = const Color(0xFF34D399);
        }
      }
    } else {
      final isFresh = ring.vitals != null &&
          DateTime.now().difference(ring.vitals!.timestamp).inMinutes.abs() < 1;
      final liveHr = isFresh ? ring.vitals!.heartRate : 0;
      int hrVal = liveHr > 0 ? liveHr : (int.tryParse(databaseHrStr) ?? 0);
      hrStr = hrVal > 0 ? hrVal.toString() : '--';
      if (hrVal > 0) {
        if (hrVal < 60) {
          status = 'Low';
          statusColor = Colors.blue;
        } else if (hrVal > 100) {
          status = 'High';
          statusColor = const Color(0xFFEF4444);
        } else {
          status = 'Normal';
          statusColor = const Color(0xFF34D399);
        }
      }
    }

    return _buildRedesignedCard(
      decoration: BoxDecoration(
        color: const Color(0xFF13141E),
        border: Border.all(
          color: ring.isMonitoring ? const Color(0xFFEF4444).withValues(alpha: 0.5) : const Color(0xFF1E1F2B),
          width: ring.isMonitoring ? 1.5 : 0.5,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: ring.isMonitoring
            ? [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Live BPM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (ring.isMonitoring) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (status != '--') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Modernized Measure Button matching HomeScreen style
              if (ring.isConnected)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ring.isMonitoring ? const Color(0xFFEF4444) : AppColors.primary,
                    side: BorderSide(color: ring.isMonitoring ? const Color(0xFFEF4444) : AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () {
                    ref.read(cssRingServiceProvider.notifier).measureHeartRate();
                    final isNowMonitoring = !ring.isMonitoring;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isNowMonitoring
                            ? 'Starting live stream... Please hold still.'
                            : 'Measurement stopped.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(ring.isMonitoring ? Icons.stop_rounded : Icons.favorite, size: 12),
                  label: Text(ring.isMonitoring ? 'Stop' : 'Measure', style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hrStr,
                style: TextStyle(
                  fontSize: hrStr.contains(RegExp('[a-zA-Z]')) ? 24 : 32, // BPM value in red at 32sp bold (or 24 if text)
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 6),
              if (!hrStr.contains(RegExp('[a-zA-Z]')))
                const Text(
                  'bpm',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: HeartSparklinePainter(phase: phase, isLive: ring.isMonitoring),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedesignedSmallMetricCard({
    required String title,
    required String value,
    required String unit,
    required Color accentColor,
    required IconData icon,
    required double progress,
  }) {
    return _buildRedesignedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: accentColor,
              backgroundColor: const Color(0xFF1E1F2B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodOxygenCard(String spo2Str) {
    final spo2Val = double.tryParse(spo2Str) ?? 0.0;
    final progress = spo2Val > 0 ? (spo2Val / 100.0).clamp(0.0, 1.0) : 0.95;

    return _buildRedesignedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bloodtype_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Blood Oxygen',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                spo2Str == '--' ? '--' : '$spo2Str%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: const Color(0xFF6366F1),
              backgroundColor: const Color(0xFF1E1F2B),
            ),
          ),
        ],
      ),
    );
  }
}

class HeartSparklinePainter extends CustomPainter {
  final double phase; // phase shift (0.0 to 1.0) from animation loop
  final bool isLive;
  HeartSparklinePainter({required this.phase, required this.isLive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Translate the canvas smoothly left to animate the scroll effect during active measurements
    final step = 80.0;
    final offset = isLive ? phase * step : 0.0;
    canvas.translate(-offset, 0);

    final path = Path();
    path.moveTo(0, midY);

    double x = 0;
    // Draw extra segments to guarantee coverage when shifted
    while (x < w + step) {
      path.lineTo(x + 15, midY);
      path.quadraticBezierTo(x + 20, midY - 6, x + 25, midY);
      path.lineTo(x + 30, midY);
      path.lineTo(x + 33, midY + 8);
      path.lineTo(x + 38, midY - 24);
      path.lineTo(x + 43, midY + 16);
      path.lineTo(x + 46, midY);
      path.quadraticBezierTo(x + 53, midY - 10, x + 60, midY);
      path.lineTo(x + step, midY);
      x += step;
    }

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HeartSparklinePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.isLive != isLive;
  }
}
