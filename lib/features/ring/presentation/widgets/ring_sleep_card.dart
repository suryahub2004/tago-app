import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ble/css_ring/css_ring_service.dart';

class RingSleepCard extends ConsumerWidget {
  const RingSleepCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleep = ref.watch(cssRingServiceProvider).sleep;
    if (sleep == null) return const SizedBox.shrink();

    final total = sleep.totalMinutes;
    final deepPct = total > 0 ? sleep.deepSleepMinutes / total : 0.0;
    final lightPct = total > 0 ? sleep.lightSleepMinutes / total : 0.0;
    final remPct = total > 0 ? sleep.remMinutes / total : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.bedtime, size: 18),
            const SizedBox(width: 8),
            Text('Last Night\'s Sleep',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              '${(total ~/ 60)}h ${total % 60}m',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ]),
          const SizedBox(height: 16),
          // Sleep stage bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(children: [
              if (deepPct > 0)
                Flexible(flex: (deepPct * 100).round(),
                    child: Container(height: 12, color: Colors.indigo)),
              if (lightPct > 0)
                Flexible(flex: (lightPct * 100).round(),
                    child: Container(height: 12, color: Colors.blue[200])),
              if (remPct > 0)
                Flexible(flex: (remPct * 100).round(),
                    child: Container(height: 12, color: Colors.purple[200])),
            ]),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _SleepStage('Deep', sleep.deepSleepMinutes, Colors.indigo),
            _SleepStage('Light', sleep.lightSleepMinutes, Colors.blue),
            _SleepStage('REM', sleep.remMinutes, Colors.purple),
            _SleepStage('Awake', sleep.awakeMinutes, Colors.orange),
          ]),
        ]),
      ),
    );
  }
}

class _SleepStage extends StatelessWidget {
  final String label;
  final int minutes;
  final Color color;
  const _SleepStage(this.label, this.minutes, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(height: 4),
    Text('${minutes ~/ 60}h ${minutes % 60}m',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
  ]);
}
