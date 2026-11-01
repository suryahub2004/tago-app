import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../providers/family_hub_provider.dart';
import '../../data/models/family_models.dart';

/// Fetches shared vitals for every accepted family member and builds
/// the [MemberComparison] list for the comparison charts.
///
/// Strategy:
///   1. Read the already-loaded family member list from [familyHubProvider].
///   2. For each active member call GET /family/members/:id/shared-vitals.
///   3. Also fetch the current user's own summary to include "You" in the chart.
final familyComparisonProvider = FutureProvider<List<MemberComparison>>((ref) async {
  final api = ref.watch(apiClientProvider);

  // Current user's own summary
  Map<String, dynamic> mySummary = {};
  try {
    mySummary = await api.getMap('/vitals/summary', query: {'period': 'today'});
  } catch (_) {}

  final comparisons = <MemberComparison>[
    MemberComparison(
      name: 'You',
      steps: _parseInt(mySummary['steps'] ?? mySummary['totalSteps']),
      sleep: _parseInt(mySummary['sleepScore']),
      heartRate: _parseInt(mySummary['avgHr']),
      spo2: _parseInt(mySummary['spo2']),
    ),
  ];

  // Family members
  final membersState = ref.watch(familyHubProvider);
  final members = membersState.valueOrNull ?? [];

  for (final member in members) {
    try {
      final vitals = await api.getMap('/family/members/${member.userId}/shared-vitals');
      comparisons.add(MemberComparison(
        name: member.name.isNotEmpty ? member.name : 'Member',
        steps:    _parseInt(vitals['steps']),
        sleep:    _parseInt(vitals['sleepScore']),
        heartRate: _parseInt(vitals['heartRate']),
        spo2:     _parseInt(vitals['spo2']),
      ));
    } catch (_) {
      // Member may not have shared vitals — skip
    }
  }

  return comparisons;
});

int _parseInt(dynamic v) {
  if (v == null) return 0;
  return int.tryParse(v.toString()) ?? (v is num ? v.toInt() : 0);
}
