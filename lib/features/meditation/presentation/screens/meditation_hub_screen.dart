import 'package:flutter/material.dart';
import 'breathing_session_screen.dart';
import 'breath_hold_screen.dart';
import '../../data/models/meditation_models.dart';

class MeditationHubScreen extends StatelessWidget {
  const MeditationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breathe & Meditate')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Today\'s Recommendation', style: TextStyle(fontWeight: FontWeight.bold)),
          Card(
            child: ListTile(
              leading: const Text('😴', style: TextStyle(fontSize: 24)),
              title: const Text('4-7-8 Breathing'),
              subtitle: const Text('calm your nervous system'),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),
          const Text('Techniques', style: TextStyle(fontWeight: FontWeight.bold)),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: builtInPatterns.map((pattern) {
              return GestureDetector(
                onTap: () {
                  if (pattern.isBreathHold == true) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BreathHoldScreen(pattern: pattern)));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => BreathingSessionScreen(pattern: pattern)));
                  }
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(pattern.iconEmoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(pattern.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
