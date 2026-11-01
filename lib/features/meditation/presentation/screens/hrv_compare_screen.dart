import 'package:flutter/material.dart';

class HrvCompareScreen extends StatelessWidget {
  const HrvCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Before vs After')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Before', style: TextStyle(fontSize: 24)),
                    SizedBox(height: 8),
                    Text('45 ms', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Text('After', style: TextStyle(fontSize: 24)),
                    SizedBox(height: 8),
                    Text('53 ms', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('▲ +8 ms — breathing improved your HRV', style: TextStyle(color: Colors.green)),
            const SizedBox(height: 64),
            ElevatedButton(onPressed: () {}, child: const Text('Save Session')),
            TextButton(onPressed: () {}, child: const Text('Share')),
          ],
        ),
      ),
    );
  }
}
