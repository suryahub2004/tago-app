import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_button.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const TextField(
          decoration: InputDecoration(labelText: 'Shipping address'),
        ),
        const SizedBox(height: AppSpacing.md),
        const TextField(decoration: InputDecoration(labelText: 'Promo code')),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'card', label: Text('Card')),
            ButtonSegment(value: 'apple', label: Text('Apple Pay')),
            ButtonSegment(value: 'upi', label: Text('UPI')),
          ],
          selected: const {'card'},
          onSelectionChanged: (_) {},
        ),
        const SizedBox(height: AppSpacing.xl),
        SvButton(label: 'Place Order', onPressed: () {}),
      ],
    ),
  );
}
