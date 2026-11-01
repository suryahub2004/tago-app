import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/vitals_socket_client.dart';
import '../../data/models/family_member.dart';

final familyHubProvider = StateNotifierProvider<FamilyHubController, AsyncValue<List<FamilyMember>>>((ref) {
  final api = ref.watch(apiClientProvider);
  final socket = ref.watch(vitalsSocketProvider);
  return FamilyHubController(api, socket);
});

// NOTE: inviteTokenProvider is intentionally removed.
// Generating an invite token requires {email, relationship} which are
// collected in InviteMemberScreen. Call /family/invite from that screen directly.
// Keeping a FutureProvider here that posts with no body causes a 400 validation error.

class FamilyHubController extends StateNotifier<AsyncValue<List<FamilyMember>>> {
  FamilyHubController(this._api, this._socket) : super(const AsyncValue.loading()) {
    _init();
  }

  final ApiClient _api;
  final VitalsSocketClient _socket;
  StreamSubscription? _vitalsSub;
  String? _familyGroupId;

  /// Exposed so the challenge provider can use the already-resolved group ID
  /// without making a second API call.
  String? get familyGroupId => _familyGroupId;

  Future<void> _init() async {
    await fetchMembers();
    await _socket.connect();
    
    _vitalsSub = _socket.vitalsStream.listen((data) {
      _updateVital(data);
    });
  }

  Future<void> fetchMembers() async {
    try {
      state = const AsyncValue.loading();

      // Get the family group to extract the groupId for WebSocket subscription
      final groupRes = await _api.getMap('/family/group');
      _familyGroupId = groupRes['id'] as String?
          ?? (groupRes['data'] as Map<String, dynamic>?)?['id'] as String?;

      // /family/members returns a raw JSON array (not wrapped in {data:[...]})
      // so we use getList() instead of getMap() to avoid a List→Map cast crash.
      final rawList = await _api.getList('/family/members');
      final list = rawList
          .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(list);

      if (_familyGroupId != null) {
        _socket.subscribeToFamilyGroup(_familyGroupId!);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> acceptInviteByToken(String token) async {
    await _api.postMap('/family/invite/$token/accept');
    await fetchMembers(); // Refresh members after joining
  }

  Future<Map<String, dynamic>> getInvitePreview(String token) async {
    final res = await _api.getMap('/family/invite/$token');
    return res['data'] as Map<String, dynamic>? ?? res;
  }


  void _updateVital(Map<String, dynamic> data) {
    if (!state.hasValue) return;
    final userId = data['userId'] as String?;
    if (userId == null) return;

    final members = state.value!;
    final index = members.indexWhere((m) => m.userId == userId);
    if (index == -1) return;

    final member = members[index];
    final vitalType = data['type'] as String?;
    final value = data['value'];

    FamilyMember updated = member;
    if (vitalType == 'heart_rate') {
      updated = member.copyWith(latestHr: (value as num).toInt());
    } else if (vitalType == 'spo2') {
      updated = member.copyWith(latestSpo2: (value as num).toInt());
    }

    if (updated != member) {
      final newList = List<FamilyMember>.from(members);
      newList[index] = updated;
      state = AsyncValue.data(newList);
    }
  }

  @override
  void dispose() {
    _vitalsSub?.cancel();
    if (_familyGroupId != null) {
      _socket.unsubscribeFromFamilyGroup(_familyGroupId!);
    }
    // We do not disconnect socket here, as it might be used globally or handled by root
    super.dispose();
  }
}
