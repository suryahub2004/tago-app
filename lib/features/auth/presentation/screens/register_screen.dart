import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../data/models/register_dto.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Step 1
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  CancelToken? _checkEmailCancelToken;
  Timer? _emailDebounce;
  bool _emailChecking = false;
  String? _emailError;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Step 2
  final _step2FormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _selectedGender;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailDebounce?.cancel();
    _checkEmailCancelToken?.cancel('disposed');
    super.dispose();
  }

  void _onEmailChanged(String value) {
    if (_emailDebounce?.isActive ?? false) _emailDebounce!.cancel();
    if (value.isEmpty || Validators.email(value) != null) {
      setState(() => _emailError = null);
      return;
    }
    
    _checkEmailCancelToken?.cancel('new email typed');
    _checkEmailCancelToken = CancelToken();
    final token = _checkEmailCancelToken!;

    setState(() => _emailChecking = true);
    _emailDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        final available = await ref.read(authRepositoryProvider).checkEmail(value, cancelToken: token);
        if (mounted && !token.isCancelled) {
          setState(() {
            _emailChecking = false;
            _emailError = available ? null : 'This email is already registered — sign in instead?';
          });
        }
      } catch (_) {
        // silent
      } finally {
        if (mounted && !(_checkEmailCancelToken?.isCancelled ?? false)) {
          setState(() => _emailChecking = false);
        }
      }
    });
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) score++;
    return score;
  }

  String _getPasswordStrengthLabel(int score) {
    switch (score) {
      case 0:
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Strong';
      case 4: return 'Very Strong';
      default: return 'Weak';
    }
  }

  Color _getPasswordStrengthColor(int score) {
    switch (score) {
      case 0:
      case 1: return AppColors.danger;
      case 2: return Colors.orange;
      case 3: return Colors.lightGreen;
      case 4: return AppColors.success;
      default: return AppColors.danger;
    }
  }

  void _nextStep() {
    if (_step1FormKey.currentState!.validate() && _emailError == null) {
      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    setState(() => _currentStep = 0);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    if (!_step2FormKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms & Privacy Policy')),
      );
      return;
    }

    final dto = RegisterDto(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _selectedGender,
    );

    await ref.read(authProvider.notifier).register(dto);
    
    if (!mounted) return;
    
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go('/onboarding/product-select');
    } else if (authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.errorMessage!), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        leading: _currentStep == 1 
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep)
          : IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 2,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(auth.isLoading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    final pwdScore = _calculatePasswordStrength(_passwordController.text);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create your account',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 32),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Name is required';
                if (val.trim().length < 2) return 'Name must be at least 2 characters';
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(val)) return 'Only letters and spaces allowed';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                errorText: _emailError,
                suffixIcon: _emailChecking 
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
              ),
              onChanged: _onEmailChanged,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (v) => setState(() {}), // refresh strength
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) {
                if (val == null || val.length < 8) return 'Minimum 8 characters required';
                return null;
              },
            ),
            const SizedBox(height: 8),
            // Password Strength Indicator
            if (_passwordController.text.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: pwdScore / 4,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(_getPasswordStrengthColor(pwdScore)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getPasswordStrengthLabel(pwdScore),
                    style: TextStyle(color: _getPasswordStrengthColor(pwdScore), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (val) {
                if (val != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            SvButton(
              label: 'Continue',
              onPressed: _nextStep,
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tell us about yourself',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 32),
            
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+91 9876543210',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Phone number is required';
                }
                final stripped = val.trim().replaceAll(RegExp(r'[\s\-()]'), '');
                if (stripped.length < 10) {
                  return 'Enter a valid phone number (min 10 digits)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _dateOfBirth = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date of Birth'),
                child: Text(
                  _dateOfBirth == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_dateOfBirth!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Gender', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Male', 'Female', 'Non-binary', 'Prefer not to say'].map((gender) {
                final selected = _selectedGender == gender;
                return ChoiceChip(
                  label: Text(gender),
                  selected: selected,
                  onSelected: (val) => setState(() => _selectedGender = val ? gender : null),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textPrimary),
                  backgroundColor: AppColors.surface,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _termsAccepted,
                    onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('I agree to the ', style: TextStyle(fontSize: 13)),
                      InkWell(
                        onTap: () {}, // open terms webview
                        child: const Text('Terms of Service', style: TextStyle(fontSize: 13, color: AppColors.primary, decoration: TextDecoration.underline)),
                      ),
                      const Text(' and ', style: TextStyle(fontSize: 13)),
                      InkWell(
                        onTap: () {}, // open privacy webview
                        child: const Text('Privacy Policy', style: TextStyle(fontSize: 13, color: AppColors.primary, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            SvButton(
              label: 'Create Account',
              isLoading: isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
