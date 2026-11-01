import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/screen_utils.dart';
import '../providers/ring_sizer_provider.dart';

class RingSizerScreen extends ConsumerStatefulWidget {
  const RingSizerScreen({super.key});

  @override
  ConsumerState<RingSizerScreen> createState() => _RingSizerScreenState();
}

class _RingSizerScreenState extends ConsumerState<RingSizerScreen> {
  int _step = 1;
  double _dpi = 160.0;
  
  // Coin calibration vars
  double _calibrationRenderMm = 23.0; // ₹5 coin default
  final double _actualCoinMm = 23.0;
  
  @override
  void initState() {
    super.initState();
    _initDpi();
  }

  void _initDpi() {
    // Post-frame callback because MediaQuery needs context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _dpi = ScreenUtils.getPhysicalDpi(context));
      }
    });
  }

  void _nextStep() {
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ring Sizer')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == 1) _buildIntro()
              else if (_step == 2) _buildCalibration()
              else _buildMeasurement(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.fingerprint, size: 80, color: Colors.blueAccent),
        const SizedBox(height: 24),
        const Text(
          'Find Your Ring Size',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          "We'll use your screen to measure your exact ring size.\n\nRemove rings. Place your phone on a flat surface. Use your non-dominant hand.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Start Measuring', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildCalibration() {
    // A circle with a dashed border that user can resize
    final sizeInPx = ScreenUtils.mmToPixels(_calibrationRenderMm, _dpi, 1.0);
    
    return Column(
      children: [
        const Text(
          "First, let's calibrate your screen",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Place a ₹5 coin (23mm) on the circle and pinch to resize until it matches perfectly.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _calibrationRenderMm *= details.scale;
                  // Clamp to reasonable limits
                  _calibrationRenderMm = _calibrationRenderMm.clamp(10.0, 40.0);
                });
              },
              child: Container(
                width: sizeInPx,
                height: sizeInPx,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent, width: 2, style: BorderStyle.solid),
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                ),
                child: const Center(child: Text('₹5')),
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // Calculate correction factor
            final factor = _calibrationRenderMm / _actualCoinMm;
            ref.read(dpiCorrectionFactorProvider.notifier).state = factor;
            saveDpiCorrectionFactor(factor);
            _nextStep();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Coin fits perfectly', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildMeasurement() {
    final correctionFactor = ref.watch(dpiCorrectionFactorProvider);
    final diameterMm = ref.watch(ringSizeProvider);
    final sizeInPx = ScreenUtils.mmToPixels(diameterMm, _dpi, correctionFactor);

    return Column(
      children: [
        const Text(
          "Place your finger inside the circle",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Adjust until the circle fits snugly around your finger knuckle, not too tight.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              onScaleUpdate: (details) {
                ref.read(ringSizeProvider.notifier).state = 
                  (diameterMm * details.scale).clamp(10.0, 30.0);
              },
              child: Container(
                width: sizeInPx,
                height: sizeInPx,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 6),
                ),
              ),
            ),
          ),
        ),
        Text(
          '${diameterMm.toStringAsFixed(1)} mm',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 48,
              onPressed: () {
                ref.read(ringSizeProvider.notifier).state -= 0.3;
              },
              icon: const Icon(Icons.remove_circle_outline),
            ),
            IconButton(
              iconSize: 48,
              onPressed: () {
                ref.read(ringSizeProvider.notifier).state += 0.3;
              },
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            context.push('/home/profile/ring-sizer/result');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('This fits!', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
