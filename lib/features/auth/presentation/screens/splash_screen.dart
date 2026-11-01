import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_restore()));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final minimum = Future.delayed(const Duration(milliseconds: 1500));

    // Demo auto-login: enabled ONLY via .env DEMO_AUTO=true
    final demoAuto = dotenv.maybeGet('DEMO_AUTO') == 'true';

    try {
      if (demoAuto) {
        await Future.wait<void>([
          minimum,
          ref.read(authProvider.notifier).demoLogin(UserRole.healthUser),
        ]);
      } else {
        await Future.wait<void>([
          minimum,
          ref.read(authProvider.notifier).restoreSession(),
        ]);
      }
    } catch (e) {
      debugPrint('SplashScreen Error: $e');
    }

    if (!mounted) return;
    final auth = ref.read(authProvider);

    if (!auth.isAuthenticated) {
      // Not logged in — go to login
      context.goNamed(RouteNames.login);
    } else if (!auth.onboardingComplete) {
      // Logged in but onboarding not done — start onboarding
      context.go('/onboarding/product-select');
    } else {
      // Fully set up — go straight to dashboard
      context.go('/home/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Logo & Text Centered
          Center(
            child: Semantics(
              label: 'Tago loading',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Spinning Ring
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: RotationTransition(
                      turns: _rotationController,
                      child: CustomPaint(
                        painter: _AnimatedRingPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Tago',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Draw an arc that's almost a full circle (spinning effect)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.5, // 270 degrees
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
