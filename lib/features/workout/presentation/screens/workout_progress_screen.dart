import 'package:flutter/material.dart';

class WorkoutProgressScreen extends StatelessWidget {
  const WorkoutProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Progress')),
      body: const Center(child: Text('Progress Charts')),
    );
  }
}
