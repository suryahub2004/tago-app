import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_badge.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Morning reading · HR 72 bpm',
      'Sleep logged · 7h 42m',
      'Workout · Zone 3 run',
      'Alert reviewed · elevated HR',
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search history',
            ),
          );
        }
        if (index == 1) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Wrap(
              spacing: 8,
              children: [
                SvBadge(label: 'All'),
                SvBadge(label: 'Workouts'),
                SvBadge(label: 'Sleep'),
                SvBadge(label: 'Alerts'),
              ],
            ),
          );
        }
        final item = items[index - 2];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: Text(item),
            subtitle: const Text('Today'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
