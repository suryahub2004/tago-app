import 'package:flutter/material.dart';
import '../../data/models/meditation_models.dart';

class BreathHoldScreen extends StatelessWidget {
  final BreathingPattern pattern;

  const BreathHoldScreen({super.key, required this.pattern});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('HOLD', style: TextStyle(color: Colors.redAccent, fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            const Text('00:45', style: TextStyle(color: Colors.white, fontSize: 64)),
            const SizedBox(height: 64),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tap to breathe'),
            )
          ],
        ),
      ),
    );
  }
}
