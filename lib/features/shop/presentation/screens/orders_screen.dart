import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_card.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => _buildLoading(),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                const Text(
                  'Could not load orders',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                SvButton(
                  label: 'Retry',
                  fullWidth: false,
                  onPressed: () => ref.invalidate(myOrdersProvider),
                ),
              ],
            ),
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No orders yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 16),
                  SvButton(
                    label: 'Browse Products',
                    fullWidth: false,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              final id = order['id'] as String? ?? '';
              final shortId = id.length >= 8 ? '#${id.substring(id.length - 8).toUpperCase()}' : '#$id';
              final total = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
              final status = order['status'] as String? ?? 'PENDING';
              final created = order['createdAt'] != null ? DateTime.tryParse(order['createdAt'].toString()) : null;

              Color statusColor = AppColors.textSecondary;
              if (status == 'CONFIRMED' || status == 'DELIVERED') statusColor = AppColors.primary;
              if (status == 'CANCELLED') statusColor = AppColors.danger;

              return SvCard(
                onTap: () => context.push('/home/shop/order/$id'),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(shortId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Total: ₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    if (created != null)
                      Text(
                        'Placed on: ${DateFormat.yMMMd().format(created)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: CircularProgressIndicator(color: AppColors.textTertiary)),
      ),
    );
  }
}
