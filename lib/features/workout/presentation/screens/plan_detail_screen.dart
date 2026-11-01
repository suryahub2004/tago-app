import 'package:flutter/material.dart';

class PlanDetailScreen extends StatelessWidget {
  const PlanDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plan Detail'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(children: const [Text('Weekly view of all 7 days')]),
            const Center(child: Text('Monthly calendar widget goes here')),
          ],
        ),
      ),
    );
  }
}
