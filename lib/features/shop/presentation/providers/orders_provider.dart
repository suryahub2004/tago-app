import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/shop_repository.dart';

final myOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(shopRepositoryProvider).getMyOrders();
});
