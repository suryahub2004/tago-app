import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/network/network_exception.dart';
import 'sv_button.dart';
import 'sv_card.dart';

class SvErrorWidget extends StatelessWidget {
  const SvErrorWidget({required this.error, super.key, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  /// Maps any exception type to a clean, user-facing message.
  /// Never shows raw DioException or stack trace text to the user.
  String _friendlyMessage() {
    final e = error;
    if (e is UnauthorizedException) {
      return 'Your session has expired. Please sign in again.';
    }
    if (e is NetworkUnavailableException) {
      return 'No internet connection. Check your network and try again.';
    }
    if (e is NotFoundException) {
      return 'This data is not available yet.';
    }
    if (e is ServerException) {
      return e.message.isNotEmpty
          ? e.message
          : 'The server is temporarily unavailable. Please try again.';
    }
    // For any other error (DioException, etc.) show a generic message
    // instead of exposing internal exception details to the user.
    return 'Something went wrong loading this data. Pull down to retry.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SvCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'We could not load this health data',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _friendlyMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              SvButton(
                label: 'Try again',
                onPressed: onRetry,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
