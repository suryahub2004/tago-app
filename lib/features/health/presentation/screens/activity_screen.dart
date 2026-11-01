import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/vitals_provider.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(unifiedVitalsProvider('today'));

    String stepsStr = '--';
    String caloriesStr = '854';
    double caloriesProgress = 854 / 2150;
    double stepsProgress = 0.0;

    if (summaryAsync.hasValue && summaryAsync.value != null) {
      final summary = summaryAsync.value!;
      final steps = summary['steps'];
      if (steps != null) {
        stepsStr = steps.toString();
        final stepsVal = int.tryParse(stepsStr) ?? 0;
        stepsProgress = (stepsVal / 12000).clamp(0.0, 1.0);
      }
      final calories = summary['calories'];
      if (calories != null) {
        final calVal = double.tryParse(calories.toString()) ?? 0.0;
        if (calVal > 0) {
          caloriesStr = calVal.toStringAsFixed(0);
          caloriesProgress = (calVal / 2150).clamp(0.0, 1.0);
        }
      }
    }

    final workouts = [
      _WorkoutItem('Morning Run', '45 min', const Color(0xFF3B82F6), Icons.directions_run_rounded),
      _WorkoutItem('Strength Training', '60 min', const Color(0xFFA78BFA), Icons.fitness_center_rounded),
      _WorkoutItem('Evening Yoga', '30 min', const Color(0xFFFBBF24), Icons.self_improvement_rounded),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF6366F1), // indigo primary
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
        label: const Text('Log Workout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            const Text(
              'Activity Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            const Text(
              'View your logged routines and baseline progress.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            
            // Styled Search Box
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13141E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E1F2B), width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const TextField(
                style: TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search activity, workouts...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  prefixIconConstraints: BoxConstraints(minWidth: 32, minHeight: 20),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Calories card
            _buildRedesignedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Active Calories', 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 15,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_right_rounded, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Daily training and activity burn.', 
                    style: TextStyle(
                      color: AppColors.textSecondary, 
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        caloriesStr, 
                        style: const TextStyle(
                          color: Color(0xFFFBBF24), // amber
                          fontSize: 26, // calorie value in amber bold 26sp
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'of 2,150 kcal', 
                        style: TextStyle(
                          color: AppColors.textTertiary, 
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Thin progress bar with amber-to-orange gradient
                  _GradientProgressIndicator(
                    progress: caloriesProgress,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFBBF24), // Amber
                        Colors.orange,
                      ],
                    ),
                    backgroundColor: const Color(0xFF1E1F2B),
                    height: 5,
                  ),
                  const SizedBox(height: 12),
                  // Workouts list
                  Column(
                    children: workouts.map((workout) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: workout.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(workout.icon, color: workout.color, size: 12),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  workout.name,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              workout.duration,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Steps Walked Card
            _buildRedesignedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Walking Steps', 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 15,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_right_rounded, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dynamic steps computed from sensor feeds.', 
                    style: TextStyle(
                      color: AppColors.textSecondary, 
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        stepsStr, 
                        style: const TextStyle(
                          color: Color(0xFF34D399), // step value in green
                          fontSize: 26, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'of 12,000 steps', 
                        style: TextStyle(
                          color: AppColors.textTertiary, 
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // thin green progress indicator bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stepsProgress,
                      minHeight: 5,
                      color: const Color(0xFF34D399), // LinearProgressIndicator in green
                      backgroundColor: const Color(0xFF1E1F2B), // background #1E1F2B
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // FAB padding
          ],
        ),
      ),
    );
  }

  Widget _buildRedesignedCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13141E),
        border: Border.all(color: const Color(0xFF1E1F2B), width: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: padding,
      child: child,
    );
  }
}

class _WorkoutItem {
  final String name;
  final String duration;
  final Color color;
  final IconData icon;
  _WorkoutItem(this.name, this.duration, this.color, this.icon);
}

class _GradientProgressIndicator extends StatelessWidget {
  const _GradientProgressIndicator({
    required this.progress,
    required this.gradient,
    required this.backgroundColor,
    this.height = 6,
  });

  final double progress;
  final Gradient gradient;
  final Color backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: backgroundColor,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * progress.clamp(0.0, 1.0);
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
