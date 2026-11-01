import 'package:flutter/material.dart';
import '../../data/models/ai_models.dart';

class AiInsightDetailScreen extends StatelessWidget {
  final AiInsight insight;

  const AiInsightDetailScreen({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insight Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(insight.iconEmoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(insight.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Chip(label: Text(insight.category)),
            const SizedBox(height: 16),
            Text(insight.body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            if (insight.correlationNote != null) ...[
              const Text('Why?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(insight.correlationNote!),
              const SizedBox(height: 16),
            ],
            if (insight.actionItems != null) ...[
              const Text('Action Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...insight.actionItems!.map((action) => ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(action),
              )),
            ]
          ],
        ),
      ),
    );
  }
}
