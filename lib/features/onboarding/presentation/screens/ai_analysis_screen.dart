import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class AiAnalysisScreen extends ConsumerStatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  ConsumerState<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends ConsumerState<AiAnalysisScreen> {
  var _visibleItems = 0;
  var _summaryVisible = false;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _visibleItems = i + 1);
    }
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    final state = ref.read(onboardingProvider);
    await ref
        .read(authProvider.notifier)
        .updateHealthProfile(
          HealthProfile(
            deviceType: state.deviceType,
            onboardingComplete: false,
            fitnessLevel: state.fitnessLevel,
            primaryGoal: state.primaryGoal,
            age: state.age,
          ),
        );
    if (!mounted) return;
    setState(() => _summaryVisible = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) context.go('/onboarding/health-permission');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProvider)?.healthProfile;
    final checks = [
      'Building your health baseline',
      'Calibrating your device thresholds',
      'Personalising your dashboard',
      'Setting alert sensitivity',
      'Syncing your profile',
    ];
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.auto_awesome,
                color: AppColors.primaryLight,
                size: 72,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Analysing your baseline',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xxl),
              for (var i = 0; i < checks.length; i++)
                AnimatedOpacity(
                  opacity: i < _visibleItems ? 1 : 0.2,
                  duration: const Duration(milliseconds: 240),
                  child: ListTile(
                    leading: Icon(
                      i < _visibleItems
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: AppColors.success,
                    ),
                    title: Text(
                      checks[i],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              const Spacer(),
              AnimatedOpacity(
                opacity: _summaryVisible ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  'Your SmartVital profile: ${profile?.fitnessLevel ?? 'Active'} ${profile?.age ?? 32}-year-old aiming for ${profile?.primaryGoal ?? 'General Wellness'}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SvButton(
                label: "Let's go",
                onPressed: _summaryVisible
                    ? () => context.go('/onboarding/health-permission')
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
