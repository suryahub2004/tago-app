import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'activity_screen.dart';
import 'body_screen.dart';
import 'heart_screen.dart';
import 'history_screen.dart';
import 'sleep_screen.dart';
import 'trends_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Discover', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                indicator: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelColor: const Color(0xFF555555),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Text('Heart'))),
                  Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Text('Sleep'))),
                  Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Text('Activity'))),
                  Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Text('Body'))),
                  Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Text('Trends'))),
                  Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Text('History'))),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            HeartScreen(),
            SleepScreen(),
            ActivityScreen(),
            BodyScreen(),
            TrendsScreen(),
            HistoryScreen(),
          ],
        ),
      ),
    );
  }
}
