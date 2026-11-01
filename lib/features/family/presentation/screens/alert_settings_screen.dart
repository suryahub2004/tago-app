import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_button.dart';

class AlertSettingsScreen extends StatelessWidget {
  const AlertSettingsScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alerts for $memberId')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Critical vitals alerts'),
          ),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Device battery alerts'),
          ),
          SwitchListTile(
            value: false,
            onChanged: (_) {},
            title: const Text('Daily summary alerts'),
          ),
          const SizedBox(height: AppSpacing.xl),
          SvButton(label: 'Save alert settings', onPressed: () {}),
        ],
      ),
    );
  }
}
