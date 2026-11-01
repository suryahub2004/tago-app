import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';

class ScanQrScreen extends ConsumerStatefulWidget {
  const ScanQrScreen({super.key});

  @override
  ConsumerState<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends ConsumerState<ScanQrScreen> {
  bool _isProcessing = false;

  Future<void> _handleScan(String token) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Route to JoinFamilyScreen which will show the preview before accepting
    context.go('/join?token=$token');
    
    // We don't reset _isProcessing because the screen is unmounting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                final raw = barcodes.first.rawValue!;
                final uri = Uri.tryParse(raw);
                if (uri != null && uri.queryParameters.containsKey('token')) {
                  _handleScan(uri.queryParameters['token']!);
                } else if (!raw.contains('://')) {
                  // Fallback in case the QR just contains the raw token
                  _handleScan(raw);
                }
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: AppColors.background.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
