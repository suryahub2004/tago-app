import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../features/alerts/presentation/providers/alert_provider.dart';

class SvBottomNav extends ConsumerWidget {
  const SvBottomNav({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAlerts = ref.watch(unreadCriticalAlertsCountProvider);
    final bgColor = AppColors.background.withValues(alpha: 0.85); // Dark glassmorphism
    final borderColor = AppColors.border.withValues(alpha: 0.2);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              top: 12,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(color: borderColor, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Icons.adjust_outlined,
                  Icons.adjust,
                  'Insights',
                  badgeCount: unreadAlerts,
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.view_agenda_outlined,
                  Icons.view_agenda_rounded,
                  'Discover',
                ),
                _buildNavItem(
                  context,
                  2,
                  Icons.favorite_outline_rounded,
                  Icons.favorite_rounded,
                  'Family',
                ),
                _buildNavItem(
                  context,
                  3,
                  Icons.shopping_bag_outlined,
                  Icons.shopping_bag_rounded,
                  'Shop',
                ),
                _buildNavItem(
                  context,
                  4,
                  Icons.sentiment_satisfied_outlined,
                  Icons.sentiment_satisfied,
                  'Me',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String label, {
    int badgeCount = 0,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textSecondary;

    Widget iconWidget = Icon(
      isSelected ? solidIcon : outlineIcon,
      color: isSelected ? activeColor : inactiveColor,
      size: 26,
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(badgeCount.toString()),
        backgroundColor: AppColors.danger,
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: () {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
