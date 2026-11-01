import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'models/product.dart';

class ShopRepository {
  ShopRepository(this._api);

  final ApiClient _api;

  /// Fetches the active product catalogue from [GET /shop/products].
  /// Throws on failure — callers should display an error and offer a retry.
  /// No silent fake fallback: a fake product ID would pass @IsUUID() validation
  /// only if it happens to be a UUID, which a hardcoded slug never is.
  Future<List<Product>> getProducts() async {
    // The backend returns a bare JSON array — use getList(), not getMap().
    final list = await _api.getList('/shop/products');
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single product by [slug] from [GET /shop/products/:slug].
  /// Throws on failure.
  Future<Product> getProduct(String slug) async {
    final res = await _api.getMap('/shop/products/$slug');
    return Product.fromJson(
        res['product'] as Map<String, dynamic>? ?? res);
  }

  /// Places an order via [POST /shop/orders].
  /// Throws a [NetworkException] or [ServerException] on failure — callers
  /// must handle errors and show appropriate UI (never silently swallow).
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    return await _api.postMap('/shop/orders', data: orderData);
  }

  /// Fetches a single order by its ID via [GET /shop/orders/:id].
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final res = await _api.getMap('/shop/orders/$orderId');
    return res['order'] as Map<String, dynamic>? ??
        res['data'] as Map<String, dynamic>? ??
        res;
  }

  /// Fetches the current user's order history via [GET /shop/orders/my].
  /// The backend returns a bare JSON array.
  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final list = await _api.getList('/shop/orders/my');
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
}

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.watch(apiClientProvider));
});
