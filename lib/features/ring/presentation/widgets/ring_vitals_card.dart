import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ble/css_ring/css_ring_service.dart';
import '../../../../core/ble/css_ring/css_ring_models.dart';

class RingVitalsCard extends ConsumerWidget {
  const RingVitalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ring = ref.watch(cssRingServiceProvider);

    // Show nothing if ring not connected and no data available
    if (!ring.isConnected && 
        ring.vitals == null && 
        ring.activity == null && 
        ring.bloodPressure == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(Icons.ring_volume, size: 18),
                const SizedBox(width: 8),
                Text('Smart Ring',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (ring.battery != null)
                  _BatteryChip(battery: ring.battery!),
                if (ring.isMonitoring)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Vitals grid
            if (ring.vitals != null)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _MetricTile(
                    icon: Icons.favorite,
                    color: Colors.red,
                    label: _getHrFreshnessLabel(ring.vitals!.timestamp),
                    value: '${ring.vitals!.heartRate}',
                    unit: 'bpm',
                  ),
                  _MetricTile(
                    icon: Icons.air,
                    color: Colors.blue,
                    label: 'SpO2',
                    value: '${ring.vitals!.spo2}',
                    unit: '%',
                  ),
                  _MetricTile(
                    icon: Icons.timeline,
                    color: Colors.purple,
                    label: 'HRV',
                    value: '${ring.vitals!.hrv}',
                    unit: 'ms',
                  ),
                  _MetricTile(
                    icon: Icons.psychology,
                    color: Colors.orange,
                    label: 'Stress',
                    value: '${ring.vitals!.stress}',
                    unit: '/100',
                  ),
                ],
              ),

            // Activity row
            if (ring.activity != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ActivityItem(Icons.directions_walk,
                      '${ring.activity!.steps}', 'steps'),
                  _ActivityItem(Icons.local_fire_department,
                      ring.activity!.calories.toStringAsFixed(0), 'kcal'),
                  _ActivityItem(Icons.straighten,
                      ring.activity!.distanceKm.toStringAsFixed(1), 'km'),
                ],
              ),
            ],

            // Blood Pressure
            if (ring.bloodPressure != null) ...[
              const Divider(height: 24),
              Row(children: [
                const Icon(Icons.monitor_heart, size: 18, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  '${ring.bloodPressure!.systolic}/${ring.bloodPressure!.diastolic} mmHg',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 4),
                Text('Blood Pressure',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ]),
            ],

            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: ring.isMonitoring
                        ? () => ref.read(cssRingServiceProvider.notifier)
                            .stopMonitoring()
                        : () => ref.read(cssRingServiceProvider.notifier)
                            .startMonitoring(),
                    icon: Icon(ring.isMonitoring
                        ? Icons.stop : Icons.play_arrow, size: 16),
                    label: Text(ring.isMonitoring ? 'Stop' : 'Start',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(cssRingServiceProvider.notifier).requestBP(),
                    icon: const Icon(Icons.monitor_heart, size: 16),
                    label: const Text('BP', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(cssRingServiceProvider.notifier).requestSleep(),
                    icon: const Icon(Icons.bedtime, size: 16),
                    label: const Text('Sleep', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),

            // Error display
            if (ring.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(ring.error!,
                    style: TextStyle(color: Colors.red[400], fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  String _getHrFreshnessLabel(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 5) return 'Live HR • Just now';
    if (diff.inHours < 1) return 'Heart Rate • ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Heart Rate • ${diff.inHours}h ago';
    return 'Heart Rate • ${diff.inDays}d ago';
  }
}

class _BatteryChip extends StatelessWidget {
  final CssRingBattery battery;
  const _BatteryChip({required this.battery});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: battery.level > 20 ? Colors.green[50] : Colors.red[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: battery.level > 20 ? Colors.green : Colors.red,
        width: 0.5,
      ),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(
        battery.isCharging ? Icons.battery_charging_full : Icons.battery_full,
        size: 12,
        color: battery.level > 20 ? Colors.green : Colors.red,
      ),
      const SizedBox(width: 4),
      Text('${battery.level}%',
          style: TextStyle(
            fontSize: 11,
            color: battery.level > 20 ? Colors.green[700] : Colors.red[700],
          )),
    ]),
  );
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value, unit;
  const _MetricTile({
    required this.icon, required this.color,
    required this.label, required this.value, required this.unit,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
            fontSize: 10, color: Colors.grey[600])),
      ]),
      const Spacer(),
      RichText(text: TextSpan(children: [
        TextSpan(text: value, style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        TextSpan(text: ' $unit', style: TextStyle(
            fontSize: 11, color: Colors.grey[500])),
      ])),
    ]),
  );
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _ActivityItem(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 20, color: Colors.grey[600]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: TextStyle(
          fontSize: 11, color: Colors.grey[500])),
    ],
  );
}
