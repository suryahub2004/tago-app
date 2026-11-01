import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/family_models.dart';
import '../providers/family_hub_provider.dart';

/// Fetches the live family challenge from the backend once the family
/// group ID is known (via [familyHubProvider]).
final familyChallengeProvider =
    FutureProvider.autoDispose<FamilyChallenge?>((ref) async {
  // Wait for the family hub to resolve so we have the group ID
  final hubState = ref.watch(familyHubProvider);
  final controller = ref.read(familyHubProvider.notifier);

  // If still loading, return null (card shows loading state)
  if (!hubState.hasValue) return null;

  // Retrieve the group ID the controller stored
  final groupId = controller.familyGroupId;
  if (groupId == null || groupId.isEmpty) return null;

  final api = ref.watch(apiClientProvider);
  final res = await api.getMap('/family/groups/$groupId/challenge');
  return FamilyChallenge.fromJson(res);
});
