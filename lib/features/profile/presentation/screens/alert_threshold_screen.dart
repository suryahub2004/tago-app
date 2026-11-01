import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_button.dart';

class AlertThresholdScreen extends StatelessWidget {
  const AlertThresholdScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alert Thresholds')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        for (final item in const [
          ('Heart rate high threshold', 130.0, 100.0, 180.0, 'bpm'),
          ('Heart rate low threshold', 40.0, 30.0, 60.0, 'bpm'),
          ('SpO2 low threshold', 93.0, 88.0, 97.0, '%'),
          ('Inactivity alert after', 6.0, 1.0, 24.0, 'hours'),
          ('Battery low alert at', 20.0, 5.0, 30.0, '%'),
        ])
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${item.$1}: ${item.$2.round()} ${item.$5}'),
              Slider(
                value: item.$2,
                min: item.$3,
                max: item.$4,
                onChanged: (_) {},
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        SvButton(label: 'Save', onPressed: () {}),
      ],
    ),
  );
}
