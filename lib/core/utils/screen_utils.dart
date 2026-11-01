import 'package:flutter/widgets.dart';

class ScreenUtils {
  // Get screen DPI safely without desktop plugins
  static double getPhysicalDpi(BuildContext context) {
    // MediaQuery.devicePixelRatio gives logical to physical pixels.
    // Base android/iOS baseline is usually 160 dpi = 1.0 devicePixelRatio
    return MediaQuery.devicePixelRatioOf(context) * 160.0;
  }

  // Convert mm to pixels at corrected DPI
  static double mmToPixels(double mm, double dpi, double correctionFactor) {
    return (mm / 25.4) * dpi * correctionFactor;
  }

  // Convert pixels back to mm
  static double pixelsToMm(double pixels, double dpi, double correctionFactor) {
    return (pixels / dpi / correctionFactor) * 25.4;
  }
}
