import 'package:flutter/material.dart';

class LogWorkoutScreen extends StatelessWidget {
  const LogWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Workout')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text("Today's workout", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bench Press - 3 Sets of 10'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Weight'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Reps'))),
                      IconButton(icon: const Icon(Icons.check_circle_outline), onPressed: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Finish Workout'),
          ),
        ],
      ),
    );
  }
}
