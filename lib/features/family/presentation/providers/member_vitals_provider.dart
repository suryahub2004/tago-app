import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

final memberVitalsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, memberId) async {
  final api = ref.watch(apiClientProvider);
  try {
    return await api.getMap('/family/members/$memberId/shared-vitals');
  } catch (_) {
    return null;
  }
});
