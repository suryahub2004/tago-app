import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Guide'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.menu_book, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'SmartVital Manual',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          _buildGuideSection(
            '1. How to wear your ring',
            'Wear the ring on your index, middle, or ring finger for the most accurate readings. Ensure the sensors on the inside of the ring are touching the bottom of your finger.',
          ),
          _buildGuideSection(
            '2. Charging your ring',
            'Place the ring on the magnetic charging dock. A full charge takes approximately 60-90 minutes and lasts for 4-7 days depending on usage.',
          ),
          _buildGuideSection(
            '3. Syncing Data',
            'Your ring will automatically sync with the SmartVital app when you open the app and Bluetooth is enabled. You can also pull down on the Discover screen to force a manual sync.',
          ),
          _buildGuideSection(
            '4. Understanding your Vitals',
            'SmartVital tracks Heart Rate, Heart Rate Variability (HRV), Blood Oxygen (SpO2), Stress, and Sleep. Check the Health Reports section for detailed insights into your trends.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
