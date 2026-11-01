import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sv_card.dart';
import '../../../../shared/widgets/sv_error_widget.dart';
import '../../../../shared/widgets/sv_loading.dart';
import '../../../health/presentation/providers/vitals_provider.dart';
import '../../../../core/bluetooth/ble_manager.dart';
import '../../../../core/bluetooth/ble_state_guard.dart';
import '../../../../core/ble/css_ring/css_ring_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnect();
    });
  }

  Future<void> _autoConnect() async {
    if (!Hive.isBoxOpen('settings')) return;
    final settings = Hive.box('settings');
    final lastDeviceId = settings.get('last_device_id') as String?;
    final lastDeviceType = settings.get('last_device_type') as String?;

    if (lastDeviceId != null && lastDeviceType != null) {
      final bleManager = ref.read(bleManagerProvider);
      if (bleManager.currentState.name != 'connected' &&
          bleManager.currentState.name != 'connecting') {
        try {
          final adapterResult = await BleStateGuard.waitUntilReady(
            timeout: const Duration(seconds: 8),
          );
          if (adapterResult != BleAdapterReadyResult.ready) return;

          final device = await bleManager.scanForDevice(
            deviceType: lastDeviceType,
            targetDeviceId: lastDeviceId,
            timeout: const Duration(seconds: 5),
          );
          if (device != null && device.remoteId.str == lastDeviceId) {
            await bleManager.connect(device);
          }
        } catch (e) {
          debugPrint('Auto-connect failed: $e');
        }
      }
    }
  }

  Widget _buildDatePicker() {
    // Show 14 days in the past including today
    final List<DateTime> dates = List.generate(14, (index) {
      return DateTime.now().subtract(Duration(days: 13 - index));
    });

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // So today is on the right, or we can scroll to the end
        itemCount: dates.length,
        itemBuilder: (context, index) {
          // Use natural order since reverse=true puts index 0 on the far right.
          // Wait, if reverse is true, dates[0] (13 days ago) would be on the right. 
          // Let's just build it normally and set initialScrollIndex or reverse the list.
          final date = dates[dates.length - 1 - index];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final isToday = date.difference(DateTime.now()).inDays == 0 && date.day == DateTime.now().day;
              ref.invalidate(vitalsSummaryProvider(isToday ? 'today' : dateStr));
            },
            child: Container(
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDate.difference(DateTime.now()).inDays == 0 && _selectedDate.day == DateTime.now().day;
    final dateParam = isToday ? 'today' : DateFormat('yyyy-MM-dd').format(_selectedDate);
    final summary = ref.watch(unifiedVitalsProvider(dateParam));
    final cssRing = ref.watch(cssRingServiceProvider);
    final isConnected = cssRing.isConnected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(vitalsSummaryProvider(dateParam).future),
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isToday ? 'Today' : DateFormat('MMMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (cssRing.battery?.level != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                '${cssRing.battery!.level}%',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Icon(
                            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                            color: isConnected ? AppColors.primary : AppColors.danger,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildDatePicker(),
                ),
              ),
              summary.when(
                loading: () => const SliverFillRemaining(child: SvLoading()),
                error: (error, _) => SliverFillRemaining(
                  child: SvErrorWidget(
                    error: error,
                    onRetry: () => ref.refresh(vitalsSummaryProvider('today').future),
                  ),
                ),
                data: (data) => SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    _buildWellnessBalance(data, cssRing),
                    const SizedBox(height: 40),
                    _buildActivityCard(data, cssRing),
                    const SizedBox(height: 16),
                    _buildStressCard(data, cssRing),
                    const SizedBox(height: 16),
                    _buildVitalSignsCard(data, cssRing),
                    const SizedBox(height: 120), // Bottom padding for nav bar
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWellnessBalance(Map<String, dynamic> data, dynamic cssRing) {
    final bool hasLiveActivity = cssRing.activity != null;
    final int steps = hasLiveActivity ? cssRing.activity!.steps : (data['steps'] ?? 0);
    final hasData = (data['avgHr'] != null && data['avgHr'] > 0) || cssRing.vitals != null;
    
    // Fallback values for UI
    final int readinessScore = (data['readinessScore'] ?? data['readiness_score'] ?? (hasData ? 50 : 0)).toInt();
    final int sleepScore = (data['sleepScore'] ?? data['sleep_score'] ?? 0).toInt();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Wellness Balance',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            SizedBox(width: 6),
            Icon(Icons.info_outline, color: AppColors.textSecondary, size: 14),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          hasData ? 'Tracking active' : 'Temporarily no data',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildCircularProgressUI(readinessScore, hasData),
        const SizedBox(height: 48),
        _buildMetricsRow(steps, sleepScore, readinessScore),
      ],
    );
  }

  Widget _buildCircularProgressUI(int readinessScore, bool hasData) {
    String readinessText = 'No Data';
    if (hasData) {
      if (readinessScore >= 85) {
        readinessText = 'Optimal';
      } else if (readinessScore >= 70) {
        readinessText = 'Good';
      } else if (readinessScore >= 50) {
        readinessText = 'Moderate';
      } else {
        readinessText = 'Low';
      }
    }

    return SizedBox(
      height: 240,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(240, 240),
            painter: CircularProgressPainter(progress: hasData ? readinessScore / 100.0 : 0.0),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$readinessScore',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                readinessText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(int steps, int sleepScore, int readinessScore) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMetricDotItem(const Color(0xFF3E61E4), '$steps', 'Steps'),
          _buildMetricDotItem(const Color(0xFF8A6FFF), '$sleepScore%', 'Sleep'),
          _buildMetricDotItem(const Color(0xFFFF9500), '$readinessScore', 'Readiness'),
        ],
      ),
    );
  }

  Widget _buildMetricDotItem(Color dotColor, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data, dynamic cssRing) {
    final bool hasLiveActivity = cssRing.activity != null;
    final steps = hasLiveActivity ? cssRing.activity!.steps.toString() : (data['steps']?.toString() ?? '--');
    final calories = hasLiveActivity ? cssRing.activity!.calories.toStringAsFixed(1) : (data['calories']?.toStringAsFixed(1) ?? '--');
    final distance = hasLiveActivity ? cssRing.activity!.distanceKm.toStringAsFixed(2) : (data['distance']?.toStringAsFixed(2) ?? '--');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SvCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Activity', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(steps == '--' ? '--' : '$steps steps', style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActivityMetric(Icons.directions_walk, AppColors.activity, steps, '/6000'),
                _buildActivityMetric(Icons.local_fire_department, Colors.deepOrange, calories, ' kcal'),
                _buildActivityMetric(Icons.directions_run, Colors.redAccent, distance, ' km'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActivityMetric(IconData icon, Color iconColor, String value, String target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(target, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildStressCard(Map<String, dynamic> data, dynamic cssRing) {
    final isConnected = cssRing.isConnected;
    final stress = data['stress'] ?? '--';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SvCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Stress', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(isConnected ? 'Tracking active' : 'Temporarily no data', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Stress Index $stress', style: const TextStyle(color: AppColors.primary, fontSize: 14)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Container(height: 8, decoration: BoxDecoration(color: const Color(0xFF2B3A4A), borderRadius: BorderRadius.circular(4)))),
                const SizedBox(width: 4),
                Expanded(child: Container(height: 8, decoration: BoxDecoration(color: const Color(0xFF33355A), borderRadius: BorderRadius.circular(4)))),
                const SizedBox(width: 4),
                Expanded(child: Container(height: 8, decoration: BoxDecoration(color: const Color(0xFF4A335A), borderRadius: BorderRadius.circular(4)))),
                const SizedBox(width: 4),
                Expanded(child: Container(height: 8, decoration: BoxDecoration(color: const Color(0xFF5A3333), borderRadius: BorderRadius.circular(4)))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignsCard(Map<String, dynamic> data, dynamic cssRing) {
    final isConnected = cssRing.isConnected;
    
    // Check if live data is fresh (within 1 minute, or if actively monitoring/measuring)
    final isFresh = cssRing.vitals != null &&
        (cssRing.isMonitoring || DateTime.now().difference(cssRing.vitals!.timestamp).inMinutes.abs() < 1);
    
    final hr = (isFresh && cssRing.vitals!.heartRate > 0) ? cssRing.vitals!.heartRate.toString() : (data['avgHr'] ?? '--');
    final spo2 = (isFresh && cssRing.vitals!.spo2 > 0) ? cssRing.vitals!.spo2.toString() : (data['spo2'] ?? '--');
    final hrv = (isFresh && cssRing.vitals!.hrv > 0) ? cssRing.vitals!.hrv.toString() : (data['avgHrv'] ?? '--');
    final skinTemp = data['skinTemp'] ?? '--';
    final bp = cssRing.bloodPressure != null ? '${cssRing.bloodPressure!.systolic}/${cssRing.bloodPressure!.diastolic}' : (data['bp'] ?? '--');

    String hrDisplay = '$hr';
    if (cssRing.isMonitoring) {
      if (cssRing.liveHeartRate == null) {
        hrDisplay = '...';
      } else if (cssRing.liveHeartRate == 0) {
        hrDisplay = 'Sensing';
      } else {
        hrDisplay = cssRing.liveHeartRate.toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SvCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vital Signs', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                if (isConnected)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cssRing.isMonitoring ? const Color(0xFFEF4444) : AppColors.primary,
                      side: BorderSide(color: cssRing.isMonitoring ? const Color(0xFFEF4444) : AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: () {
                      ref.read(cssRingServiceProvider.notifier).measureHeartRate();
                      final isNowMonitoring = !cssRing.isMonitoring;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isNowMonitoring
                              ? 'Starting live stream... Please hold still.'
                              : 'Measurement stopped.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(cssRing.isMonitoring ? Icons.stop_rounded : Icons.favorite, size: 14),
                    label: Text(cssRing.isMonitoring ? 'Stop' : 'Measure', style: const TextStyle(fontSize: 12)),
                  )
                else
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(isConnected ? (cssRing.isMonitoring ? 'Live Monitoring Active' : 'Live Monitoring') : 'Temporarily no data', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildVitalBlock(Icons.favorite, hrDisplay, 'bpm', isLive: cssRing.isMonitoring),
                  _buildVitalBlock(Icons.water_drop, '$spo2', '%'),
                  _buildVitalBlock(Icons.monitor_heart, '$hrv', 'ms'),
                  _buildVitalBlock(Icons.thermostat, '$skinTemp', '°C'),
                  _buildVitalBlock(Icons.favorite_border, '$bp', 'mmHg'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVitalBlock(IconData icon, String value, String unit, {bool isLive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFEF4444).withValues(alpha: 0.1) : AppColors.background,
        border: isLive ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)) : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: isLive ? const Color(0xFFEF4444) : AppColors.textSecondary, size: 20),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: isLive ? const Color(0xFFEF4444) : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(unit, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;

  CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track for the thick ring (dark brown)
    final trackPaint = Paint()
      ..color = const Color(0xFF3E2D1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round;
    
    // Active progress for the thick ring (orange)
    final progressPaint = Paint()
      ..color = const Color(0xFFFF9500)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round;

    // Faint middle ring (purple)
    final middleRingPaint = Paint()
      ..color = const Color(0xFF332B4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;

    // Outer ring (dark navy)
    final outerRingPaint = Paint()
      ..color = const Color(0xFF1E2235)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0;

    // Draw the rings from outside to inside
    canvas.drawCircle(center, radius - 8, outerRingPaint);
    canvas.drawCircle(center, radius - 24, middleRingPaint);
    
    // Draw thick progress track
    canvas.drawCircle(center, radius - 48, trackPaint);
    
    // Draw actual progress arc
    final rect = Rect.fromCircle(center: center, radius: radius - 48);
    final startAngle = -pi / 2; // Start at 12 o'clock
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
