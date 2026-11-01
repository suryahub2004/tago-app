import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final dpiCorrectionFactorProvider = StateProvider<double>((ref) {
  final box = Hive.box<dynamic>('settings');
  return box.get('dpi_correction_factor', defaultValue: 1.0) as double;
});

final ringSizeProvider = StateProvider<double>((ref) {
  return 17.3; // Default starting diameter in mm (US size 7)
});

void saveDpiCorrectionFactor(double factor) {
  final box = Hive.box<dynamic>('settings');
  box.put('dpi_correction_factor', factor);
}
