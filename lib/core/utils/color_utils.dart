import 'package:flutter/material.dart';

extension ColorUtils on Color {
  /// Small helper to return a color with the given alpha (0.0 - 1.0).
  Color withValues({double? alpha}) {
    if (alpha == null) return this;
    final normalized = alpha.clamp(0.0, 1.0);
    return Color.fromARGB(
      (normalized * 255).round(),
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
    );
  }
}
