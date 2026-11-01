import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('About SmartVital'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: Icon(Icons.favorite, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'SmartVital',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Guarding Health, Starting from Sharing',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 48),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildLinkTile(
                  'Privacy Policy',
                  Icons.privacy_tip_outlined,
                  () => _launchUrl('https://example.com/privacy'),
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60, endIndent: 20),
                _buildLinkTile(
                  'Terms of Service',
                  Icons.description_outlined,
                  () => _launchUrl('https://example.com/terms'),
                ),
                const Divider(color: AppColors.border, height: 1, indent: 60, endIndent: 20),
                _buildLinkTile(
                  'Website',
                  Icons.language,
                  () => _launchUrl('https://example.com'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            '© 2026 SmartVital Inc.\nAll rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      trailing: const Icon(Icons.open_in_new, color: AppColors.textSecondary, size: 20),
    );
  }
}
