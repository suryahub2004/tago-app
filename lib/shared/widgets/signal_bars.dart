import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SignalBars extends StatelessWidget {
  const SignalBars({super.key, required this.rssi});
  
  final int rssi;

  @override
  Widget build(BuildContext context) {
    // RSSI roughly maps to:
    // > -60 dBm: 4 bars (Excellent)
    // -60 to -70 dBm: 3 bars (Good)
    // -70 to -80 dBm: 2 bars (Fair)
    // < -80 dBm: 1 bar (Poor)
    
    int bars = 1;
    if (rssi > -60) {
      bars = 4;
    } else if (rssi > -70) {
      bars = 3;
    } else if (rssi > -80) {
      bars = 2;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final isActive = index < bars;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3,
          height: 6.0 + (index * 3),
          decoration: BoxDecoration(
            color: isActive ? AppColors.success : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
