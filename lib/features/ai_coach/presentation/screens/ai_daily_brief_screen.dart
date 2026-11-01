import 'package:flutter/material.dart';
import '../../data/models/ai_models.dart';

class AiDailyBriefScreen extends StatelessWidget {
  final AiCoachResponse response;

  const AiDailyBriefScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Brief')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('Good Morning!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(response.dailyBrief, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(response.readinessMessage, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
