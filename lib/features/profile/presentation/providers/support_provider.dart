import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/support_repository.dart';
// supportRepositoryProvider is defined in support_repository.dart — do NOT redeclare it here.

final supportTicketsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(supportRepositoryProvider).getMyTickets();
});
