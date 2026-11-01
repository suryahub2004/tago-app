import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/family_hub_provider.dart';

/// Landing screen for family invite deep links.
///
/// Reached via:
///   `smartvital://join?token=<token>`
///   `https://<cloudflare-tunnel>/join?token=<token>`
///
/// Flow:
///   - Not logged in → show preview → redirect to login → come back here
///   - Logged in → show "Join [Name]'s family?" confirmation → accept → go to /home/family
class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  bool _isLoadingPreview = true;
  bool _isLoading = false;
  bool _done = false;
  String? _error;
  String? _inviterName;

  @override
  void initState() {
    super.initState();
    // If the token is empty, show error immediately
    if (widget.token.isEmpty) {
      _error = 'Invalid invite link — no token found.';
      _isLoadingPreview = false;
    } else {
      _loadPreview();
    }
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await ref.read(familyHubProvider.notifier).getInvitePreview(widget.token);
      if (!mounted) return;
      setState(() {
        _inviterName = preview['inviterName'] as String?;
        _isLoadingPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load invite details.';
        _isLoadingPreview = false;
      });
    }
  }

  Future<void> _accept() async {
    final auth = ref.read(authProvider);

    // Not logged in — send to login and come back with the token in extra
    if (!auth.isAuthenticated) {
      context.go('/login', extra: {'pendingInviteToken': widget.token});
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref
          .read(familyHubProvider.notifier)
          .acceptInviteByToken(widget.token);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _done = true;
      });

      // Small delay so the success state is visible before navigating
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/home/family');
    } on NotFoundException {
      setState(() {
        _isLoading = false;
        _error = 'This invite link has expired or is no longer valid.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoggedIn = auth.isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icon
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _done
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    _done ? Icons.check_circle_rounded : Icons.people_rounded,
                    size: 52,
                    color: _done ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                _done
                    ? "You've joined the family!"
                    : _error != null
                        ? 'Invite Error'
                        : "You've been invited!",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              if (_isLoadingPreview)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Text(
                  _done
                      ? 'You can now see each other\'s health data in the Family tab.'
                      : _error != null
                          ? _error!
                          : isLoggedIn
                              ? '${_inviterName ?? 'A family member'} wants to share health data with you via SmartVital.\n\nJoin to monitor each other in real-time.'
                              : '${_inviterName ?? 'A family member'} wants to share health data with you.\n\nSign in or create an account to accept.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: _error != null ? AppColors.danger : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

              const Spacer(),

              // Action button
              if (!_done && _error == null && !_isLoadingPreview) ...[
                SvButton(
                  label: isLoggedIn ? 'Join Family Group' : 'Sign In to Accept',
                  isLoading: _isLoading,
                  onPressed: _accept,
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => context.go('/home/dashboard'),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
              ],

              // Error retry
              if (_error != null) ...[
                SvButton(
                  label: 'Go to Home',
                  onPressed: () => context.go('/home/dashboard'),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
