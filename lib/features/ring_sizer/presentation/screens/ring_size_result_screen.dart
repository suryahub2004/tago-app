import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/ring_size_chart.dart';
import '../providers/ring_sizer_provider.dart';

class RingSizeResultScreen extends ConsumerWidget {
  const RingSizeResultScreen({super.key});

  Future<void> _saveSize(BuildContext context, WidgetRef ref, RingSizeEntry? entry) async {
    if (entry == null) return;
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patchMap('/users/me', data: {'ringSize': 'US ${entry.usSize}'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ring size saved to your profile!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save ring size.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diameterMm = ref.watch(ringSizeProvider);
    final bestMatch = findSizeByDiameter(diameterMm);

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Lottie.asset(
              'assets/animations/success.json',
              height: 120,
              repeat: false,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Ring Size',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              bestMatch != null ? 'US ${bestMatch.usSize}' : 'No exact match',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 24),
            
            if (bestMatch != null) ...[
              Card(
                elevation: 0,
                color: Colors.blueAccent.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSizeLabel('US', bestMatch.usSize),
                          _buildSizeLabel('EU', bestMatch.euSize),
                          _buildSizeLabel('UK', bestMatch.ukSize),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSizeLabel('JP', bestMatch.jpSize),
                          _buildSizeLabel('IN', bestMatch.inSize),
                          _buildSizeLabel('Inner Ø', '${bestMatch.diameterMm} mm'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () => _saveSize(context, ref, bestMatch),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Save to my profile', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                if (bestMatch != null) {
                  // Navigate to shop with pre-selected ring size as a query param
                  // ShopScreen reads this to pre-filter products
                  context.go('/home/shop?ringSize=${bestMatch.usSize}');
                } else {
                  context.go('/home/shop');
                }
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Shop rings that fit you', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.push('/home/profile/ring-sizer/chart');
              },
              child: const Text('View full size chart'),
            ),
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Measure again'),
            ),
            IconButton(
              onPressed: () {
                if (bestMatch != null) {
                  SharePlus.instance.share(ShareParams(text: 'My SmartVital ring size: US ${bestMatch.usSize} | EU ${bestMatch.euSize} | UK ${bestMatch.ukSize}'));
                }
              },
              icon: const Icon(Icons.share),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSizeLabel(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
