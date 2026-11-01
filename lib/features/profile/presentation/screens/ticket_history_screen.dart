import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sv_card.dart';
import '../providers/support_provider.dart';

class TicketHistoryScreen extends ConsumerWidget {
  const TicketHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsState = ref.watch(supportTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        actions: [
          IconButton(
            onPressed: () => context.go('/home/profile/support/new'),
            icon: const Icon(Icons.add),
            tooltip: 'New Ticket',
          ),
        ],
      ),
      body: ticketsState.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(
              child: Text('No support tickets found.', style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(supportTicketsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final subject = ticket['subject'] as String? ?? 'No Subject';
                final status = ticket['status'] as String? ?? 'OPEN';
                final message = ticket['message'] as String? ?? '';
                final createdAtStr = ticket['createdAt'] as String?;
                final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SvCard(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subject,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Chip(
                            label: Text(status, style: const TextStyle(fontSize: 12)),
                            backgroundColor: status.toUpperCase() == 'OPEN' ? AppColors.warning.withValues(alpha: 0.2) : AppColors.surface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      if (createdAt != null)
                        Text(
                          createdAt.toLocal().toString().split('.')[0],
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
