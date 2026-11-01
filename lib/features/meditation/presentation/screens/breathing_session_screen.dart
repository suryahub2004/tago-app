import 'package:flutter/material.dart';
import '../../data/models/meditation_models.dart';
import 'hrv_compare_screen.dart';

class BreathingSessionScreen extends StatelessWidget {
  final BreathingPattern pattern;

  const BreathingSessionScreen({super.key, required this.pattern});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('INHALE', style: TextStyle(color: Colors.white, fontSize: 32)),
            const SizedBox(height: 32),
            Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent),
            ),
            const SizedBox(height: 64),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HrvCompareScreen())),
              child: const Text('End Session (Demo)'),
            )
          ],
        ),
      ),
    );
  }
}
