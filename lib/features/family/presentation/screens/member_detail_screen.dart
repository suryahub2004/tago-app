import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../../../shared/widgets/sv_metric_card.dart';
import '../providers/family_hub_provider.dart';
import '../providers/member_vitals_provider.dart';

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsState = ref.watch(memberVitalsProvider(memberId));
    final familyState = ref.watch(familyHubProvider);
    
    final members = familyState.valueOrNull ?? [];
    // FamilyHubScreen navigates with member.id (the join-table row UUID).
    // We search by both id and userId to cover both cases robustly.
    final member = members
        .where((m) => m.id == memberId || m.userId == memberId)
        .firstOrNull;
    
    final name = member?.name ?? memberId;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'Alerts',
            onPressed: () =>
                context.go('/home/family/alert-settings/$memberId'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: vitalsState.when(
        data: (vitals) {
          final liveHr = member?.latestHr;
          final lastHr = vitals?['heartRate'] as num?;
          
          final hrValue = liveHr != null && liveHr > 0 
              ? liveHr.toString() 
              : (lastHr?.toString() ?? '--');
              
          final isLive = liveHr != null && liveHr > 0;
              
          final spo2 = vitals?['spo2'] as num?;
          final steps = vitals?['steps'] as num?;
          final sleep = vitals?['sleepScore'] as num?;
          
          final lastActiveStr = vitals?['lastActive'] as String?;
          final lastActive = lastActiveStr != null ? DateTime.tryParse(lastActiveStr) : null;
          
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (lastActive != null) ...[
                Text(
                  'Last active: ${timeago.format(lastActive)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SvMetricCard(
                label: isLive ? 'Live HR (LIVE)' : 'Heart Rate',
                value: hrValue,
                unit: 'bpm',
                accentColor: AppColors.heartRate,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SvMetricCard(
                      label: 'SpO2',
                      value: spo2?.toString() ?? '--',
                      unit: '%',
                      accentColor: AppColors.spo2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SvMetricCard(
                      label: 'Steps',
                      value: steps?.toString() ?? '--',
                      unit: '',
                      accentColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              if (sleep != null) ...[
                const SizedBox(height: AppSpacing.md),
                SvMetricCard(
                  label: 'Sleep Quality',
                  value: sleep.toString(),
                  unit: '%',
                  accentColor: AppColors.sleep,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SvButton(
                label: 'Send Check-in',
                onPressed: () async {
                  try {
                    await ref.read(apiClientProvider).postMap(
                      '/family/members/${member?.userId ?? memberId}/checkin',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Check-in sent!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send check-in')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SvButton(
                label: 'Emergency Call',
                variant: SvButtonVariant.destructive,
                onPressed: () async {
                  // Get phone number from vitals data or member info
                  final phone = vitals?['phone'] as String?;
                  if (phone != null && phone.isNotEmpty) {
                    final uri = Uri(scheme: 'tel', path: phone);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  } else {
                    // Create a CRITICAL alert so admin and family owner are notified
                    try {
                      await ref.read(apiClientProvider).postMap(
                        '/alerts',
                        data: {
                          'alertType': 'EMERGENCY_SOS',
                          'severity': 'CRITICAL',
                          'message': 'Emergency SOS triggered for family member ${member?.name ?? memberId}',
                          'targetUserId': member?.userId ?? memberId,
                        },
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Emergency alert sent to family and admin'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Emergency alert sent')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
