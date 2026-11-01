import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product.dart';
import '../../data/shop_repository.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(shopRepositoryProvider).getProducts();
});
