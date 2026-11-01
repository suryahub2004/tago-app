import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sv_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/health/apple_health_service.dart';
import '../../../my_device/presentation/screens/find_device_screen.dart';
import 'smartvital_lab_screen.dart';
import 'wellness_summary_screen.dart';
import 'user_guide_screen.dart';
import 'support_screen.dart';
import 'version_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Profile Info
              InkWell(
                onTap: () => context.push('/home/profile/edit'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      SvAvatar(name: user?.fullName ?? 'surya', radius: 30),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.fullName ?? 'surya',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF232532),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.military_tech, color: Color(0xFF8A6FFF), size: 14),
                                SizedBox(width: 4),
                                Text('0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Giant Ring Graphic
              Center(
                child: Icon(
                  Icons.donut_large,
                  size: 140,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
              ),

              const SizedBox(height: 32),

              // Ring Settings & Pairing
              Column(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/home/profile/devices'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Ring Settings', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.push('/home/profile/devices'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('--', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Container(width: 1, height: 16, color: AppColors.border),
                          const SizedBox(width: 12),
                          const Text('Start Pairing', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Meet Gen 3 Card


              const SizedBox(height: 16),

              // Health Alerts
              _buildCardTile('Health Alerts', onTap: () => context.push('/home/profile/thresholds')),

              const SizedBox(height: 16),

              // Sharing Card
              GestureDetector(
                onTap: () => context.go('/home/family'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF26324A), Color(0xFF4A3A26)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Sharing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Icon(Icons.chevron_right, color: Colors.white70),
                      ],
                    ),
                      const SizedBox(height: 16),
                      const Text('Guarding health\nStarting from sharing', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Settings List Group
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildListTile(Icons.settings_outlined, 'App Settings', onTap: () => context.push('/home/profile/edit')),
                    _buildDivider(),
                    _buildListTile(Icons.receipt_long_outlined, 'Order History', onTap: () => context.push('/home/shop/orders')),
                    _buildDivider(),
                    _buildListTile(Icons.bar_chart_rounded, 'Health Reports', onTap: () => context.push('/home/profile/reports')),
                    _buildDivider(),
                    _buildListTile(Icons.radar, 'Find My Ring', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FindDeviceScreen()))),
                    _buildDivider(),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: const Icon(Icons.health_and_safety, color: AppColors.textSecondary),
                      title: const Text('Apple Health Sync', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final authorized = await ref.read(appleHealthServiceProvider).requestPermissions();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(authorized ? 'Connected to Apple Health!' : 'Failed to connect')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(60, 30),
                        ),
                        child: const Text('Connect', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    _buildDivider(),
                    _buildListTile(Icons.science_outlined, 'SmartVital Lab', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartvitalLabScreen()))),
                    _buildDivider(),
                    _buildListTile(Icons.history_outlined, 'Wellness Summary', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WellnessSummaryScreen()))),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Support Group
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildListTile(Icons.menu_book_outlined, 'User Guide', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGuideScreen()))),
                    _buildDivider(),
                    _buildListTile(Icons.support_agent_outlined, 'After-Sales Support', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Version Group
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildListTile(Icons.grid_view_outlined, 'Version Management', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VersionScreen()))),
                    _buildDivider(),
                    _buildListTile(Icons.info_outline, 'About SmartVital', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              GestureDetector(
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 120), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardTile(String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: AppColors.border, height: 1, indent: 60, endIndent: 20);
  }
}
