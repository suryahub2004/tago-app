import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';

/// FutureProvider that generates a token-only invite (no email required).
/// The token is embedded in a deep link URL the user can share via
/// any channel (WhatsApp, SMS, etc.).
final _qrInviteTokenProvider = FutureProvider.autoDispose<String>((ref) async {
  final api = ref.watch(apiClientProvider);
  // Token-only invite — email is optional, relationship defaults to 'family'
  final res = await api.postMap(
    '/family/invite',
    data: {'relationship': 'family'},
  );
  final token = res['inviteToken'] as String?
      ?? (res['data'] as Map<String, dynamic>?)?['inviteToken'] as String?;
  if (token == null || token.isEmpty) {
    throw Exception('No invite token received from server');
  }
  return token;
});

/// Builds the full shareable deep link URL from the invite token.
/// Uses the Cloudflare tunnel URL (API_BASE_URL stripped to root) so the
/// link works from any network and opens the app via custom URL scheme.
String _buildInviteLink(String token) {
  // Deep link: opens the app directly via custom scheme
  return 'smartvital://join?token=$token';
}

/// Builds the HTTPS fallback link for users who don't have the app installed.
/// Uses the Cloudflare tunnel / production URL from .env.
String _buildWebFallbackLink(String token) {
  final base = dotenv.maybeGet('API_BASE_URL') ?? 'https://api.smartvital.io/api/v1';
  final root = base.replaceAll(RegExp(r'/api/v1/?$'), '');
  return '$root/join?token=$token';
}

class FamilyQrScreen extends ConsumerWidget {
  const FamilyQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenState = ref.watch(_qrInviteTokenProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invite via QR / Link'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: tokenState.when(
          data: (token) {
            final deepLink = _buildInviteLink(token);
            final webLink = _buildWebFallbackLink(token);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ask a family member to scan\nthis QR code in SmartVital',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // QR code embeds the deep link URI
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: QrImageView(
                      data: deepLink,
                      version: QrVersions.auto,
                      size: 220.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1A1A2E),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Or share the link directly',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // Share button — sends both links so it works with/without app
                  FilledButton.icon(
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share Invite Link'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      SharePlus.instance.share(ShareParams(
                        subject: 'Join my SmartVital family',
                        text:
                            "I'd like to share my health data with you on SmartVital!\n\n"
                            "👉 If you have the app, tap: $deepLink\n\n"
                            "👉 Or open: $webLink\n\n"
                            'Once you join, you can see my live vitals.',
                      ));
                    },
                  ),
                  const SizedBox(height: 12),

                  // Refresh token button
                  TextButton(
                    onPressed: () => ref.invalidate(_qrInviteTokenProvider),
                    child: const Text(
                      'Generate new code',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const CircularProgressIndicator(color: AppColors.primary),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  'Could not generate invite.\n${err.toString().replaceFirst("Exception: ", "")}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(_qrInviteTokenProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
