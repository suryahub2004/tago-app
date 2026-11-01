import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/sv_badge.dart';
import '../../../../shared/widgets/sv_button.dart';
import '../../../../shared/widgets/sv_loading.dart';
import '../../data/shop_repository.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(_productBySlugProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          slug.split('-').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' '),
        ),
        actions: [
          IconButton(tooltip: 'Share', onPressed: () {}, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: productAsync.when(
        loading: () => const Center(child: SvLoading()),
        error: (e, _) => Center(child: Text('Failed to load product: $e')),
        data: (product) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  const SizedBox(
                    height: 220,
                    child: Center(child: Icon(Icons.watch, size: 96)),
                  ),
                  Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text('₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (product.deviceType == 'SMART_RING') ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.push('/home/profile/ring-sizer'),
                        icon: const Icon(Icons.straighten),
                        label: const Text('Find your ring size'),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  const Wrap(
                    spacing: 8,
                    children: [
                      SvBadge(label: 'Works with Smart Ring'),
                      SvBadge(label: 'Water resistant'),
                      SvBadge(label: '7-day battery'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(product.description),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: SvButton(
                        label: 'Add to Cart',
                        variant: SvButtonVariant.secondary,
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart'), duration: Duration(seconds: 2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SvButton(
                        label: 'Buy Now',
                        // Pass the real UUID id AND deviceType — never the slug
                        onPressed: () => context.push(
                          '/home/shop/order?product=${product.id}&deviceType=${product.deviceType ?? ""}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Scoped provider — fetches one product by slug using the repository.
// Riverpod caches this per-slug so navigating back and forth is instant.
final _productBySlugProvider = FutureProvider.family((ref, String slug) async {
  return ref.watch(shopRepositoryProvider).getProduct(slug);
});
