import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sv_button.dart';

class OrderConfirmationScreen extends StatelessWidget {
  /// The real order ID returned by the backend after a successful order creation.
  /// Passed via GoRouter [extra] from [OrderFormScreen].
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.check_circle, size: 100, color: AppColors.success),
              const SizedBox(height: 32),
              const Text(
                'Order Confirmed!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank you for your purchase.\nYour SmartVital device is being prepared for dispatch.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Only show Track Order if we have a real order ID
              if (orderId.isNotEmpty)
                SvButton(
                  label: 'Track Order',
                  onPressed: () => context.go('/home/shop/order/$orderId'),
                ),
              if (orderId.isNotEmpty) const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/home/shop'),
                child: const Text('Back to Store'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
