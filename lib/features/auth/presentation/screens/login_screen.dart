import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Clear previous error messages
    ref.read(authProvider.notifier).clearError();
    
    await ref
        .read(authProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
        
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      // After an explicit sign-in (not first registration), always go to
      // dashboard. The user has already logged in before — they know the app.
      // Onboarding is only forced for brand-new registrations, not re-logins.
      context.go('/home/dashboard');
    } else if (authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _forgotPassword() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    bool isSuccess = false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 32,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSuccess 
                      ? 'Check your email for a reset link.'
                      : 'Enter your registered email below to receive instructions.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!isSuccess) ...[
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'name@example.com',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SvButton(
                    label: 'Send reset link',
                    onPressed: () async {
                      if (resetEmailController.text.trim().isEmpty) return;
                      await ref.read(authProvider.notifier).forgotPassword(resetEmailController.text.trim());
                      if (!context.mounted) return;
                      final authState = ref.read(authProvider);
                      if (authState.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authState.errorMessage!), backgroundColor: AppColors.danger),
                        );
                      } else {
                        setState(() {
                          isSuccess = true;
                        });
                      }
                    },
                  ),
                ] else ...[
                  SvButton(
                    label: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _demoLogin() async {
    final role = await showModalBottomSheet<UserRole>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Demo Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Demo account is pre-seeded in the database.\nEmail: demo@smartvital.io | Password: Demo@1234',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.xl),
              ActionChip(
                label: const Text('Health User'),
                onPressed: () => Navigator.pop(context, UserRole.healthUser),
              ),
              const SizedBox(height: AppSpacing.sm),
              ActionChip(
                label: const Text('Parent Guardian'),
                onPressed: () => Navigator.pop(context, UserRole.parentGuardian),
              ),
            ],
          ),
        ),
      ),
    );
    if (role == null) return;
    
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).demoLogin(role);
        
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      // Demo login always goes to dashboard — demo accounts have
      // onboardingComplete: true set by the seed script.
      context.go('/home/dashboard');
    } else if (authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // Glowing Smart Ring Graphic
                      Center(
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: CustomPaint(
                            painter: _LoginSmartRingPainter(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Brand text
                      const Center(
                        child: Text(
                          'SmartVital',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title from screenshot
                      const Text(
                        'Track What Matters.\nEffortlessly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Start Your Journey to Smarter Wellness',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        style: const TextStyle(color: AppColors.textPrimary),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter a password';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const ValueKey('forgot_password_btn'),
                          onPressed: _forgotPassword,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SvButton(
                        label: 'Sign In',
                        onPressed: _submit,
                        isLoading: auth.isLoading,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      OutlinedButton.icon(
                        key: const ValueKey('google_btn'),
                        onPressed: () {
                          // POST /auth/social/google
                        },
                        icon: const Icon(Icons.g_mobiledata, size: 28, color: AppColors.textPrimary),
                        label: const Text('Continue with Google', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border, width: 1.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      
                      if (Platform.isIOS) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const ValueKey('apple_btn'),
                          onPressed: () {
                            // POST /auth/social/apple
                          },
                          icon: const Icon(Icons.apple, size: 22, color: AppColors.textPrimary),
                          label: const Text('Continue with Apple', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border, width: 1.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border, height: 1, thickness: 0.5),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have an account?',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          TextButton(
                            key: const ValueKey('signup_btn'),
                            onPressed: () => context.pushNamed(RouteNames.register),
                            child: const Text(
                              'Sign up',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      
                      TextButton(
                        key: const ValueKey('demo_login_btn'),
                        onPressed: _demoLogin,
                        child: const Text(
                          'Demo Login',
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom smart ring drawing painter for the login page
class _LoginSmartRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;

    // Draw the ring base
    final ringPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;

    canvas.drawCircle(center, w * 0.28, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

