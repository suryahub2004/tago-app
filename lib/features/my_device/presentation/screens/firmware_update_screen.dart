import 'package:flutter/material.dart';

class FirmwareUpdateScreen extends StatelessWidget {
  const FirmwareUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firmware Update')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Updating to v2.1.5...', style: TextStyle(fontSize: 24)),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
