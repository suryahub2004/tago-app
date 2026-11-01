import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/sv_button.dart';

final _pendingInvitesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final list = await ref.watch(apiClientProvider).getList('/family/invites/pending');
  return list.map((e) => e as Map<String, dynamic>).toList();
});

class PendingInvitesScreen extends ConsumerWidget {
  const PendingInvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(_pendingInvitesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Invites'),
        backgroundColor: Colors.transparent,
      ),
      body: invitesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              SvButton(
                label: 'Retry',
                fullWidth: false,
                onPressed: () => ref.invalidate(_pendingInvitesProvider),
              ),
            ],
          ),
        ),
        data: (invites) {
          if (invites.isEmpty) {
            return const Center(
              child: Text(
                'No pending invites',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invites.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final invite = invites[index];
              final member = invite['member'] as Map<String, dynamic>?;
              final email = member?['email'] as String? ?? 'Unknown';
              final name = member?['name'] as String? ?? email;
              final relationship = invite['relationship'] as String? ?? '';
              final createdAt = invite['createdAt'] != null
                  ? DateTime.tryParse(invite['createdAt'].toString())
                  : null;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(name, style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '$relationship • Sent${createdAt != null ? ' ${DateFormat.MMMd().format(createdAt)}' : ''}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                trailing: Chip(
                  label: const Text('Pending',
                      style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  side: BorderSide.none,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
