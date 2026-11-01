import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_loading.dart';
import '../../data/shop_repository.dart';

/// Fetches a single order by ID from [GET /shop/orders/:id].
final _orderDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  final repo = ref.watch(shopRepositoryProvider);
  return repo.getOrderById(orderId);
});

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(_orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const Center(child: SvLoading()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(
                  'Failed to load order: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(_orderDetailProvider(orderId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (order) => _OrderDetailBody(order: order),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderDetailBody({required this.order});

  @override
  Widget build(BuildContext context) {
    final id = order['id'] as String? ?? '';
    final shortId = id.length >= 8
        ? id.substring(id.length - 8).toUpperCase()
        : id.toUpperCase();
    final status = order['status'] as String? ?? 'PENDING';
    final createdAt = order['createdAt'] != null
        ? DateTime.tryParse(order['createdAt'].toString())
        : null;
    final totalAmount =
        (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = order['paymentMethod'] as String? ?? '';
    final trackingNumber = order['trackingNumber'] as String?;

    // Shipping address stored as JSON in the backend
    final addr = order['shippingAddress'] as Map<String, dynamic>? ?? {};
    final addrFullName = addr['fullName'] as String? ?? '';
    final addrPhone = addr['phone'] as String? ?? '';
    final addrLine1 = addr['line1'] as String? ?? '';
    final addrCity = addr['city'] as String? ?? '';
    final addrPinCode = addr['pinCode'] as String? ?? '';
    final addrState = addr['state'] as String? ?? '';

    // Items array
    final items = (order['items'] as List<dynamic>?) ?? [];

    Color statusColor = AppColors.textSecondary;
    if (status == 'CONFIRMED' || status == 'DELIVERED') {
      statusColor = AppColors.success;
    } else if (status == 'SHIPPED') {
      statusColor = AppColors.primary;
    } else if (status == 'CANCELLED') {
      statusColor = AppColors.danger;
    } else if (status == 'PENDING' || status == 'PACKED') {
      statusColor = AppColors.warning;
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Order header ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #$shortId',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: $status',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Placed on: ${DateFormat.yMMMd().format(createdAt)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              if (trackingNumber != null && trackingNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Tracking: ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      trackingNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // ── Items ─────────────────────────────────────────────────────────
        const SizedBox(height: 24),
        const Text(
          'Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text(
            'No items found.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ...items.map((item) {
            final itemMap = item as Map<String, dynamic>;
            final product =
                itemMap['product'] as Map<String, dynamic>? ?? {};
            final productName =
                product['name'] as String? ?? 'Product';
            final qty = (itemMap['quantity'] as num?)?.toInt() ?? 1;
            final unitPrice =
                (itemMap['unitPrice'] as num?)?.toDouble() ?? 0.0;
            final ringSize = order['ringSize'] as String?;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.radio_button_unchecked,
                  color: AppColors.primary,
                ),
              ),
              title: Text(productName),
              subtitle: Text(
                '${ringSize != null ? "Size: $ringSize\n" : ""}Qty: $qty',
              ),
              trailing: Text(
                '₹${(unitPrice * qty).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          }),

        const Divider(height: 48),

        // ── Shipping Address ──────────────────────────────────────────────
        const Text(
          'Shipping Address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          [
            addrFullName,
            if (addrPhone.isNotEmpty) addrPhone,
            addrLine1,
            '$addrCity, $addrPinCode',
            addrState,
          ].where((s) => s.isNotEmpty).join('\n'),
          style: const TextStyle(
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),

        const Divider(height: 48),

        // ── Payment ───────────────────────────────────────────────────────
        const Text(
          'Payment Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _row('Method', paymentMethod),
        const SizedBox(height: 8),
        _row('Subtotal', '₹${totalAmount.toStringAsFixed(0)}'),
        const SizedBox(height: 8),
        _row('Shipping', 'Free'),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '₹${totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
