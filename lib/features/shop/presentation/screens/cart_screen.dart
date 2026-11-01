import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_button.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cart')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const ListTile(
          leading: Icon(Icons.watch),
          title: Text('Smart Ring Gen 2'),
          subtitle: Text('Size 9 · Matte Black'),
          trailing: Text('\$249'),
        ),
        const Divider(),
        const ListTile(title: Text('Subtotal'), trailing: Text('\$249')),
        const SizedBox(height: AppSpacing.xl),
        SvButton(
          label: 'Checkout',
          onPressed: () => context.go('/home/shop/order?product=smartvital-ring'),
        ),
      ],
    ),
  );
}
