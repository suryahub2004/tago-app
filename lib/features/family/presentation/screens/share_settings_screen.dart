import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ShareSettingsScreen extends StatelessWidget {
  const ShareSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Share Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {}, 
            child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings for Family Member',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Customize what they can see',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          
          _buildSwitchItem(Icons.favorite_rounded, Colors.red, 'Heart Rate', 'They\'ll see your live BPM', true),
          _buildSwitchItem(Icons.bar_chart_rounded, Colors.indigo, 'HRV Score', 'Shows stress and recovery level', true),
          _buildSwitchItem(Icons.air_rounded, Colors.lightBlue, 'Blood Oxygen', 'SpO2 percentage', true),
          _buildSwitchItem(Icons.thermostat_rounded, Colors.orange, 'Skin Temperature', 'Ring only', false),
          _buildSwitchItem(Icons.bedtime_rounded, Colors.deepPurple, 'Sleep Score', 'Overall sleep quality number', true),
          _buildSwitchItem(Icons.nights_stay_rounded, Colors.deepPurpleAccent, 'Sleep Stages', 'Detailed breakdown', false),
          _buildSwitchItem(Icons.directions_walk_rounded, Colors.green, 'Steps', 'Daily movement', true),
          _buildSwitchItem(Icons.local_fire_department_rounded, Colors.deepOrange, 'Calories', 'Energy burn', false),
          _buildSwitchItem(Icons.fitness_center_rounded, Colors.amber, 'Strain Score', 'Workout load', false),
          _buildSwitchItem(Icons.monitor_heart_rounded, Colors.pink, 'Stress Level', 'HRV-based stress indicator', true),
          _buildSwitchItem(Icons.warning_rounded, AppColors.danger, 'Health Alerts', 'Send my alerts to them', true),
          
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Silent Hours',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'No alerts sent outside this window',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          ListTile(
            title: const Text('From: 10:00 PM', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.access_time_rounded, color: AppColors.textSecondary),
            onTap: () {},
          ),
          ListTile(
            title: const Text('To: 07:00 AM', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            trailing: const Icon(Icons.access_time_rounded, color: AppColors.textSecondary),
            onTap: () {},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(IconData icon, Color iconColor, String title, String subtitle, bool initialValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: initialValue,
            onChanged: (val) {},
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
