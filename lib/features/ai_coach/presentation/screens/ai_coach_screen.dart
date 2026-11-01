import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_coach_provider.dart';
import 'ai_daily_brief_screen.dart';

class AiCoachScreen extends ConsumerWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiCoachState = ref.watch(aiCoachProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(aiCoachProvider.notifier).refreshInsights(),
          ),
        ],
      ),
      body: aiCoachState.when(
        data: (response) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (response.isCached)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Chip(
                    label: Text('Updated ${DateTime.parse(response.generatedAt).toLocal()} - Tap ↺ to refresh'),
                  ),
                ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AiDailyBriefScreen(response: response))),
                child: Card(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text(response.dailyBrief, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(response.readinessMessage, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Today\'s Actions', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: response.todayActions.map((action) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(label: Text(action)),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Insights', style: TextStyle(fontWeight: FontWeight.bold)),
              ...response.insights.map((insight) {
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Text(insight.iconEmoji, style: const TextStyle(fontSize: 24)),
                        title: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(insight.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (insight.deepLinkRoute != null) {
                            ref.read(aiCoachProvider.notifier).trackClick(insight.id);
                            // Navigator.push(context, route) or GoRouter depending on setup
                            // For now just tracking click since deep link route was requested
                          }
                        },
                      ),
                      Row(
                        children: [
                          const Spacer(),
                          IconButton(
                            icon: Icon(insight.userVoted == true ? Icons.thumb_up : Icons.thumb_up_outlined),
                            color: insight.userVoted == true ? Theme.of(context).primaryColor : null,
                            onPressed: insight.userVoted != null ? null : () {
                              ref.read(aiCoachProvider.notifier).voteInsight(insight.id, true);
                            },
                          ),
                          Text(
                            insight.thumbsUp?.toString() ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(insight.userVoted == false ? Icons.thumb_down : Icons.thumb_down_outlined),
                            color: insight.userVoted == false ? Theme.of(context).primaryColor : null,
                            onPressed: insight.userVoted != null ? null : () {
                              ref.read(aiCoachProvider.notifier).voteInsight(insight.id, false);
                            },
                          ),
                          Text(
                            insight.thumbsDown?.toString() ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
