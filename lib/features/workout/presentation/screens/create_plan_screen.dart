import 'package:flutter/material.dart';

class CreatePlanScreen extends StatelessWidget {
  const CreatePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Plan')),
      body: Stepper(
        steps: [
          Step(
            title: const Text('Plan Basics'),
            content: Column(
              children: [
                TextFormField(decoration: const InputDecoration(labelText: 'Plan Name')),
                // Segmented controls and pickers
              ],
            ),
          ),
          Step(
            title: const Text('Weekly Template'),
            content: Column(
              children: [
                const Text('7-day grid'),
              ],
            ),
          ),
          Step(
            title: const Text('Review'),
            content: ElevatedButton(
              onPressed: () {},
              child: const Text('Create Plan'),
            ),
          ),
        ],
      ),
    );
  }
}
