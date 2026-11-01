import 'package:flutter/material.dart';

class MeditationHistoryScreen extends StatelessWidget {
  const MeditationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meditation History')),
      body: const Center(child: Text('History List')),
    );
  }
}
